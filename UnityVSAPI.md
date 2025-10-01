# 유니티 셰이더 경험자를 위한 실제 그래픽스 API 셰이더 처리 개요

## 1. 유니티와 실제 API의 차이

* **Unity**

  * ShaderLab, Surface Shader, Shader Graph 등을 제공. 개발자는 추상화된 코드만 작성.
  * Unity가 내부적으로 **렌더 파이프라인**, **셰이더 컴파일**, **머티리얼 시스템**을 관리.
  * 즉, 사용자는 "이런 효과를 원한다"라고 선언하는 수준.
* **그래픽스 API (Direct3D, OpenGL, Vulkan 등)**

  * 셰이더를 직접 작성(HLSL/GLSL/SPIR-V) → API를 통해 GPU에 전달 → 파이프라인 객체로 연결.
  * 모든 단계(컴파일, 바인딩, 실행)를 개발자가 제어해야 함.

---

## 2. 셰이더 단계 (Shader Stages)

Unity에서는 `vert`/`frag` 함수 정도만 직접 작성했을 텐데, 실제 API에서는 더 세분화된 스테이지로 나뉨.

* **Vertex Shader**
  입력: 정점 데이터(위치, UV, 법선 등)
  출력: 클립 공간 좌표, 보간될 변수들
* **Tessellation Control / Evaluation Shader (옵션)**
  메시를 더 잘게 쪼개고 보간 처리.
* **Geometry Shader (옵션)**
  새로운 프리미티브를 생성하거나 수정.
* **Fragment/Pixel Shader**
  각 픽셀에 대해 색상, 깊이 등을 계산.
* **Compute Shader** (렌더링 파이프라인과 독립적)
  범용 GPU 연산.

Unity에서는 대부분 **Vertex + Fragment** 수준만 직접 제어했지만, 실제 API는 이 모든 스테이지를 직접 구성.

---

## 3. 셰이더 작성과 컴파일

### Unity

* `.shader` 파일 작성 → Unity가 자동으로 HLSL을 컴파일 → 플랫폼별 바이트코드(DXIL, SPIR-V 등) 생성.
* 사용자는 플랫폼별 차이를 크게 의식하지 않아도 됨.

### Direct3D / OpenGL / Vulkan

* 셰이더 소스(HLSL, GLSL)를 직접 작성.
* **런타임 전에 컴파일**하거나 **런타임 중에 API로 전달 후 컴파일**.
* 최종적으로 GPU가 이해하는 바이트코드(DXIL, SPIR-V 등)로 변환됨.

예시 (Direct3D 11)

  ```cpp
  ID3DBlob* vsBlob;
  D3DCompileFromFile(L"shader.hlsl", nullptr, nullptr, "VSMain", "vs_5_0", 0, 0, &vsBlob, nullptr);
  device->CreateVertexShader(vsBlob->GetBufferPointer(), vsBlob->GetBufferSize(), nullptr, &vertexShader);
  ```

---

## 4. 파이프라인 연결

### Unity

* `Pass { ... }` 블록 안에 vertex/fragment 함수 지정.
* Unity가 자동으로 **렌더 파이프라인**과 연결.

### API

* 셰이더 객체(VertexShader, PixelShader 등)를 각각 생성.
* **Input Layout(정점 데이터 형식)**, **Rasterizer State**, **Blend State** 등 파이프라인 상태를 직접 정의.
* 최종적으로 `Pipeline State Object`(PSO, Vulkan/D3D12)로 결합.

---

## 5. 리소스 바인딩 (상수, 텍스처 등)

### Unity

* `Properties` 블록으로 정의 → 머티리얼 Inspector에 표시 → C# 스크립트에서 `material.SetFloat`, `SetTexture`로 전달.

### 그래픽스 API

* **상수 버퍼(Constant Buffer / Uniform Buffer)** 생성 후 CPU 메모리에서 데이터 복사 → GPU에 바인딩.
* **샘플러/텍스처**를 각각 슬롯에 바인딩.
* 개발자가 모든 리소스 슬롯 번호, 크기, 레이아웃을 직접 관리해야 함.

예시 (D3D11)

```cpp
context->PSSetShaderResources(0, 1, &textureView);
context->PSSetSamplers(0, 1, &samplerState);
context->VSSetConstantBuffers(0, 1, &constantBuffer);
```

---

## 6. 실행 (Draw Call)

### Unity

* `Graphics.DrawMesh` 또는 카메라가 자동으로 `Render()`.
* 파이프라인 내부는 Unity가 관리.

### 실제 API

1. 파이프라인 상태 객체(PSO) 바인딩
2. 셰이더 리소스(버퍼, 텍스처 등) 바인딩
3. 정점 버퍼/인덱스 버퍼 바인딩
4. `Draw()` 호출

   ```cpp
   context->DrawIndexed(indexCount, 0, 0);
   ```

---

## 7. 정리 

* Unity에서는 **"재질(Material)" 중심** → 내부적으로 셰이더/리소스/파이프라인 상태를 관리.
* 실제 API에서는 **셰이더, 버퍼, 파이프라인 상태**를 **직접 연결**해야 함.
* 즉, Unity가 추상화해준 "머티리얼 시스템"과 "렌더링 파이프라인"을 **수동으로 만드는 것**이 실제 API 프로그래밍.

---

# Unity ShaderLab vs 실제 API 셰이더 코드 비교

## 1. Unity에서 쓰던 가장 단순한 Unlit Shader

```c
Shader "Custom/UnlitColor"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 pos : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return _Color;
            }
            ENDCG
        }
    }
}
```

* Unity는 `Properties`에서 머티리얼 변수 정의.
*  **정점 변환 행렬** 같은 걸 내부에서 제공.
* `vert`, `frag`만 있으면 바로 실행됨.

---

## 2. Direct3D 11에서 같은 효과 내기

Unity 내부에서 자동으로 해주던 부분을 **모두 직접 작성**해야 합니다.

### Vertex Shader (HLSL)

```hlsl
cbuffer ConstantBuffer : register(b0)
{
    matrix MVP;       // 모델-뷰-투영 행렬
    float4 Color;     // 머티리얼 색상
};

struct VS_INPUT
{
    float3 pos : POSITION;
};

struct PS_INPUT
{
    float4 pos : SV_POSITION;
};

PS_INPUT VSMain(VS_INPUT input)
{
    PS_INPUT output;
    output.pos = mul(float4(input.pos, 1.0f), MVP);
    return output;
}
```

### Pixel Shader (HLSL)

```hlsl
cbuffer ConstantBuffer : register(b0)
{
    matrix MVP;
    float4 Color;
};

float4 PSMain(PS_INPUT input) : SV_TARGET
{
    return Color; // Unity의 frag에서 _Color 반환한 것과 동일
}
```

---

### 그래픽스 API (Direct3D 11)

Unity의 `material.SetColor("_Color", ...)` 대신, 버퍼를 만들어 직접 바인딩해야 합니다.

```cpp
// Constant Buffer 구조체 (CPU 측)
struct ConstantBuffer
{
    DirectX::XMMATRIX MVP;
    DirectX::XMFLOAT4 Color;
};

// 버퍼 생성
D3D11_BUFFER_DESC cbDesc = {};
cbDesc.ByteWidth = sizeof(ConstantBuffer);
cbDesc.Usage = D3D11_USAGE_DEFAULT;
cbDesc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;

ID3D11Buffer* constantBuffer;
device->CreateBuffer(&cbDesc, nullptr, &constantBuffer);

// 매 프레임 업데이트
ConstantBuffer cb;
cb.MVP = XMMatrixTranspose(world * view * proj);
cb.Color = XMFLOAT4(1.0f, 0.0f, 0.0f, 1.0f); // 빨간색
context->UpdateSubresource(constantBuffer, 0, nullptr, &cb, 0, 0);

// 셰이더 및 버퍼 바인딩
context->VSSetShader(vertexShader, nullptr, 0);
context->PSSetShader(pixelShader, nullptr, 0);
context->VSSetConstantBuffers(0, 1, &constantBuffer);
context->PSSetConstantBuffers(0, 1, &constantBuffer);

// 드로우 콜
context->DrawIndexed(indexCount, 0, 0);
```

---

## 3. OpenGL에서 같은 효과

OpenGL은 GLSL 기반. Unity에서 `frag`랑 비슷하지만, API 호출도 직접 해야 함.

### Vertex Shader (GLSL)

```glsl
#version 330 core
layout(location = 0) in vec3 aPos;

uniform mat4 MVP;

void main()
{
    gl_Position = MVP * vec4(aPos, 1.0);
}
```

### Fragment Shader (GLSL)

```glsl
#version 330 core
out vec4 FragColor;
uniform vec4 Color;

void main()
{
    FragColor = Color;
}
```

### OpenGL 코드

```cpp
// Uniform 위치 가져오기
GLuint mvpLoc = glGetUniformLocation(shaderProgram, "MVP");
GLuint colorLoc = glGetUniformLocation(shaderProgram, "Color");

// 값 전달
glUniformMatrix4fv(mvpLoc, 1, GL_FALSE, glm::value_ptr(mvpMatrix));
glUniform4f(colorLoc, 1.0f, 0.0f, 0.0f, 1.0f); // 빨강

// 드로우
glUseProgram(shaderProgram);
glBindVertexArray(VAO);
glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_INT, 0);
```

---

## 4. 비교 요약

| 개념      | Unity                         | Direct3D/OpenGL 실제 코드                |
| ------- | ----------------------------- | ------------------------------------ |
| 셰이더 작성  | ShaderLab(.shader)            | HLSL(GLSL) 직접 작성                     |
| 머티리얼 변수 | `Properties { _Color }`       | Constant Buffer / Uniform            |
| 행렬 변환   | `UnityObjectToClipPos()` 제공   | `MVP` 행렬 직접 계산 및 전달                  |
| 셰이더 연결  | `#pragma vertex vert`         | `device->CreateVertexShader` + 파이프라인 |
| 값 전달    | `material.SetColor("_Color")` | `UpdateSubresource` / `glUniform`    |
| 실행      | Unity 렌더 파이프라인 자동 호출          | `Draw()` 직접 호출                       |

---

요약하면 Unity에서는
**"머티리얼 = 셰이더 + 변수"** 수준만 알면 되는데,
실제 API에서는
**"셰이더 코드 작성 + 버퍼/리소스 준비 + 파이프라인 연결 + Draw Call"**
까지 직접 해줘야 한다는 차이가 있습니다.

---
