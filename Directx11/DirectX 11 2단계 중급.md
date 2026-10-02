# DirectX 11 학습 2단계: 중급 (핵심 기능 마스터)
> **따라 하기**: 1단계의 `main.cpp` 를 확장해서 진행합니다 (상수 버퍼, 텍스처, 깊이 버퍼를 추가). 아래 C++ 코드는 DirectX Tool Kit 의 `SimpleMath`(`#include <SimpleMath.h>`, NuGet `directxtk_desktop_win10`)를 사용하는 *조각*이며 전체 프로그램이 아닙니다. 텍스처 로드는 DirectXTK 의 `CreateWICTextureFromFile`(`WICTextureLoader.h`)이 가장 간단합니다. 환경과 행렬 규약은 [실습 환경과 공통 규약](../Shader%20Learning/0.%20실습%20환경과%20공통%20규약.md)을 먼저 읽으세요. 작성자가 직접 빌드해 확인하지는 못했습니다.

### 목표
단순한 도형 렌더링을 넘어, 3D 그래픽스의 핵심 요소인 텍스처, 조명, 카메라의 원리를 이해하고 직접 구현함으로써 사실적인 3D 씬을 구성하는 능력을 기릅니다. 이 단계를 마치면 3D 모델에 텍스처를 입히고, 조명을 비추며, 원하는 시점에서 씬을 바라볼 수 있게 됩니다.

## 1. HLSL 셰이더 프로그래밍 심화
중급 단계에서는 C++ 애플리케이션과 셰이더 간의 데이터 통신이 더욱 중요해집니다.

상수 버퍼 (Constant Buffer): C++ 코드에서 계산된 데이터(행렬, 조명 정보, 시간 등)를 GPU의 셰이더로 전달하는 주된 방법입니다. cbuffer 키워드를 사용하여 HLSL에서 선언하며, C++에서는 ID3D11Buffer로 생성하고 UpdateSubresource 또는 Map/Unmap을 통해 데이터를 업데이트합니다.

시맨틱 (Semantics): 셰이더의 입력과 출력 데이터가 어떤 의미를 갖는지 알려주는 식별자입니다. POSITION, NORMAL, TEXCOORD, COLOR 등이 있으며, 입력 레이아웃과 셰이더 스테이지 간의 데이터 연결을 보장합니다.

## 2. 텍스처링 (Texturing)
밋밋한 단색 폴리곤에 사실적인 표면 질감을 입히는 과정입니다.

개념: 3D 모델의 표면에 2D 이미지를 씌우는 기술입니다. 각 정점은 모델 표면의 어느 지점에 이미지의 어떤 부분이 매핑될지를 나타내는 UV 좌표(텍스처 좌표)를 가집니다.

C++ 구현:

텍스처 로딩: DirectXTex 라이브러리나 WIC(Windows Imaging Component) API를 사용하여 .dds, .png, .jpg 같은 이미지 파일을 로드합니다.

리소스 생성: 로드한 이미지 데이터로 ID3D11Texture2D 리소스를 생성합니다.

셰이더 리소스 뷰 (Shader Resource View): 생성된 텍스처를 셰이더가 읽을 수 있도록 ID3D11ShaderResourceView를 생성합니다. 이 뷰를 픽셀 셰이더에 바인딩(PSSetShaderResources)합니다.

샘플러 상태 (Sampler State): 텍스처를 샘플링(색상 추출)할 방법을 정의합니다. 텍셀이 픽셀보다 크거나 작을 때 어떻게 필터링할지(Linear, Point), UV 좌표가 0~1 범위를 벗어났을 때 어떻게 처리할지(Wrap, Mirror, Clamp) 등을 ID3D11SamplerState로 설정합니다.

HLSL 구현:

픽셀 셰이더에서 Texture2D와 SamplerState 객체를 선언합니다.

Texture2D.Sample(SamplerState, UV_Coordinates) 함수를 호출하여 특정 UV 좌표의 텍스처 색상(텍셀)을 가져옵니다.

## 3. 조명 (Lighting)
조명은 3D 씬에 깊이와 현실감을 부여하는 가장 중요한 요소입니다. 가장 널리 쓰이는 **퐁 조명 모델(Phong Reflection Model)**을 기반으로 학습합니다.

퐁 모델은 빛을 3가지 요소로 분해하여 계산합니다.

환경광 (Ambient): 씬 전체에 고르게 퍼져있는 빛입니다. 직접적인 광원이 없어도 물체의 기본 형태를 알아볼 수 있게 해주며, 그림자를 너무 어둡지 않게 만듭니다.

Ambient = 전역 빛의 색 * 물체 표면의 색

난반사 (Diffuse): 특정 방향에서 오는 빛이 물체 표면에 부딪혀 여러 방향으로 흩어지는 것을 표현합니다. 빛의 방향과 표면이 마주 보는 각도에 따라 밝기가 결정됩니다. (표면에 수직으로 빛이 닿을수록 밝아짐)

Diffuse = 빛의 색 * 물체 표면의 색 * dot(표면 법선 벡터, 빛 방향 벡터)

정반사 (Specular): 광택이 있는 표면에서 빛이 특정 방향으로 강하게 반사되어 생기는 '하이라이트'를 표현합니다. 빛의 반사 방향과 카메라(시점) 방향이 가까울수록 밝게 빛납니다.

Specular = 빛의 색 * 반사광의 색 * pow(dot(카메라 방향 벡터, 빛 반사 벡터), 광택도)

최종 색상 = Ambient + Diffuse + Specular

이 계산은 주로 픽셀 셰이더에서 각 픽셀 단위로 수행됩니다.

## 4. 카메라와 변환 행렬
3D 공간의 물체를 2D 화면에 표시하기 위해서는 여러 단계의 좌표계 변환이 필요하며, 이는 행렬 곱셈으로 이루어집니다.

월드 변환 (World Transform): 모델의 고유 좌표계(로컬 공간)에서 3D 씬의 공통 좌표계(월드 공간)로 물체를 배치하는 변환입니다. 이동(Translate), 회전(Rotate), 크기(Scale) 행렬의 조합으로 만들어집니다.

뷰 변환 (View Transform): 월드 공간의 물체들을 카메라의 시점에서 바라보는 좌표계(뷰 공간)로 변환합니다. 카메라의 위치, 바라보는 지점, 상단 방향 벡터로 계산됩니다.

투영 변환 (Projection Transform): 3D 뷰 공간을 2D 화면에 투영하는 변환입니다. 원근감을 표현하기 위해 주로 원근 투영(Perspective Projection) 행렬을 사용하며, 시야각(FOV), 종횡비(Aspect Ratio), 근접/원접 평면(Near/Far Plane)으로 정의됩니다.

이 세 행렬(World, View, Projection)을 곱한 WVP 행렬을 정점 셰이더로 전달하여, 각 정점의 위치를 최종적인 2D 화면 좌표로 변환합니다.
```cpp
// C++ 에서의 행렬 계산 예시
Matrix mWorld = Matrix::CreateRotationY(time) * Matrix::CreateTranslation(position);
Matrix mView = Matrix::CreateLookAt(cameraPosition, cameraTarget, cameraUp);
Matrix mProjection = Matrix::CreatePerspectiveFieldOfView(fov, aspectRatio, nearPlane, farPlane);

Matrix mWVP = mWorld * mView * mProjection;

// 상수 버퍼에 올릴 때는 반드시 전치(Transpose)한다.
//   SimpleMath/DirectXMath 는 행 우선(row-major), HLSL cbuffer 의 기본 패킹은 열 우선(column-major) 이기 때문.
//   (HLSL 의 mul(vector, matrix) 규약은 이 전치를 전제로 한다.)
struct CbChangesEveryFrame { Matrix World, View, Projection; };
CbChangesEveryFrame cb;
cb.World = mWorld.Transpose();
cb.View = mView.Transpose();
cb.Projection = mProjection.Transpose();
context->UpdateSubresource(cbuffer.Get(), 0, nullptr, &cb, 0, 0); // cbuffer 는 BIND_CONSTANT_BUFFER, ByteWidth=sizeof(CbChangesEveryFrame)(=192, 16의 배수)
context->VSSetConstantBuffers(0, 1, cbuffer.GetAddressOf());
```
## 5. 3D 모델 렌더링
이제 직접 만든 정점 데이터 대신, 외부에서 제작된 3D 모델 파일을 불러와 렌더링하는 방법을 알아봅니다.

메시(Mesh): 3D 모델을 구성하는 기본 단위로, 정점(Vertex) 데이터와 인덱스(Index) 데이터의 집합입니다.

파일 포맷: .obj, .fbx 등 다양한 3D 모델 포맷이 있습니다.

로더(Loader): 이러한 모델 파일을 파싱하여 정점/인덱스 데이터를 추출하는 라이브러리가 필요합니다. (예: Assimp)

데이터 활용: 로드된 정점 데이터(위치, 법선, UV좌표 등)를 정점 버퍼에, 인덱스 데이터를 인덱스 버퍼에 채워넣고 렌더링하면 됩니다.

**(완성형)** 아래 셰이더는 위 C++ 조각과 짝입니다. 호스트가 해야 할 일: 정점 레이아웃 `POSITION`(R32G32B32_FLOAT, 0) / `NORMAL`(R32G32B32_FLOAT, 12) / `TEXCOORD`(R32G32_FLOAT, 24), 슬롯 b0 = 행렬 상수 버퍼(VS), b1 = 조명 상수 버퍼(**PS 에 바인딩**: `PSSetConstantBuffers(1, …)`), t0 = 텍스처 SRV, s0 = 샘플러, 그리고 3D 장면이므로 **깊이 버퍼(DSV)와 `ClearDepthStencilView`** 가 필요합니다.
```hlsl
// 상수 버퍼 (C++에서 데이터를 받아옴)
cbuffer CbChangesEveryFrame : register(b0)
{
    matrix World;
    matrix View;
    matrix Projection;
};

cbuffer CbLightInfo : register(b1)
{
    float4 LightDir;   // w는 사용 안 함
    float4 LightColor; // 조명 색상
    float4 CameraPos;  // 카메라 위치
};


// 텍스처와 샘플러
Texture2D txDiffuse : register(t0);
SamplerState samLinear : register(s0);


// Vertex Shader의 입력 구조체
struct VS_INPUT
{
    float4 Pos   : POSITION;
    float3 Norm  : NORMAL;
    float2 Tex   : TEXCOORD0;
};

// Pixel Shader의 입력 구조체
struct PS_INPUT
{
    float4 Pos      : SV_POSITION;
    float3 Norm     : NORMAL;
    float2 Tex      : TEXCOORD0;
    float3 WorldPos : TEXCOORD1;
};


// 정점 셰이더
PS_INPUT VS(VS_INPUT input)
{
    PS_INPUT output = (PS_INPUT)0;

    // 1. 월드, 뷰, 투영 행렬을 곱하여 정점 위치를 변환
    output.Pos = mul(input.Pos, World);
    output.Pos = mul(output.Pos, View);
    output.Pos = mul(output.Pos, Projection);

    // 2. 월드 행렬을 이용해 법선 벡터를 변환하고 정규화
    output.Norm = normalize(mul(input.Norm, (float3x3)World));
    
    // 3. 월드 공간에서의 정점 위치 계산
    output.WorldPos = mul(input.Pos, World).xyz;

    // 4. 텍스처 좌표는 그대로 전달
    output.Tex = input.Tex;

    return output;
}


// 픽셀 셰이더
float4 PS(PS_INPUT input) : SV_Target
{
    // 텍스처에서 기본 색상을 샘플링
    float4 textureColor = txDiffuse.Sample(samLinear, input.Tex);

    // 환경광(Ambient) 계산
    float4 ambient = float4(0.1f, 0.1f, 0.1f, 1.0f) * textureColor;

    // 난반사(Diffuse) 계산
    float3 lightDir = normalize(LightDir.xyz);          // LightDir: 빛이 진행하는 방향(광원 -> 표면)
    float3 N = normalize(input.Norm);                   // 보간된 법선은 길이가 1 이 아닐 수 있다
    float diffuseFactor = saturate(dot(N, -lightDir));
    float4 diffuse = diffuseFactor * LightColor * textureColor;
    
    // 정반사(Specular) 계산
    float3 viewDir = normalize(CameraPos.xyz - input.WorldPos);
    float3 reflectDir = reflect(lightDir, N);
    // 32.0f 는 광택도(shininess). 빛을 받지 않는 면(diffuseFactor == 0)에서는 하이라이트가 생기지 않게 막는다.
    float specularFactor = pow(saturate(dot(viewDir, reflectDir)), 32.0f) * (diffuseFactor > 0.0f ? 1.0f : 0.0f);
    float4 specular = specularFactor * LightColor;

    // 최종 색상 = 환경광 + 난반사 + 정반사
    float4 finalColor = ambient + diffuse + specular;
    finalColor.a = textureColor.a;
    return finalColor;
}
```
