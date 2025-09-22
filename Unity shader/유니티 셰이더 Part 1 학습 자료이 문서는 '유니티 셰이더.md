# 유니티 셰이더 Part 1 학습 자료
이 문서는 '유니티 셰이더 16주 완성 커리큘럼'의 Part 1 내용을 보충하는 학습 자료입니다. 각 주차별 핵심 개념에 대한 상세한 설명과 코드 예제를 통해 셰이더의 기초를 탄탄히 다지는 것을 목표로 합니다.

## 1주차: 그래픽스 파이프라인 입문
핵심 개념 상세
### 셰이더 (Shader) 란?
셰이더는 GPU(그래픽 처리 장치)에서 실행되도록 작성된 프로그램입니다. 화면에 픽셀 하나를 어떤 색으로 그릴지, 3D 모델의 정점을 어디에 위치시킬지 등 그래픽 렌더링의 거의 모든 과정을 제어합니다. CPU가 게임 로직, 물리 계산 등 일반적인 연산을 담당한다면, GPU는 셰이더를 통해 수많은 픽셀과 정점을 동시에 병렬로 처리하는 데 특화되어 있습니다.

### 렌더링 파이프라인 (Rendering Pipeline)
3D 모델 데이터가 화면에 그려지기까지 거치는 일련의 단계를 의미합니다. 파이프라인처럼 데이터가 한 방향으로 흐르며 각 단계에서 처리됩니다.

### Application Stage (CPU): 
렌더링 할 오브젝트 결정, 컬링(Culling, 보이지 않는 오브젝트 제외), 드로우 콜(Draw Call, GPU에 렌더링 명령) 등 준비 작업을 합니다.

### Vertex Shader Stage (GPU): 
각 정점(Vertex)의 위치를 3D 공간에서 화면의 2D 좌표로 변환합니다. 정점의 색상이나 UV 좌표를 계산하기도 합니다.

### Rasterization Stage (GPU): 
정점 셰이더에서 변환된 정점들을 연결하여 삼각형(폴리곤)을 만들고, 이 삼각형이 화면의 어떤 픽셀을 덮을지 결정합니다.

### Fragment Shader Stage (GPU): 
래스터라이제이션 단계에서 결정된 각 픽셀(프래그먼트)의 최종 색상을 계산합니다. 텍스처를 입히고 조명을 계산하는 등 가장 복잡한 작업이 주로 여기서 이루어집니다.

## 유니티 렌더링 파이프라인 종류
`
Built-in Render Pipeline`: 가장 전통적인 방식의 파이프라인입니다. 유연성이 낮아 최근에는 잘 사용되지 않습니다.

`URP (Universal Render Pipeline)`: 모바일과 PC 등 다양한 플랫폼에서 높은 성능을 내도록 설계된 최신 파이프라인입니다. 스크립터블(Scriptable) 방식으로 커스터마이징이 용이합니다.

`HDRP (High Definition Render Pipeline)`: 고사양 PC와 콘솔을 타겟으로, 최고 수준의 그래픽 품질을 제공하는 파이프라인입니다.

`과제 가이드`
URP 프로젝트 생성은 'Unity Hub'에서 새 프로젝트를 생성할 때 템플릿 목록에서 '3D (URP)'를 선택하면 간단히 완료됩니다. 프로젝트가 생성되면 Assets/Settings 폴더에서 URP 에셋 파일을 찾아 Project Settings > Graphics의 'Scriptable Render Pipeline Settings'에 할당되어 있는지 확인해보세요.

## 2주차: 첫 셰이더와 ShaderLab
`ShaderLab 구조`
유니티 셰이더 파일은 HLSL 코드를 감싸는 ShaderLab이라는 선언적 언어로 작성됩니다.
```c
Shader "MyShaders/SimpleUnlit" // 셰이더의 경로와 이름
{
    Properties // 인스펙터에 노출될 변수 선언
    {
        _Color ("Main Color", Color) = (1,1,1,1) // (변수명, 인스펙터 라벨, 타입) = 기본값
    }
    SubShader // 셰이더의 실제 구현부
    {
        Pass // 렌더링 패스. 오브젝트를 한 번 그리는 단위
        {
            // HLSL 코드 시작
            HLSLPROGRAM
            // ...
            ENDHLSL
        }
    }
}
```
`Unlit Shader 작성`

'Unlit'은 '조명 없는'이라는 뜻으로, 조명의 영향을 받지 않고 지정된 색상이나 텍스처를 그대로 출력하는 가장 기본적인 셰이더입니다.

`과제 가이드`

아래는 과제를 위한 전체 코드 예시입니다. Project 창에서 Create > Shader > Unlit Shader로 파일을 생성하고 내용을 아래 코드로 교체한 뒤, 새 머티리얼(Material)을 만들어 이 셰이더를 적용하고 3D 오브젝트에 할당해보세요.
```c
// 유니티 셰이더 파일: SimpleColor.shader
Shader "MyShaders/SimpleColor"
{
    Properties
    {
        // 인스펙터에서 "Display Color"라는 이름으로 색상을 조절할 수 있는 _MyColor 변수 선언
        _MyColor ("Display Color", Color) = (1.0, 0.0, 0.0, 1.0) // 기본값: 빨간색
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Properties 블록의 변수를 HLSL에서 사용하기 위해 선언
            half4 _MyColor;

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                // 정점 위치를 오브젝트 공간에서 클립 공간으로 변환
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // 프래그먼트 셰이더는 단순히 _MyColor 값을 최종 색상으로 반환
                return _MyColor;
            }
            ENDHLSL
        }
    }
}
```
## 3주차: HLSL 기초와 좌표 공간

* HLSL (High-Level Shading Language)

DirectX 기반의 셰이딩 언어로, C와 유사한 문법을 가집니다. 유니티는 내부적으로 HLSL을 사용합니다.

데이터 타입: float (32비트 실수), half (16비트 실수, 정확도 낮지만 빠름), fixed (11비트 고정소수점, 저사양 모바일용). float4는 4개의 float 값을 가진 벡터(예: rgba 색상), float4x4는 4x4 행렬을 의미합니다.

좌표 공간 변환 (Coordinate Space Transformation)
그래픽스에서 가장 중요한 개념 중 하나입니다. 정점 데이터는 여러 좌표 공간을 거쳐 최종적으로 화면에 표시됩니다.

오브젝트 공간 (Object/Local Space): 모델링 프로그램에서 만든 모델 원점(0,0,0) 기준의 좌표계.

월드 공간 (World Space): 유니티 씬의 중심(0,0,0) 기준의 좌표계. 오브젝트의 위치, 회전, 크기 변환이 적용된 후의 좌표입니다.

뷰 공간 (View/Camera Space): 카메라의 위치가 원점(0,0,0)이 되는 좌표계. 카메라 시점에서 본 상대적인 위치입니다.

클립 공간 (Clip Space/Homogeneous Clip Space): 카메라의 시야각(FOV)과 절단 평면(Clipping Planes)을 고려하여 화면에 보일 영역(-1에서 1 사이의 값으로 정규화)을 결정하는 4차원 좌표계. 이 공간 밖의 정점은 잘려나갑니다.

UNITY_MATRIX_MVP (Built-in) / TransformObjectToHClip() (URP): 이 행렬(또는 함수)은 정점 위치를 오브젝트 공간에서 클립 공간으로 한 번에 변환해주는 마법 같은 도구입니다. (Model * View * Projection 행렬의 곱)

과제 가이드
2주차 예제 코드의 vert 함수를 다시 살펴보세요. TransformObjectToHClip(IN.positionOS.xyz) 라인이 바로 3D 오브젝트의 정점 위치(positionOS)를 최종적으로 화면에 표시될 좌표(positionHCS)로 변환하는 핵심 코드입니다. 이 한 줄에 좌표 공간 변환의 모든 과정이 압축되어 있습니다.

## 4주차: 텍스처와 UV 매핑
` UV 좌표`
3D 모델의 표면을 2D 평면처럼 펼쳐놓은 좌표계입니다. U는 가로(x), V는 세로(y) 방향을 나타내며, 보통 0에서 1 사이의 값을 가집니다. 이 UV 좌표 덕분에 2D 이미지를 3D 모델 표면에 정확하게 입힐 수 있습니다.

`텍스처 샘플링 (Texture Sampling)`
UV 좌표를 이용해 텍스처 이미지의 특정 위치에 있는 픽셀 색상 값을 가져오는 과정입니다. HLSL에서는 tex2D (Built-in) 또는 SAMPLE_TEXTURE2D (URP) 매크로를 사용합니다.

과제 가이드
아래는 텍스처를 입히고 Tiling/Offset을 조절하는 셰이더의 전체 코드입니다.

```c
// 유니티 셰이더 파일: SimpleTexture.shader
Shader "MyShaders/SimpleTexture"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {} // 2D 텍스처를 받는 _MainTex 변수
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0; // 모델의 UV 좌표를 입력받음
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0; // UV 좌표를 프래그먼트 셰이더로 전달
            };

            // Properties의 텍스처 변수와 Tiling/Offset 정보를 담는 변수 선언
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST; // _ST 접미사는 유니티가 자동으로 Tiling(xy)과 Offset(zw) 값을 채워줌

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // UV 좌표에 Tiling/Offset 적용 (TRANSFORM_TEX 매크로 사용)
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // 전달받은 UV 좌표로 _MainTex에서 색상 샘플링
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                return color;
            }
            ENDHLSL
        }
    }
}
```
이 셰이더를 적용한 머티리얼의 인스펙터를 보면 _MainTex 슬롯과 함께 Tiling, Offset 값을 조절하는 필드가 나타납니다. 이 값을 변경하며 텍스처가 어떻게 변하는지 관찰해보세요.