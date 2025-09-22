# 유니티 셰이더 Part 2 학습 자료
이 문서는 '유니티 셰이더 16주 완성 커리큘럼'의 Part 2 학습 자료입니다. 조명 계산, 블렌딩, 정점 애니메이션 등 중급 셰이더 기법을 학습하는 것을 목표로 합니다.

## 5챕터: 기본 조명 모델

`조명의 3요소`
컴퓨터 그래픽스에서 조명은 주로 세 가지 요소의 조합으로 표현됩니다.

`Ambient (환경광)`: 씬 전체에 고르게 퍼져 있는 빛입니다. 직접 빛을 받지 않는 어두운 부분(그림자)의 색상을 결정합니다.

`Diffuse (난반사)`: 빛이 표면에 부딪혀 모든 방향으로 고르게 반사되는 현상입니다. 표면의 각도에 따라 밝기가 달라지며, 물체의 기본 색상을 나타냅니다.

`Specular (정반사)`: 빛이 특정 방향으로 강하게 반사되는 현상입니다. 매끄러운 표면에서 하이라이트(반짝임)를 만듭니다.

`램버트 (Lambert) 조명 모델`
난반사를 계산하는 가장 간단하고 일반적인 모델입니다. 표면이 받는 빛의 양은 표면의 법선(Normal) 방향과 광원(Light)의 방향 사이의 각도에 따라 결정된다는 원리를 이용합니다. 이 각도는 두 벡터의 내적(Dot Product)으로 쉽게 계산할 수 있습니다.

`Dot(Normal, Light Direction)` 결과가 1이면 빛을 정면으로 받는 것이고, 0이면 90도로 비껴 맞는 것, 음수이면 뒷면을 향하는 것입니다.

`saturate() 함수`를 이용해 0과 1 사이의 값으로 만들어 빛의 감쇠량으로 사용합니다.

`법선 벡터 (Normal Vector)`
3D 모델의 각 정점(또는 면)이 바라보는 방향을 나타내는 단위 벡터입니다. 조명 계산의 핵심 요소로, 이 벡터가 있어야 빛과 표면의 각도를 계산할 수 있습니다. 법선 벡터는 보통 오브젝트 공간(Object Space)에 저장되어 있으므로, 조명 계산을 위해서는 월드 공간(World Space)으로 변환해야 합니다.

과제 가이드
URP의 기본 방향 광원(Directional Light)을 기준으로 램버트 조명 모델을 구현하는 Unlit 셰이더 코드입니다. URP에서는 셰이더가 조명 정보를 자동으로 받기 위해 특정 규칙을 따라야 합니다.
```c
// 유니티 셰이더 파일: SimpleLambert.shader
Shader "MyShaders/SimpleLambert"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        // URP의 Lit 셰이더로 인식시키기 위한 태그
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" }

        Pass
        {
            // URP의 조명 패스임을 명시
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL; // 정점의 법선 벡터 입력
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalWS     : TEXCOORD0; // 월드 공간 법선 벡터를 전달
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // 법선 벡터를 오브젝트 공간에서 월드 공간으로 변환
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // 법선 벡터 정규화 (보간 과정에서 길이가 변할 수 있음)
                float3 normalWS = normalize(IN.normalWS);

                // URP에서 메인 광원 정보를 가져옴
                Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction;

                // 램버트 조명 계산: 내적 결과는 0 이하가 되지 않도록 saturate 처리
                half lambert = saturate(dot(normalWS, lightDir));

                // 최종 색상 = 기본색 * 난반사광 + 환경광
                // mainLight.color는 빛의 색상과 강도를 포함
                half3 finalColor = _BaseColor.rgb * lambert * mainLight.color;

                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
```

## 6챕터: Blinn-Phong 조명과 고급 조명
 
`Blinn-Phong 조명 모델`
정반사(Specular)를 계산하여 하이라이트를 만드는 모델입니다. '절반 벡터(Halfway Vector)'라는 개념을 도입하여 기존 Phong 모델보다 연산이 빠르고 효율적입니다.

`View Direction:` 표면에서 카메라(시점)를 향하는 벡터.

`Light Direction:` 광원에서 표면을 향하는 벡터.

`Halfway Vector:` View Direction과 Light Direction의 중간 벡터. normalize(viewDir + lightDir)로 계산합니다.

`pow(saturate(dot(normalWS, halfwayDir)), _Shininess)`: 법선과 절반 벡터가 얼마나 일치하는지를 계산하여 하이라이트의 강도를 결정합니다. _Shininess 값으로 반짝임의 집중도를 조절합니다.

과제 가이드
5챕터 코드에 Blinn-Phong 정반사 계산을 추가한 코드입니다.
```c
// 셰이더 경로: "MyShaders/SimpleBlinnPhong"
// Properties에 추가:
_Shininess ("Shininess", Range(0.1, 100)) = 20

// Varyings 구조체에 추가:
float3 positionWS     : TEXCOORD1; // 월드 공간 정점 위치

// CBUFFER에 추가:
half _Shininess;

// vert 함수에 추가:
OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);

// frag 함수 수정:
half4 frag (Varyings IN) : SV_Target
{
    // ... (램버트 계산까지는 동일)

    // Blinn-Phong 계산에 필요한 벡터들
    float3 normalWS = normalize(IN.normalWS);
    Light mainLight = GetMainLight();
    float3 lightDir = mainLight.direction;

    // 카메라 위치는 URP 전역 변수 _WorldSpaceCameraPos 에서 가져옴
    float3 viewDir = normalize(_WorldSpaceCameraPos - IN.positionWS);
    float3 halfwayDir = normalize(lightDir + viewDir);

    // 정반사(Specular) 계산
    half specular = pow(saturate(dot(normalWS, halfwayDir)), _Shininess);

    // 난반사(Diffuse) 계산
    half lambert = saturate(dot(normalWS, lightDir));

    // 최종 색상 = (난반사 + 정반사) * 빛 색상 * 기본 색상
    half3 finalColor = (_BaseColor.rgb * lambert + specular) * mainLight.color;

    return half4(finalColor, 1.0);
}
```

## 7챕터: 투명도와 블렌딩
`알파 블렌딩 (Alpha Blending)`
반투명 효과를 내는 기법입니다. 프래그먼트 셰이더가 계산한 색상의 알파(Alpha, 불투명도) 값을 이용해 배경색과 섞습니다.

`"Queue"="Transparent"`: 렌더링 순서를 불투명 오브젝트들 뒤로 미룹니다. 투명 오브젝트는 뒤에 있는 것이 먼저 그려져야 올바르게 보입니다.

`ZWrite Off`: 깊이 버퍼(Z-Buffer)에 쓰기를 비활성화합니다. 반투명 오브젝트가 다른 오브젝트를 가리는 것을 막기 위함입니다.

`Blend SrcAlpha OneMinusSrcAlpha`: 가장 일반적인 블렌딩 공식으로, (SourceColor * SourceAlpha) + (DestinationColor * (1 - SourceAlpha))를 의미합니다.

`알파 테스팅` (Alpha Testing / Cutout)
텍스처의 알파 값이 특정 임계값(Threshold)보다 낮으면 해당 픽셀을 아예 그리지 않는 기법입니다. 나뭇잎, 철조망처럼 외곽선이 복잡한 오브젝트를 표현할 때 유용합니다. 블렌딩보다 성능 부하가 적습니다.

`clip(value)`: HLSL 내장 함수로, value가 0보다 작으면 해당 픽셀의 렌더링을 중단합니다.

과제 가이드
1. 반투명 유리 셰이더
```c
Shader "MyShaders/TransparentGlass"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,0.5)
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            // ... (vert, frag 기본 구조)
            half4 frag (Varyings IN) : SV_Target
            {
                return _Color; // Properties에서 설정한 색상과 알파값 반환
            }
            ENDHLSL
        }
    }
}
```
2. Cutout 셰이더
```c
// Properties에 추가:
_MainTex ("Texture", 2D) = "white" {}
_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

// Pass 태그 수정:
Tags { "RenderType"="TransparentCutout" }

// frag 함수 수정:
half4 frag (Varyings IN) : SV_Target
{
    half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
    // 텍스처의 알파값이 _Cutoff 값보다 작으면 픽셀을 버림
    clip(texColor.a - _Cutoff);
    return texColor;
}
```

## 8챕터: 정점 셰이더 활용

`정점 위치 조작`
지금까지 정점 셰이더(vert)는 정점의 위치를 좌표 공간 변환만 했습니다. 하지만 정점의 위치(positionOS)를 변환하기 전에 직접 수정하면 오브젝트의 형태를 동적으로 바꿀 수 있습니다.
`
_Time 변수`
유니티가 셰이더에 자동으로 제공하는 내장 변수로, 시간의 흐름에 따른 값을 담고 있습니다. _Time.y가 일반적으로 사용되는 시간 값(Time.time)입니다. 이를 sin, cos 같은 삼각함수와 조합하면 주기적인 움직임을 쉽게 만들 수 있습니다.

`과제 가이드`
바람에 흔들리는 깃발처럼 평면(Plane)을 위아래로 출렁이게 하는 셰이더 코드입니다.
```c
// 유니티 셰이더 파일: WavingFlag.shader
Shader "MyShaders/WavingFlag"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WaveSpeed ("Wave Speed", Float) = 1.0
        _WaveHeight ("Wave Height", Float) = 0.1
    }
    SubShader
    {
        // ... (기본 구조)
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // ... (include, structs)

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half _WaveSpeed;
                half _WaveHeight;
            CBUFFER_END
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);


            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                // 정점의 x 위치와 시간에 따라 sin 값을 계산하여 y 위치를 변경
                float wave = sin(IN.positionOS.x + _Time.y * _WaveSpeed) * _WaveHeight;
                IN.positionOS.y += wave;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
            }
            ENDHLSL
        }
    }
}
```
이 셰이더를 Plane 오브젝트에 적용하고 인스펙터에서 Wave Speed와 Wave Height 값을 조절해보세요.
