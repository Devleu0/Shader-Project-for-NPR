# 유니티 셰이더 Part 1 학습 자료
이 문서는 ShaderLab 학습 자료입니다. 코드 예제를 통해 셰이더의 기초를 탄탄히 다지는 것을 목표로 합니다.

 * 목차
* [1. 그래픽스 파이프라인 입문](#1-그래픽스-파이프라인-입문)
* [2. 첫 셰이더와 ShaderLab](#2-첫-셰이더와-shaderlab)
* [3. HLSL 기초와 좌표 공간](#3-hlsl-기초와-좌표-공간)
* [4. 텍스처와 UV 매핑](#4-텍스처와-uv-매핑)
* [5. ShaderLab 특징](#shaderlab-특징)


## 1. 그래픽스 파이프라인 입문

### **셰이더 (Shader) 란?**
셰이더는 GPU(그래픽 처리 장치)에서 실행되도록 작성된 프로그램입니다. 화면에 픽셀 하나를 어떤 색으로 그릴지, 3D 모델의 정점을 어디에 위치시킬지 등 그래픽 렌더링의 거의 모든 과정을 제어합니다. CPU가 게임 로직, 물리 계산 등 일반적인 연산을 담당한다면, GPU는 셰이더를 통해 수많은 픽셀과 정점을 동시에 병렬로 처리하는 데 특화되어 있습니다.

## 렌더링 파이프라인 (Rendering Pipeline)
3D 모델 데이터가 화면에 그려지기까지 거치는 일련의 단계를 의미합니다. 파이프라인처럼 데이터가 한 방향으로 흐르며 각 단계에서 처리됩니다.

* **Application Stage**
렌더링 할 오브젝트 결정, 컬링(Culling, 보이지 않는 오브젝트 제외), 드로우 콜(Draw Call, GPU에 렌더링 명령) 등 준비 작업을 합니다.

* **Vertex Shader Stage**
각 정점(Vertex)의 위치를 3D 공간에서 화면의 2D 좌표로 변환합니다. 정점의 색상이나 UV 좌표를 계산하기도 합니다.

* **Rasterization Stage**
정점 셰이더에서 변환된 정점들을 연결하여 삼각형(폴리곤)을 만들고, 이 삼각형이 화면의 어떤 픽셀을 덮을지 결정합니다.

* **Fragment Shader Stage**
래스터라이제이션 단계에서 결정된 각 픽셀(프래그먼트)의 최종 색상을 계산합니다. 텍스처를 입히고 조명을 계산하는 등 가장 복잡한 작업이 주로 여기서 이루어집니다.

## 유니티 렌더링 파이프라인 종류

* `Built-in Render Pipeline`: 가장 전통적인 방식의 파이프라인입니다. 유연성이 낮아 최근에는 잘 사용되지 않습니다.

* `URP (Universal Render Pipeline)`: 모바일과 PC 등 다양한 플랫폼에서 높은 성능을 내도록 설계된 최신 파이프라인입니다. 스크립터블(Scriptable) 방식으로 커스터마이징이 용이합니다.

* `HDRP (High Definition Render Pipeline)`: 고사양 PC와 콘솔을 타겟으로, 최고 수준의 그래픽 품질을 제공하는 파이프라인입니다.


# Unity에서 사용 가능한 셰이더 종류

Unity는 현재 **Programmable Pipeline**을 기반으로 다양한 방식의 셰이더를 지원합니다.  
* Fixed Function Shader는 더 이상 지원되지 않으며, 아래 방식들이 주로 사용됩니다.
* Surface Shader도 현 시점에서는 권장되지 않습니다.

## 1. **Surface Shader**
- Unity의 **고전적인 셰이더 작성 방식**  
- ShaderLab을 통해 간단한 선언으로 Unity의 표준 조명 모델을 자동 처리  
- 내부적으로는 HLSL 코드로 변환되어 실행됨
    -  장점: 쓰기 쉽고, Unity의 조명/섀도우 시스템과 자동 연동  
    -  단점: 최신 SRP(URP/HDRP)에서는 권장되지 않음

 예시 
```c
#pragma surface surf Standard fullforwardshadows
```


## 2. **Unlit Shader**

* 조명 계산을 전혀 하지 않는 셰이더
* UI, HUD, 특수 효과 등에 주로 사용
* HLSL을 직접 작성해야 하며, 매우 단순한 구조를 가짐


## 3. **Vertex/Fragment Shader** (Programmable Shader)

* GPU 파이프라인의 **Vertex Shader**와 **Fragment Shader**를 직접 작성
* Unity의 ShaderLab 구문과 함께 HLSL 코드 포함 가능
* 가장 범용적이며, 커스터마이즈 가능성이 높음
* URP/HDRP 모두 사용 가능

 

```c
Pass {
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    ENDCG
}
```


## 4. **Compute Shader**

* 화면 렌더링과는 별개로 GPU 연산을 처리하기 위한 셰이더
* GPGPU(병렬 연산), 물리 시뮬레이션, AI, 파티클 시스템 등에 활용
* DirectX 11 이상, Metal, Vulkan에서 지원
* 렌더링보다 데이터 처리용으로 주로 사용됨

 확장자

```
.compute
```

## 5. **Shader Graph**

* 노드 기반 셰이더 제작 도구
* SRP(URP/HDRP) 전용
* HLSL을 몰라도 시각적으로 복잡한 셰이더 제작 가능
* URP에서는 Lightweight Shader Graph, HDRP에서는 HDRP Shader Graph 사용

 특징

* Unlit, Lit, PBR 등 다양한 마스터 노드 제공
* 커스텀 함수 노드로 HLSL 코드 삽입 가능


## 6. **SRP 전용 셰이더**

Unity의 **Scriptable Render Pipeline(SRP)**(URP/HDRP)에 특화된 셰이더들.

* ### URP Shader

  * Universal Render Pipeline 전용
  * 경량 & 범용 (모바일, VR, 일반 프로젝트에 적합)
  * Shader Graph 또는 HLSL 기반으로 작성

* ### HDRP Shader

  * High Definition Render Pipeline 전용
  * 고품질 PBR, 실사 렌더링 지향
  * 물리 기반 라이팅, 레이 트레이싱 지원

##  지원 중단된 셰이더

* **Fixed Function Shader**

  * 예: `Material { Diffuse ... }`, `Lighting On`, `SetTexture`
  * Unity 5 이후 Deprecated, 현재 버전에서는 지원되지 않음


##  정리

* 과거: **Fixed Function Shader** → 현재는 사용 불가
* 현재 사용 가능:

  * **Surface Shader** (레거시 지원용)
  * **Unlit Shader**
  * **Vertex/Fragment Shader (HLSL)**
  * **Compute Shader**
  * **Shader Graph (SRP 전용)**
  * **URP/HDRP 전용 셰이더**

---

URP 프로젝트 생성은 'Unity Hub'에서 새 프로젝트를 생성할 때 템플릿 목록에서 '3D (URP)'를 선택하면 간단히 완료됩니다. 프로젝트가 생성되면 Assets/Settings 폴더에서 URP 에셋 파일을 찾아 Project Settings > Graphics의 'Scriptable Render Pipeline Settings'에 할당되어 있는지 확인해보세요.

## 첫 셰이더와 ShaderLab
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

## 각 타입의 특징

### float
- 표준 32비트 부동소수점.
- 높은 정밀도가 필요할 때 사용.
- GPU 연산 비용이 가장 큼.
- 일반적으로 복잡한 계산, 위치 계산, 물리 시뮬레이션 등에 사용.

****
```hlsl
float3 pos = float3(1.0, 2.0, 3.0);
```

---

### half

* 16비트 부동소수점.
* 정밀도는 낮지만 계산이 빠르고 메모리 사용량이 절반.
* 주로 색 계산, 라이팅, 텍스처 좌표 계산 등에 사용.
* 모바일/VR 등에서 성능 최적화에 자주 사용.

****

```hlsl
half brightness = 0.8;
```

---

### fixed

* 11비트 고정소수점.
* 매우 낮은 정밀도 → 주로 **색 데이터(0~1 범위)**에 최적화됨.
* 메모리와 성능을 아주 많이 절약.
* 주로 모바일 셰이더나 간단한 색 조정에서 사용.

****

```hlsl
fixed4 col = fixed4(1.0, 0.5, 0.2, 1.0);
```

---

## 언제 무엇을 쓸까?

* **정밀도 최우선** → `float`
* **균형(정밀도 + 성능)** → `half`
* **성능 최우선, 낮은 정밀도 허용** → `fixed`

 **팁**
Unity의 Surface Shader에서 `fixed`는 기본적으로 색 속성에 많이 사용됩니다.
왜냐하면 색값은 보통 0~1 범위이기 때문에 `fixed` 타입이 충분하고, GPU 메모리 효율도 높기 때문입니다.


## 3. HLSL 기초와 좌표 공간

* HLSL (High-Level Shading Language)

DirectX 기반의 셰이딩 언어로, C와 유사한 문법을 가집니다. 유니티는 내부적으로 HLSL을 사용합니다.

* 데이터 타입: float (32비트 실수), half (16비트 실수, 정확도 낮지만 빠름), fixed (11비트 고정소수점, 저사양 모바일용). float4는 4개의 float 값을 가진 벡터(예: rgba 색상), float4x4는 4x4 행렬을 의미합니다.

### 좌표 공간 변환 (Coordinate Space Transformation)
그래픽스에서 가장 중요한 개념 중 하나입니다. 정점 데이터는 여러 좌표 공간을 거쳐 최종적으로 화면에 표시됩니다.

    * **오브젝트 공간** (Object/Local Space): 모델링 프로그램에서 만든 모델 원점(0,0,0) 기준의 좌표계.

    * **월드 공간 (World Space)**: 유니티 씬의 중심(0,0,0) 기준의 좌표계. 오브젝트의 위치, 회전, 크기 변환이 적용된 후의 좌표입니다.

    * **뷰 공간 (View/Camera Space)**: 카메라의 위치가 원점(0,0,0)이 되는 좌표계. 카메라 시점에서 본 상대적인 위치입니다.

    * **클립 공간 (Clip Space/Homogeneous Clip Space)**: 카메라의 시야각(FOV)과 절단 평면(Clipping Planes)을 고려하여 화면에 보일 영역(-1에서 1 사이의 값으로 정규화)을 결정하는 4차원 좌표계. 이 공간 밖의 정점은 잘려나갑니다.

UNITY_MATRIX_MVP (Built-in) / TransformObjectToHClip() (URP): 이 행렬(또는 함수)은 정점 위치를 오브젝트 공간에서 클립 공간으로 한 번에 변환해주는 마법 같은 도구입니다. (Model * View * Projection 행렬의 곱)


예제 코드의 vert 함수를 다시 살펴보세요. TransformObjectToHClip(IN.positionOS.xyz) 라인이 바로 3D 오브젝트의 정점 위치(positionOS)를 최종적으로 화면에 표시될 좌표(positionHCS)로 변환하는 핵심 코드입니다. 이 한 줄에 좌표 공간 변환의 모든 과정이 압축되어 있습니다.

## 4. **텍스처와 UV 매핑**
` UV 좌표`
3D 모델의 표면을 2D 평면처럼 펼쳐놓은 좌표계입니다. U는 가로(x), V는 세로(y) 방향을 나타내며, 보통 0에서 1 사이의 값을 가집니다. 이 UV 좌표 덕분에 2D 이미지를 3D 모델 표면에 정확하게 입힐 수 있습니다.

`텍스처 샘플링 (Texture Sampling)`
UV 좌표를 이용해 텍스처 이미지의 특정 위치에 있는 픽셀 색상 값을 가져오는 과정입니다. HLSL에서는 tex2D (Built-in) 또는 SAMPLE_TEXTURE2D (URP) 매크로를 사용합니다.


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


## ShaderLab 특징
### 1. **속성(Property)의 종류**
Properties 블록에는 셰이더가 사용하는 변수들을 정의하며, 다양한 타입이 있습니다.

| 타입 | 설명 | 예시 |
|------|------|------|
| **Color** | 색상 변수. RGBA(빨강, 초록, 파랑, 알파) 값을 가짐 | `_Color ("Main Color", Color) = (1,1,1,1)` |
| **2D** | 텍스처 변수. 텍스처 파일을 할당할 수 있음 | `_MainTex ("Texture", 2D) = "white" {}` |
| **Float** | 단일 부동소수점(실수) 변수 | `_FloatVar ("Float", Float) = 0.5` |
| **Range(min, max)** | 일정 범위 내의 부동소수점 변수. 슬라이더로 조절됨 | `_Slider ("Slider", Range(0, 1)) = 0.5` |
| **Vector** | 4차원 벡터(x, y, z, w) 변수 | `_VectorVar ("Vector", Vector) = (0,0,0,0)` |
| **Cube** | 큐브맵(Cubemap) 변수 | `_CubeMap ("Cube Map", Cube) = ""` |

---

### 2. 태그(Tag)의 종류
태그는 셰이더가 렌더링 파이프라인과 어떻게 상호작용해야 하는지 정의하는 키-값 쌍입니다. 렌더링 파이프라인이 셰이더를 분류하고 처리하는 방식을 지정하는 메타데이터 역할을 합니다.

* "RenderType": 셰이더의 렌더링 타입을 명시합니다. (Opaque, Transparent, TransparentCutout 등)

* "Queue": 오브젝트의 렌더링 순서를 결정합니다. 숫자 값이 낮을수록 먼저 렌더링됩니다. (Geometry, AlphaTest, Transparent 등)

* "LightMode": 셰이더가 어떤 렌더링 패스(Forward, Deferred)에서 사용될지 지정합니다.

* "DisableBatching": 동적/정적 배칭(Batching)을 비활성화할지 여부를 설정합니다.

---

### 3. **SubShader 자동 선택**
Unity는 현재 실행 중인 그래픽 카드와 렌더링 경로에 가장 적합한 SubShader를 자동으로 선택합니다. 

    * Unity는 셰이더 파일에 정의된 SubShader들을 위에서부터 아래로 순서대로 확인합니다.

    * 각 SubShader에 정의된 **LOD (Level of Detail)**나 Tags 같은 조건이 현재 플랫폼의 사양과 일치하는지 검사합니다.

    * 조건이 일치하는 첫 번째 SubShader를 선택하고, 나머지 SubShader는 무시합니다.

    * 만약 모든 SubShader가 현재 플랫폼에서 실행될 수 없다면, Fallback 셰이더를 사용합니다.

---

### 4. 여러 개의 Pass 사용
하나의 SubShader 내부에 여러 개의 Pass 블록을 정의하여 다단계 렌더링 효과를 만들 수 있습니다. 각 Pass는 특정 효과를 담당하는 독립적인 렌더링 단계입니다.

* **외곽선 효과**: 첫 번째 Pass에서 검은색 외곽선을 그리고, 두 번째 Pass에서 일반적인 렌더링을 수행하여 외곽선이 있는 오브젝트를 만듭니다.

* **반사 효과**: 첫 번째 Pass에서 반사 큐브맵을 사용하여 반사율을 계산하고, 두 번째 Pass에서 최종 색상을 렌더링합니다.

* **다중 조명**: 하나의 Pass가 하나의 조명만 처리하는 경우, 여러 개의 Pass를 사용하여 여러 개의 조명을 적용할 수 있습니다.
```c
Shader "Example/MultiPass"
{
    // ...
    SubShader
    {
        // 첫 번째 패스: 외곽선 렌더링
        Pass
        {
            // 외곽선 렌더링을 위한 설정
        }

        // 두 번째 패스: 일반적인 오브젝트 렌더링
        Pass
        {
            // 일반적인 렌더링을 위한 설정
        }
    }
}
```

---

## Unity가 텍스처 프로퍼티를 정의할 때 자동으로 제공하는 변수

## 1. _ST (Scale, Translation)

 float4 _Name_ST
 타일링(Tiling)과 오프셋(Offset)

`.xy → Tiling 값`
`.zw → Offset 값`

```hlsl
uv = uv * _MainTex_ST.xy + _MainTex_ST.zw;
```
---

## 2. _TexelSize

 float4 _Name_TexelSize
 텍스처의 픽셀 크기 정보

`.x = 1 / width`
`.y = 1 / height`
`.z = width`
`.w = height`

주로 블러, 포스트 프로세싱, 커널 샘플링할 때 사용.

```hlsl
float2 texel = _MainTex_TexelSize.xy; // 한 픽셀 크기
fixed4 c = tex2D(_MainTex, uv + texel); // 옆 픽셀 샘플링
```


## 3. _HDR (HDR 관련)

 float4 _Name_HDR
 HDR 텍스처를 다룰 때 감마 보정이나 노출 보정을 위해 Unity가 제공.

색 공간 변환 및 HDR 파라미터 저장용.
Lightmap, Reflection Probe 텍스처에 자주 따라옴.



## 4. _TexelSize와 _ST를 함께 활용하는 경우

예를 들어 포스트 프로세싱 블러 셰이더에서
```hlsl
float2 uv = i.uv * _MainTex_ST.xy + _MainTex_ST.zw; // 타일링/오프셋 적용
float2 texel = _MainTex_TexelSize.xy; // 픽셀 크기
fixed4 col = tex2D(_MainTex, uv + texel * float2(1,0)); // 오른쪽 이웃 픽셀 샘플링
```


## 자동 제공 규칙 정리

반드시 Properties 블록에 텍스처를 정의해야 함.

이름 규칙
```cg
_MainTex → _MainTex_ST, _MainTex_TexelSize
_NormalMap → _NormalMap_ST, _NormalMap_TexelSize
```
Unity의 머티리얼 인스펙터에서 Tiling / Offset / 텍스처 크기를 변경하면 이 값들이 자동 업데이트됨.
