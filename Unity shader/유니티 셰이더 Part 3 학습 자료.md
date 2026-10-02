## 유니티 셰이더 Part 3 학습 자료
이 문서는 '유니티 셰이더 16주 완성 커리큘럼'의 Part 3 학습 자료입니다. 노멀 매핑, 프레넬, 디졸브 등 고급 셰이더 기법을 학습하고, 셰이더 그래프를 체험합니다.

> **따라 하기 환경**: Unity 2022.3 LTS + URP 14 (새 프로젝트 템플릿 `3D (URP)`). 셰이더는 `Project 창 → Create → Shader → Unlit Shader`(또는 Empty Shader)로 파일을 만들고 내용을 전부 붙여 넣은 뒤, 셰이더 우클릭 → Create → Material → 오브젝트에 적용합니다. 코드는 에디터에서 직접 컴파일해 검증하지 못했으므로 콘솔 에러가 나면 알려 주세요.

## 9주차: 노멀 매핑과 고급 텍스처

`노멀 맵 (Normal Map)`

노멀 맵은 로우폴리(Low-poly) 모델 표면에 하이폴리(High-poly) 모델의 디테일한 음영 정보를 텍스처 형태로 저장한 것입니다. 픽셀 단위로 표면의 법선(Normal) 방향을 속여, 실제로 폴리곤이 더 많은 것처럼 보이게 하는 착시를 일으킵니다.

`RGB 채널`은 각각 법선 벡터의 X, Y, Z 방향을 나타냅니다. (보통 Z가 위쪽을 향함)

이를 통해 아주 적은 비용으로 시각적 퀄리티를 크게 향상할 수 있습니다.

`탄젠트 공간` (Tangent Space)
노멀 매핑을 올바르게 적용하기 위해 사용되는 국소적인 좌표계입니다. 모델의 각 표면(폴리곤)에 접하는 평면을 기준으로 설정됩니다.

`Normal (N)`: 표면의 법선 방향 (위쪽)

`Tangent (T)`: 표면의 가로 방향 (보통 UV의 U 방향)

`Bitangent (B)`: 표면의 세로 방향 (보통 UV의 V 방향)

노멀 맵에 저장된 법선은 탄젠트 공간 기준이므로, 조명 벡터와 같은 공간에서 계산해야 합니다. 두 가지 방법이 있습니다: (a) 광원/시선 벡터를 탄젠트 공간으로 보낸다, (b) 노멀 맵의 법선을 TBN 행렬로 **월드 공간으로 변환**한다. 이 문서의 예제는 (b)를 사용합니다.

Part 2에서 만들었던 Blinn-Phong 셰이더에 노멀 매핑을 추가하는 코드입니다.
**파일: `Assets/Shaders/Lessons/NormalMapped.shader`**
```hlsl
// Part 3 : 노멀 매핑 (탄젠트 공간 -> 월드 공간) + Lambert + Blinn-Phong
Shader "Lessons/NormalMapped"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _MainTex ("Base Texture", 2D) = "white" {}
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Scale", Range(0,2)) = 1
        _Shininess ("Shininess", Range(0.1, 100)) = 20
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }
        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float3 tangentWS   : TEXCOORD2;
                float3 bitangentWS : TEXCOORD3;
                float3 positionWS  : TEXCOORD4;
            };

            TEXTURE2D(_MainTex);   SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _BaseColor;
                half _NormalScale;
                half _Shininess;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS  = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);
                OUT.uv          = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                OUT.tangentWS   = TransformObjectToWorldDir(IN.tangentOS.xyz);
                // tangent.w 는 바이탄젠트 방향(좌/우수 좌표계 보정)
                OUT.bitangentWS = cross(OUT.normalWS, OUT.tangentWS) * IN.tangentOS.w * GetOddNegativeScale();
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv), _NormalScale);
                float3x3 tbn = float3x3(normalize(IN.tangentWS), normalize(IN.bitangentWS), normalize(IN.normalWS));
                float3 N = normalize(TransformTangentToWorld(normalTS, tbn));

                Light light = GetMainLight();
                float3 L = light.direction;
                float3 V = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                float3 H = normalize(L + V);

                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * _BaseColor.rgb;
                half diffuse = saturate(dot(N, L));
                half specular = pow(saturate(dot(N, H)), _Shininess) * step(0.0, diffuse);
                return half4((albedo * diffuse + specular) * light.color, 1);
            }
            ENDHLSL
        }
    }
}
```

> 핵심: TBN 행렬로 노멀맵(탄젠트 공간)을 월드 공간으로 변환. 노멀맵 텍스처의 Texture Type 을 Normal map 으로 지정해야 합니다.

## 10주차: 프레넬과 림 라이팅

`프레넬 효과` (Fresnel Effect)
물체의 표면을 비스듬하게 볼수록(시선과 표면의 각도가 작을수록) 반사율이 높아지는 물리 현상입니다. 대부분의 비금속 물질이 이 특성을 가집니다.

그래픽스에서는 `시선 벡터`(View Direction)와 표면의 `법선 벡터`(Normal)의 `내적`(Dot Product)을 이용하여 이 효과를 근사합니다.

`1 - saturate(dot(normal, viewDir))` 공식을 통해 시선이 표면에 수직일 때(정면)는 0, 수평에 가까울 때(가장자리)는 1에 가까운 값을 얻을 수 있습니다.

`림 라이팅 (Rim Lighting)`
프레넬 효과를 응용하여 물체의 외곽선이 빛나는 것처럼 보이게 하는 기법입니다. 캐릭터나 중요한 오브젝트를 배경과 분리하고 강조하는 데 효과적입니다. 카툰 렌더링에 사용되기도 합니다.


오브젝트의 외곽선에 지정된 색상의 빛이 감돌게 하는 림 라이팅 셰이더 코드입니다.
**파일: `Assets/Shaders/Lessons/SimpleRim.shader`**
```hlsl
// Part 3 : 프레넬 림 라이트
Shader "Lessons/SimpleRim"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _RimColor ("Rim Color", Color) = (0,1,1,1)
        _RimPower ("Rim Power", Range(0.1, 10)) = 3
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }
        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes { float4 positionOS : POSITION; float3 normalOS : NORMAL; };
            struct Varyings   { float4 positionHCS : SV_POSITION; float3 normalWS : TEXCOORD0; float3 positionWS : TEXCOORD1; };
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _RimColor;
                half  _RimPower;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS  = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }
            half4 frag(Varyings IN) : SV_Target
            {
                float3 N = normalize(IN.normalWS);
                float3 V = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                Light light = GetMainLight();
                half lambert = saturate(dot(N, light.direction));
                half rim = pow(1.0 - saturate(dot(N, V)), _RimPower);
                half3 color = _BaseColor.rgb * lambert * light.color + _RimColor.rgb * rim;
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
```

> 핵심: `rim = pow(1 - saturate(dot(N,V)), _RimPower)`.

## 11주차: 디졸브 및 왜곡 효과

`디졸브 효과 (Dissolve Effect)`
노이즈 텍스처와 clip() 함수를 이용해 오브젝트가 타거나 녹아 없어지는 듯한 효과를 만듭니다.

`노이즈 텍스처`의 흑백 값(0~1)과 인스펙터에서 조절하는 임계값(Threshold)을 비교합니다.

`clip(noiseValue - threshold)`: 노이즈 값이 임계값보다 작으면 해당 픽셀을 그리지 않아 구멍이 뚫린 것처럼 보입니다.

임계값 주변에 특정 색상을 더해주면 타들어 가는 듯한 테두리 효과`(Burn Edge)`를 추가할 수 있습니다.

`왜곡/굴절 효과 (Distortion/Refraction)`
배경 화면을 텍스처로 가져와야 합니다. Built-in 파이프라인에서는 `GrabPass`를 쓰지만, **URP 에서는 `GrabPass`가 지원되지 않으므로** URP 에셋에서 Opaque Texture 를 켜고 `_CameraOpaqueTexture` 를 샘플링합니다(`SampleSceneColor`). 이 텍스처를 샘플링할 UV 좌표를 노멀 맵 등을 이용해 살짝 왜곡하면, 배경이 아지랑이나 유리를 통해 보는 것처럼 굴절되어 보이는 효과를 만들 수 있습니다.


임계값에 따라 오브젝트가 사라지는 디졸브 셰이더 코드입니다.
**파일: `Assets/Shaders/Lessons/SimpleDissolve.shader`**
```hlsl
// Part 3 : 노이즈 텍스처 + clip 으로 만드는 디졸브
Shader "Lessons/SimpleDissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "gray" {}
        _Threshold ("Dissolve Threshold", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            Cull Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings   { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };
            TEXTURE2D(_MainTex);  SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NoiseTex_ST;
                half _Threshold;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }
            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                half noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv).r;
                clip(noise - _Threshold);
                return color;
            }
            ENDHLSL
        }
    }
}
```

> 핵심: 노이즈 R 값 - _Threshold 를 `clip`. Threshold 슬라이더를 0→1 로 움직이면 사라집니다.

## 12주차: 셰이더 그래프 (Shader Graph)
 
`셰이더 그래프 소개`
코드를 직접 작성하는 대신, 노드(Node)들을 시각적으로 연결하여 셰이더를 제작하는 툴입니다. URP와 HDRP에서만 사용할 수 있습니다. 아티스트가 셰이더를 쉽게 만들 수 있도록 돕습니다.


`장점`

* 직관적이고 시각적이어서 배우기 쉽습니다.
* 실시간으로 결과를 확인하며 빠르게 프로토타입을 만들 수 있습니다.
* 복잡한 수학 계산을 노드가 대신해줍니다.

`단점`

* 코드로 작성하는 것보다 세밀한 제어가 어려울 수 있습니다.
* 최적화 측면에서 직접 작성한 코드보다 비효율적인 코드가 생성될 수 있습니다.
* GrabPass, 복잡한 루프 등 일부 고급 기능은 구현이 어렵거나 불가능합니다.


#### 10주차의 '림 라이팅' 효과를 셰이더 그래프로 구현해봅시다.

* Project 창에서 Create > Shader Graph > URP > Lit Shader Graph 로 새 셰이더 그래프를 생성합니다. (Unity 버전에 따라 메뉴 이름이 조금 다를 수 있습니다.)

* 프로퍼티(Properties) 추가: Blackboard에서 _RimColor (Color), _RimPower (Float) 프로퍼티를 추가합니다.

`노드 연결`

* Normal Vector 노드를 가져옵니다. (Space: World)

* View Direction 노드를 가져옵니다.

* 두 벡터를 Dot Product 노드로 연결합니다.

* 결과를 One Minus 노드에 연결합니다.

* 결과를 Saturate 노드에 연결하여 0~1 사이로 값을 제한합니다.

* 결과를 Power 노드의 A에, _RimPower 프로퍼티를 B에 연결합니다.

* Power 노드의 결과를 _RimColor 프로퍼티와 Multiply 노드로 곱합니다.

* 기존의 Base Color에 Add 노드를 이용해 림 라이팅 결과를 더합니다.

* 최종 결과를 Fragment 컨텍스트(구 Master Node)의 Base Color 슬롯에 연결합니다.
