# NPR(툰) 셰이더 실습

URP 기반 툰 셰이더를 단계별로 만들어 보는 실습입니다. 아래 "전체 코드"를 그대로 따라 만들고, 각 문서에서 원리를 설명합니다.

## 환경

| 항목 | 값 |
|---|---|
| Unity | 2022.3 LTS |
| 렌더 파이프라인 | URP 14 (새 프로젝트 템플릿 `3D (URP)` 로 시작) |

> 이 저장소의 `NPR_shader.shader` 는 **Built-in 파이프라인용** 옛 버전입니다. URP 프로젝트에서는 분홍색으로 보이므로 쓰지 마세요. 아래 코드가 URP 용 최신본입니다.

## 학습 순서

1. [램프 텍스처](./램프%20텍스처.md) — 툰 명암
2. [역면 확장 기법](./역면%20확장%20기법.md) — 외곽선
3. [림 라이트와 스페큘러](./림%20라이트와%20스페큘러.md) — 디테일
4. [다중 램프 혼합 시스템](./다중%20램프%20혼합%20시스템.md) — 환경별 램프 블렌딩

각 문서는 아래 "전체 코드"의 어느 부분을 설명하는지 맨 위에 적어 둡니다.

## 따라 하기

1. `3D (URP)` 템플릿으로 프로젝트를 만든다.
2. Project 창에 `Assets/Shaders/NPR/` 폴더를 만들고, 아래 **전체 코드**의 `.shader` / `.hlsl` 파일 5개를 같은 이름으로 만들어 내용을 붙여 넣는다. (Create → Shader → Empty Shader 로 만든 뒤 내용을 통째로 교체. `.hlsl` 은 탐색기에서 텍스트 파일을 만들어 확장자를 `.hlsl` 로 바꾼다.)
3. `Assets/Scripts/NPR/NPRRampBlendController.cs` 를 만든다.
4. **램프 텍스처 만들기**: 256×16 PNG 를 3장 만든다 (그림판/포토샵/아래 Python). 왼쪽에서 오른쪽으로 어두운색 → 밝은색을 **계단(3칸)** 으로 채운다. 예) Warm: (110,80,90) / (210,170,150) / (255,240,220), Cool: (60,70,120) / (130,150,200) / (225,235,255). 텍스처 Inspector 에서 **Wrap Mode = Clamp** (셰이더가 포인트 샘플러를 쓰므로 Filter 설정은 상관없음).
5. `NPRToon.shader` 우클릭 → Create → Material. Warm Ramp / Cool Ramp 슬롯에 텍스처를 넣는다.
6. Sphere 를 만들어 머티리얼을 적용한다. Directional Light 를 돌려 **계단 모양 명암 + 검은 외곽선**이 보이면 성공.
7. (4번 문서) 빈 오브젝트에 `NPRRampBlendController` 를 붙이고 Main Light 슬롯에 Directional Light 를 연결, 라이트 색을 주황 ↔ 하늘색으로 바꿔 본다.

```python
# 램프 PNG 생성 (Pillow 필요: pip install pillow)
from PIL import Image
def ramp(name, colors):
    im = Image.new("RGB", (256, 16)); n = len(colors)
    for x in range(256):
        for y in range(16): im.putpixel((x, y), colors[x * n // 256])
    im.save(name)
ramp("Ramp_Warm.png", [(110,80,90), (210,170,150), (255,240,220)])
ramp("Ramp_Cool.png", [(60,70,120), (130,150,200), (225,235,255)])
```

## 전체 코드

**파일: `Assets/Shaders/NPR/NPRToon.shader`**
```hlsl
// NPR 툰 셰이더 (URP 14 / Unity 2022.3 기준)
// 구성: 램프 텍스처(Warm/Cool 블렌딩) + 그림자 수신 + 스페큘러 + 림 라이트 + 역면 확장 외곽선
// 패스별 코드는 같은 폴더의 .hlsl 파일에 있다. 공부할 때는 NPRToonPass.hlsl 부터 읽는다.
Shader "Tutorial/NPR/Toon"
{
    Properties
    {
        [Header(Main)]
        _Color ("기본 색상", Color) = (1,1,1,1)
        [NoScaleOffset] _WarmRamp ("따뜻한 램프", 2D) = "white" {}
        [NoScaleOffset] _CoolRamp ("차가운 램프", 2D) = "white" {}
        _ShadowStrength ("그림자 강도", Range(0,1)) = 1

        [Header(Outline)]
        _OutlineColor ("외곽선 색상", Color) = (0,0,0,1)
        _OutlineThickness ("외곽선 두께 (뷰 공간 단위)", Range(0, 0.1)) = 0.01
        _OutlineDistanceFade ("거리 페이드 (시작, 끝)", Vector) = (10, 50, 0, 0)

        [Header(Rim Light)]
        _RimColor ("림 색상", Color) = (1,1,1,1)
        _RimWidth ("림 시작 지점", Range(0, 1)) = 0.7
        _RimSharpness ("림 지수", Range(1, 5)) = 3

        [Header(Specular)]
        _SpecularColor ("스페큘러 색상", Color) = (1,1,1,1)
        _Glossiness ("광택", Range(0, 1)) = 0.5
        _SpecularThreshold ("하이라이트 컷 임계값", Range(0.5, 1)) = 0.9
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            Cull Back

            HLSLPROGRAM
            #pragma vertex ToonVert
            #pragma fragment ToonFrag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #include "NPRToonPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            // URP 는 LightMode 가 SRPDefaultUnlit 인 패스를 ForwardLit 다음에 추가로 그린다.
            Tags { "LightMode"="SRPDefaultUnlit" }
            Cull Front

            HLSLPROGRAM
            #pragma vertex OutlineVert
            #pragma fragment OutlineFrag
            #include "NPROutlinePass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "NPRShadowCaster.hlsl"
            ENDHLSL
        }
    }
}
```

**파일: `Assets/Shaders/NPR/NPRInput.hlsl`**
```hlsl
// NPRInput.hlsl
// 모든 패스가 공유하는 머티리얼 변수 선언.
// SRP Batcher 호환 조건: 머티리얼 프로퍼티는 모든 패스에서 "동일한" UnityPerMaterial CBUFFER 안에 있어야 한다.
// 그래서 선언을 한 파일로 모으고 각 패스가 #include 한다. (프로퍼티 추가/삭제 시 이 파일 + Properties 블록만 수정)
#ifndef NPR_INPUT_INCLUDED
#define NPR_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_WarmRamp);
TEXTURE2D(_CoolRamp);
// 이름이 sampler_point_clamp 이면 텍스처 임포트 설정과 무관하게 Point + Clamp 로 샘플링된다 (Unity 인라인 샘플러 규칙).
SAMPLER(sampler_point_clamp);

CBUFFER_START(UnityPerMaterial)
    half4 _Color;
    half  _ShadowStrength;
    half4 _OutlineColor;
    half  _OutlineThickness;
    half4 _OutlineDistanceFade; // x: 얇아지기 시작하는 거리, y: 두께가 0이 되는 거리
    half4 _RimColor;
    half  _RimWidth;
    half  _RimSharpness;
    half4 _SpecularColor;
    half  _Glossiness;
    half  _SpecularThreshold;
CBUFFER_END

// 머티리얼 프로퍼티가 아니라 C# (NPRRampBlendController) 이 Shader.SetGlobalFloat 로 넣는 전역 값.
// Properties 블록에 선언하면 머티리얼 값이 전역 값을 가려 버리므로 일부러 Properties 에 쓰지 않는다.
float _NPR_RampBlend; // 0 = Warm 램프, 1 = Cool 램프

#endif
```

**파일: `Assets/Shaders/NPR/NPRToonPass.hlsl`**
```hlsl
// NPRToonPass.hlsl : 본체 패스 (툰 램프 + 스페큘러 + 림 라이트 + 그림자 수신)
#ifndef NPR_TOON_PASS_INCLUDED
#define NPR_TOON_PASS_INCLUDED

#include "NPRInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS   : NORMAL;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 normalWS   : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
};

Varyings ToonVert(Attributes IN)
{
    Varyings OUT;
    OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
    OUT.positionCS = TransformWorldToHClip(OUT.positionWS);
    OUT.normalWS   = TransformObjectToWorldNormal(IN.normalOS);
    return OUT;
}

half4 ToonFrag(Varyings IN) : SV_Target
{
    float3 normalWS = normalize(IN.normalWS);
    float3 viewDir  = GetWorldSpaceNormalizeViewDir(IN.positionWS);

    // 그림자 좌표 -> 메인 라이트 (shadowAttenuation 에 그림자 결과가 들어 있다)
    float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
    Light mainLight = GetMainLight(shadowCoord);
    float3 lightDir = mainLight.direction;
    half shadow = lerp(1.0h, mainLight.shadowAttenuation, _ShadowStrength);

    // 1) 램프 텍스처 : NdotL(-1~1) -> 0~1 -> 램프의 가로(U) 좌표
    half NdotL = dot(normalWS, lightDir) * 0.5h + 0.5h;
    half2 rampUV = half2(NdotL, 0.5h);
    half3 warm = SAMPLE_TEXTURE2D(_WarmRamp, sampler_point_clamp, rampUV).rgb;
    half3 cool = SAMPLE_TEXTURE2D(_CoolRamp, sampler_point_clamp, rampUV).rgb;
    half3 ramp = lerp(warm, cool, saturate(_NPR_RampBlend));
    // 그림자 안에서는 램프의 가장 어두운 칸을 쓴다 (단순 곱셈보다 만화 느낌이 유지된다)
    half3 darkest = lerp(SAMPLE_TEXTURE2D(_WarmRamp, sampler_point_clamp, half2(0, 0.5)).rgb,
                         SAMPLE_TEXTURE2D(_CoolRamp, sampler_point_clamp, half2(0, 0.5)).rgb,
                         saturate(_NPR_RampBlend));
    ramp = lerp(darkest, ramp, shadow);
    half3 color = _Color.rgb * ramp * mainLight.color;

    // 2) 스페큘러 : Blinn-Phong 을 step 으로 잘라 딱딱한 하이라이트로 만든다
    float3 halfDir = normalize(lightDir + viewDir);
    half exponent = max(1.0h, _Glossiness * 128.0h); // 0 이면 pow(x,0)=1 이 되어 전체가 빛나는 버그 방지
    half spec = pow(saturate(dot(normalWS, halfDir)), exponent);
    spec = step(_SpecularThreshold, spec) * shadow;
    color += _SpecularColor.rgb * spec;

    // 3) 림 라이트
    half rim = 1.0h - saturate(dot(viewDir, normalWS));
    rim = pow(rim, _RimSharpness);
    rim = smoothstep(_RimWidth, 1.0h, rim);
    color += _RimColor.rgb * rim;

    return half4(color, 1.0h);
}

#endif
```

**파일: `Assets/Shaders/NPR/NPROutlinePass.hlsl`**
```hlsl
// NPROutlinePass.hlsl : 역면 확장(Inverted Hull) 외곽선 패스
#ifndef NPR_OUTLINE_PASS_INCLUDED
#define NPR_OUTLINE_PASS_INCLUDED

#include "NPRInput.hlsl"

struct Attributes { float4 positionOS : POSITION; float3 normalOS : NORMAL; };
struct Varyings   { float4 positionCS : SV_POSITION; };

Varyings OutlineVert(Attributes IN)
{
    Varyings OUT;
    float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
    float3 normalWS   = TransformObjectToWorldNormal(IN.normalOS);

    // 카메라 거리에 따라 두께를 줄인다. (분모가 0 이 되지 않도록 보호)
    float dist = distance(positionWS, _WorldSpaceCameraPos);
    float range = max(_OutlineDistanceFade.y - _OutlineDistanceFade.x, 1e-4);
    float fade = 1.0 - saturate((dist - _OutlineDistanceFade.x) / range);
    float thickness = _OutlineThickness * fade;

    // 뷰 공간에서 법선 방향으로 밀어낸다.
    float3 positionVS = TransformWorldToView(positionWS);
    float3 normalVS   = normalize(TransformWorldToViewDir(normalWS));
    positionVS += normalVS * thickness;

    OUT.positionCS = mul(GetViewToHClipMatrix(), float4(positionVS, 1.0));
    return OUT;
}

half4 OutlineFrag(Varyings IN) : SV_Target { return _OutlineColor; }

#endif
```

**파일: `Assets/Shaders/NPR/NPRShadowCaster.hlsl`**
```hlsl
// NPRShadowCaster.hlsl : 그림자 맵에 이 오브젝트를 그리는 패스 (URP Lit 의 ShadowCasterPass 와 같은 구조)
#ifndef NPR_SHADOW_CASTER_INCLUDED
#define NPR_SHADOW_CASTER_INCLUDED

#include "NPRInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

float3 _LightDirection;
float3 _LightPosition;

struct Attributes { float4 positionOS : POSITION; float3 normalOS : NORMAL; };
struct Varyings   { float4 positionCS : SV_POSITION; };

Varyings ShadowVert(Attributes IN)
{
    Varyings OUT;
    float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
    float3 normalWS   = TransformObjectToWorldNormal(IN.normalOS);

#if _CASTING_PUNCTUAL_LIGHT_SHADOW
    float3 lightDirWS = normalize(_LightPosition - positionWS);
#else
    float3 lightDirWS = _LightDirection;
#endif

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirWS));
#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif
    OUT.positionCS = positionCS;
    return OUT;
}

half4 ShadowFrag(Varyings IN) : SV_Target { return 0; }

#endif
```

**파일: `Assets/Scripts/NPR/NPRRampBlendController.cs`**
```csharp
using UnityEngine;

namespace ShaderStudy.NPR
{
    /// <summary>
    /// 메인 라이트 색이 따뜻하면 Warm 램프, 차가우면 Cool 램프를 쓰도록
    /// 전역 셰이더 값 _NPR_RampBlend (0=Warm, 1=Cool) 를 갱신한다.
    /// 셰이더 쪽 선언: NPRInput.hlsl 의 "float _NPR_RampBlend;"
    /// </summary>
    [ExecuteAlways]
    public class NPRRampBlendController : MonoBehaviour
    {
        static readonly int RampBlendId = Shader.PropertyToID("_NPR_RampBlend");

        [SerializeField] Light mainLight;
        [SerializeField, Min(0.01f)] float smoothTime = 0.5f;
        [SerializeField, Range(0f, 1f)] float currentBlend;

        float velocity;

        void Update()
        {
            if (mainLight == null) return;

            // r 이 b 보다 크면 따뜻한 빛(→0), 작으면 차가운 빛(→1)
            Color c = mainLight.color;
            float target = c.r >= c.b ? 0f : 1f;

            currentBlend = Application.isPlaying
                ? Mathf.SmoothDamp(currentBlend, target, ref velocity, smoothTime)
                : target; // 에디터(비재생)에서는 즉시 반영
            Shader.SetGlobalFloat(RampBlendId, currentBlend);
        }

        void OnDisable() => Shader.SetGlobalFloat(RampBlendId, 0f);
    }
}
```

## 자주 막히는 곳

| 증상 | 원인 / 해결 |
|---|---|
| 분홍색 | URP 가 아닌 프로젝트. `3D (URP)` 템플릿인지, Project Settings → Graphics 에 URP 에셋이 있는지 확인 |
| 외곽선이 안 보임 | `_OutlineThickness` 가 0 인지, 외곽선 패스의 `LightMode` 가 `SRPDefaultUnlit` 인지 확인 |
| 그림자를 안 받음 | Directional Light 의 Shadow Type 이 No Shadows 이거나 URP 에셋의 Main Light Cast Shadows 가 꺼짐 |
| 큐브 모서리에서 외곽선이 갈라짐 | 하드 에지 메시는 법선이 면마다 달라 생기는 현상. 구/캐릭터처럼 스무스 법선 메시로 확인 |

> **검증 상태**: URP 14 공식 Lit 셰이더의 구조를 따라 작성했지만 작성 환경에 Unity 가 없어 에디터에서 컴파일해 보지는 못했습니다. 에러가 나면 콘솔 메시지와 함께 이슈로 남겨 주세요.
