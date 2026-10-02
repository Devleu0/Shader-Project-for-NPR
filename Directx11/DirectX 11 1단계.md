# DirectX 11 1단계
기초 다지기

> **따라 하기 환경**: Windows 10/11 + Visual Studio 2022(C++를 사용한 데스크톱 개발) + Windows SDK. 이 문서 끝의 `main.cpp` **한 파일**을 새 프로젝트에 붙여 넣으면 삼각형이 뜹니다. 다만 작성자가 직접 빌드해 확인하지는 못했습니다. 오류가 나면 이슈로 알려 주세요. 다른 문서와 공통인 규약은 [실습 환경과 공통 규약](../Shader%20Learning/0.%20실습%20환경과%20공통%20규약.md)을 보세요.
## 목표
이 학습 자료의 목표는 DirectX 11을 사용하여 렌더링을 하기 위한 가장 기본적인 환경을 구축하고, 렌더링 파이프라인의 흐름을 이해하여 화면에 첫 결과물(색상이 있는 삼각형)을 출력하는 것입니다. 이 과정을 통해 DirectX 11의 핵심 구성 요소들의 역할과 상호작용을 파악하게 됩니다.

## 1. 개발 환경 설정
DirectX 11 개발을 위해서는 Visual Studio와 Windows SDK가 필요합니다. 최신 Visual Studio에는 Windows SDK가 기본적으로 포함되어 있습니다.

Visual Studio 설치: Visual Studio 다운로드 페이지에서 Community 버전을 받아 설치합니다. 설치 시 'C++를 사용한 데스크톱 개발' 워크로드를 반드시 선택해야 합니다.

프로젝트 생성:

Visual Studio를 실행하고 '새 프로젝트 만들기'를 선택합니다.

'Windows 데스크톱 애플리케이션' 템플릿을 선택하고(또는 '빈 프로젝트') 이름을 정해 만듭니다.

템플릿이 만든 `.cpp`/`.h`/`.rc` 파일은 프로젝트에서 **제거**하고(남겨 두면 `wWinMain` 이 중복됨), 아래 `main.cpp` 하나만 추가합니다. 빈 프로젝트를 골랐다면 속성 > 링커 > 시스템 > 하위 시스템을 `Windows` 로 지정하세요. 문자 집합은 기본값(유니코드)을 유지합니다.

## 2. Win32 윈도우 생성
DirectX는 렌더링 결과를 출력할 '창(Window)'이 필요합니다. Win32 API를 사용하여 기본적인 윈도우를 생성합니다.

WinMain: 모든 Win32 애플리케이션의 시작점입니다.

WNDCLASSEX: 생성할 윈도우의 속성(스타일, 아이콘, 커서 등)을 정의하는 구조체입니다.

RegisterClassEx: 운영체제에 윈도우 클래스를 등록합니다.

CreateWindow: 등록된 클래스 정보를 바탕으로 실제 윈도우를 생성합니다.

메시지 루프: 운영체제로부터 발생하는 이벤트(키보드 입력, 마우스 움직임 등)를 처리하는 핵심 루프입니다. 이 루프가 활성화되어 있는 동안 프로그램이 실행됩니다.

아래는 기본적인 Win32 윈도우 코드의 구조입니다. 실제 전체 코드는 문서 끝의 `main.cpp` 에서 확인하실 수 있습니다. (Win32 자체는 [Win32 학습 문서](../Win32/0.%20Win32%20학습%20커리큘럼.md) 참고. 이 문서의 `main.cpp` 는 Visual Studio 기본 템플릿과 같은 `wWinMain`(유니코드)을 씁니다.)
```c
// 윈도우 프로시저 - 윈도우 이벤트를 처리하는 함수
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    // ... 메시지 처리 ...
}

// WinMain - 프로그램 시작점
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    // 1. 윈도우 클래스 등록
    // 2. CreateWindow로 윈도우 생성
    // 3. 메시지 루프
    while(true) {
        // ...
    }
    return 0;
}
```
## 3. DirectX 11 초기화
이제 생성된 윈도우에 DirectX 11의 기능을 연결하는 과정입니다. 여러 핵심 컴포넌트들을 순서대로 생성하고 설정해야 합니다.

Device와 Device Context

Device (ID3D11Device): GPU와의 통신을 담당하는 가상 어댑터입니다. 버퍼, 텍스처와 같은 GPU 리소스를 생성하는 역할을 합니다. (자원 공장)

Device Context (ID3D11DeviceContext): 렌더링 명령을 GPU에 전달하는 역할을 합니다. 렌더링 상태를 설정하고, 그리기(Draw) 명령을 내립니다. (명령 전달자)

SwapChain (IDXGISwapChain)

렌더링된 이미지를 화면에 표시하는 역할을 담당합니다. 일반적으로 2개의 버퍼(Front Buffer, Back Buffer)를 사용합니다.

Back Buffer: 우리가 렌더링 명령을 통해 그림을 그리는 보이지 않는 버퍼입니다.

Front Buffer: 현재 화면에 보여지고 있는 버퍼입니다.

Back Buffer에 그리기가 완료되면, SwapChain이 두 버퍼를 '교체(Swap)'하여 그리는 도중의 화면이 보이지 않게 합니다. (모니터 주사 중에 교체되어 화면이 찢어져 보이는 티어링(tearing)은 수직 동기화(`Present(1, 0)` 의 첫 인자)로 줄입니다. 참고로 이 예제의 `BufferCount = 1` + `SWAPEFFECT_DISCARD` 는 가장 단순한 구형 방식이며, 최신 앱은 `FLIP_DISCARD` 와 버퍼 2개 이상을 씁니다.)

Render Target View (ID3D11RenderTargetView)

렌더링의 '목표'가 되는 리소스에 대한 뷰(View)입니다. 우리는 SwapChain의 Back Buffer를 렌더링 목표로 삼을 것이므로, Back Buffer에 대한 Render Target View를 생성해야 합니다.

Depth Stencil View (ID3D11DepthStencilView)

3D 공간에서 객체의 깊이(앞뒤 관계)를 처리하기 위한 버퍼(Depth Buffer)와, 특정 픽셀의 렌더링 여부를 결정하는 스텐실(Stencil) 버퍼에 대한 뷰입니다. 이 문서의 `main.cpp` 는 2D 삼각형 하나만 그리므로 깊이 버퍼를 만들지 않습니다. 3D 장면을 그리는 2단계부터 필요합니다.

Viewport 설정

렌더링될 화면의 영역을 지정합니다. 일반적으로 윈도우의 전체 클라이언트 영역으로 설정합니다.

이 모든 과정을 수행하는 코드는 마지막 예제 코드의 InitDevice() 함수 부분에서 자세히 확인할 수 있습니다.

## 4. 첫 렌더링: 삼각형 그리기
이제 화면에 무언가를 그릴 준비가 거의 끝났습니다. 삼각형을 그리기 위해 다음 3가지 요소를 준비해야 합니다.

정점 데이터와 버퍼 (Vertex Buffer)

삼각형을 구성하는 3개의 꼭짓점(Vertex) 데이터를 정의합니다. 각 꼭짓점은 위치(Position)와 색상(Color) 정보를 가집니다.

이 데이터를 GPU가 접근할 수 있는 메모리 공간인 Vertex Buffer에 복사합니다.

셰이더 (Shaders)

GPU에서 실행되는 작은 프로그램으로, 정점 데이터를 처리하고 픽셀의 최종 색상을 결정합니다.

Vertex Shader: 각 정점의 위치를 변환하는 역할을 합니다. 모델의 정점을 화면 좌표계로 변환합니다.

Pixel Shader: 각 픽셀의 색상을 계산하는 역할을 합니다. Vertex Shader에서 보간된 색상 값을 받아 최종 픽셀 색을 출력합니다.

셰이더는 HLSL(High-Level Shading Language)이라는 언어로 작성됩니다.

입력 레이아웃 (Input Layout)

Vertex Buffer에 있는 데이터 구조(예: 첫 12바이트는 위치, 다음 16바이트는 색상)가 Vertex Shader의 입력과 어떻게 일치하는지를 DirectX에 알려주는 '설명서' 역할을 합니다.

## 5. 렌더링 루프 (The Render Loop)
이제 모든 준비가 끝났습니다. WinMain의 메시지 루프 안에서 매 프레임마다 다음의 렌더링 작업을 반복합니다.

화면 지우기: ClearRenderTargetView 함수로 매 프레임 그리기를 시작하기 전에 이전 프레임의 내용을 특정 색(예: 파란색)으로 지웁니다. (깊이 버퍼를 쓰는 2단계부터는 ClearDepthStencilView로 깊이 버퍼도 초기화합니다.)

IA 단계 설정: Input Assembler(입력 조립기) 단계에 필요한 정보를 설정합니다.

IASetInputLayout: 생성한 입력 레이아웃 설정

IASetVertexBuffers: 사용할 정점 버퍼 설정

IASetPrimitiveTopology: 그릴 도형의 종류(예: 삼각형 목록) 설정

셰이더 설정: VSSetShader와 PSSetShader로 우리가 만든 Vertex/Pixel 셰이더를 파이프라인에 바인딩합니다.

그리기: Draw 함수를 호출하여 정점 버퍼에 있는 데이터로 실제 그리기를 GPU에 명령합니다. (정점 3개로 그리라고 명령)

화면 표시: g_swapChain->Present(1, 0)을 호출하여 Back Buffer의 내용을 Front Buffer로 교체하여 화면에 최종 결과를 보여줍니다.

이제 아래의 전체 코드를 프로젝트에 추가하고 실행해보세요. 파란 배경에 빨강/초록/파랑 꼭짓점이 보간된 알록달록한 삼각형이 나타나면 성공입니다.

**`main.cpp` (전체 코드, 위의 HLSL 셰이더를 문자열로 포함해 실행 중에 컴파일합니다)**
```cpp
// main.cpp : Direct3D 11 삼각형 (창 생성 + 장치 초기화 + 셰이더 + 렌더 루프)
// 빌드: Visual Studio 2022, 새 프로젝트 "Windows 데스크톱 애플리케이션"(또는 빈 프로젝트) 에 이 파일 하나만 추가.
//       프로젝트 속성 > 링커 > 시스템 > 하위 시스템 = Windows (또는 아래 wWinMain 이 진입점이 되도록 기본 설정 유지).
//       링크 라이브러리는 #pragma comment 로 지정했으므로 별도 설정이 필요 없다.

#include <windows.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <wrl/client.h>
#include <cstring>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "d3dcompiler.lib")

using Microsoft::WRL::ComPtr;

// ---------------- HLSL (실행 중에 컴파일한다. 별도 .hlsl 파일 필요 없음) ----------------
static const char* g_hlsl = R"(
struct VS_INPUT  { float4 Pos : POSITION; float4 Color : COLOR; };
struct PS_INPUT  { float4 Pos : SV_POSITION; float4 Color : COLOR; };

PS_INPUT VS(VS_INPUT input)
{
    PS_INPUT output = (PS_INPUT)0;
    output.Pos   = input.Pos;     // 이미 클립 공간(-1~1) 좌표이므로 그대로 전달
    output.Color = input.Color;
    return output;
}

float4 PS(PS_INPUT input) : SV_Target
{
    return input.Color;           // 정점에서 보간된 색
}
)";

struct Vertex { float x, y, z; float r, g, b, a; };

// ---------------- 전역 객체 ----------------
static const int kWidth = 800, kHeight = 600;
ComPtr<ID3D11Device>           g_device;
ComPtr<ID3D11DeviceContext>    g_context;
ComPtr<IDXGISwapChain>         g_swapChain;
ComPtr<ID3D11RenderTargetView> g_rtv;
ComPtr<ID3D11VertexShader>     g_vs;
ComPtr<ID3D11PixelShader>      g_ps;
ComPtr<ID3D11InputLayout>      g_layout;
ComPtr<ID3D11Buffer>           g_vb;

LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (msg == WM_DESTROY) { PostQuitMessage(0); return 0; }
    return DefWindowProc(hWnd, msg, wParam, lParam);
}

static bool Compile(const char* entry, const char* target, ComPtr<ID3DBlob>& blob)
{
    ComPtr<ID3DBlob> errors;
    HRESULT hr = D3DCompile(g_hlsl, std::strlen(g_hlsl), nullptr, nullptr, nullptr,
                            entry, target, D3DCOMPILE_ENABLE_STRICTNESS, 0, &blob, &errors);
    if (FAILED(hr))
    {
        if (errors) MessageBoxA(nullptr, (const char*)errors->GetBufferPointer(), "HLSL 컴파일 오류", MB_OK);
        return false;
    }
    return true;
}

bool InitDevice(HWND hWnd)
{
    // 1) 장치 + 스왑 체인
    DXGI_SWAP_CHAIN_DESC sd = {};
    sd.BufferCount = 1;
    sd.BufferDesc.Width = kWidth;
    sd.BufferDesc.Height = kHeight;
    sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = hWnd;
    sd.SampleDesc.Count = 1;
    sd.Windowed = TRUE;
    sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

    UINT flags = 0;
#ifdef _DEBUG
    flags |= D3D11_CREATE_DEVICE_DEBUG; // 디버그 레이어 (Windows 의 "그래픽 도구" 선택 기능이 설치되어 있어야 함. 실패하면 이 줄을 지운다)
#endif
    HRESULT hr = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags,
                                               nullptr, 0, D3D11_SDK_VERSION, &sd,
                                               &g_swapChain, &g_device, nullptr, &g_context);
    if (FAILED(hr)) return false;

    // 2) 백 버퍼에 대한 Render Target View
    ComPtr<ID3D11Texture2D> backBuffer;
    g_swapChain->GetBuffer(0, IID_PPV_ARGS(&backBuffer));
    g_device->CreateRenderTargetView(backBuffer.Get(), nullptr, &g_rtv);
    g_context->OMSetRenderTargets(1, g_rtv.GetAddressOf(), nullptr); // 깊이 버퍼는 2D 삼각형이라 사용하지 않음

    // 3) 뷰포트
    D3D11_VIEWPORT vp = { 0.0f, 0.0f, (float)kWidth, (float)kHeight, 0.0f, 1.0f };
    g_context->RSSetViewports(1, &vp);

    // 4) 셰이더 컴파일 + 생성
    ComPtr<ID3DBlob> vsBlob, psBlob;
    if (!Compile("VS", "vs_5_0", vsBlob) || !Compile("PS", "ps_5_0", psBlob)) return false;
    g_device->CreateVertexShader(vsBlob->GetBufferPointer(), vsBlob->GetBufferSize(), nullptr, &g_vs);
    g_device->CreatePixelShader(psBlob->GetBufferPointer(), psBlob->GetBufferSize(), nullptr, &g_ps);

    // 5) 입력 레이아웃: Vertex 구조체(위치 12바이트 + 색 16바이트)를 VS_INPUT 에 연결
    D3D11_INPUT_ELEMENT_DESC layout[] = {
        { "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT,    0,  0, D3D11_INPUT_PER_VERTEX_DATA, 0 },
        { "COLOR",    0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, 12, D3D11_INPUT_PER_VERTEX_DATA, 0 },
    };
    g_device->CreateInputLayout(layout, 2, vsBlob->GetBufferPointer(), vsBlob->GetBufferSize(), &g_layout);

    // 6) 정점 버퍼 (D3D11 기본 앞면은 시계 방향: 위 -> 오른쪽 아래 -> 왼쪽 아래)
    Vertex vertices[] = {
        {  0.0f,  0.5f, 0.0f, 1, 0, 0, 1 },
        {  0.5f, -0.5f, 0.0f, 0, 1, 0, 1 },
        { -0.5f, -0.5f, 0.0f, 0, 0, 1, 1 },
    };
    D3D11_BUFFER_DESC bd = {};
    bd.ByteWidth = sizeof(vertices);
    bd.Usage = D3D11_USAGE_DEFAULT;
    bd.BindFlags = D3D11_BIND_VERTEX_BUFFER;
    D3D11_SUBRESOURCE_DATA init = { vertices };
    g_device->CreateBuffer(&bd, &init, &g_vb);
    return true;
}

void Render()
{
    const float clearColor[4] = { 0.1f, 0.2f, 0.4f, 1.0f };
    g_context->ClearRenderTargetView(g_rtv.Get(), clearColor);

    UINT stride = sizeof(Vertex), offset = 0;
    g_context->IASetInputLayout(g_layout.Get());
    g_context->IASetVertexBuffers(0, 1, g_vb.GetAddressOf(), &stride, &offset);
    g_context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    g_context->VSSetShader(g_vs.Get(), nullptr, 0);
    g_context->PSSetShader(g_ps.Get(), nullptr, 0);
    g_context->Draw(3, 0);

    g_swapChain->Present(1, 0); // 1 = 수직 동기화(VSync) 사용
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, LPWSTR, int nCmdShow)
{
    // 윈도우 클래스 등록
    WNDCLASSEXW wc = { sizeof(WNDCLASSEXW) };
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.lpszClassName = L"D3D11TriangleClass";
    RegisterClassExW(&wc);

    // 클라이언트 영역이 800x600 이 되도록 창 크기 보정 (크기 조절은 지원하지 않는 단순 창)
    RECT rc = { 0, 0, kWidth, kHeight };
    DWORD style = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
    AdjustWindowRect(&rc, style, FALSE);
    HWND hWnd = CreateWindowW(wc.lpszClassName, L"D3D11 Triangle", style, CW_USEDEFAULT, CW_USEDEFAULT,
                              rc.right - rc.left, rc.bottom - rc.top, nullptr, nullptr, hInstance, nullptr);
    if (!hWnd) return -1;
    ShowWindow(hWnd, nCmdShow);

    if (!InitDevice(hWnd)) { MessageBoxW(hWnd, L"Direct3D 초기화 실패", L"오류", MB_OK); return -1; }

    // 메시지 루프 + 렌더 루프: 메시지가 없을 때마다 한 프레임을 그린다
    MSG msg = {};
    while (msg.message != WM_QUIT)
    {
        if (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) { TranslateMessage(&msg); DispatchMessage(&msg); }
        else Render();
    }
    return (int)msg.wParam;
}
```

**확인 사항**: 검은 화면만 나오면 ① 정점 순서가 시계 방향인지(반대로 하면 뒷면 컬링으로 사라짐), ② 입력 레이아웃의 시맨틱 이름이 셰이더와 같은지, ③ `Draw(3, 0)` 이전에 VS/PS 를 설정했는지 확인하세요. RenderDoc 으로 캡처해 보는 것이 가장 빠릅니다.

참고용 HLSL (위 `main.cpp` 에 이미 들어 있는 것과 같은 코드):


```hlsl
// HLSL (High-Level Shading Language) 코드

// 정점 셰이더의 입력과 픽셀 셰이더의 입력으로 사용될 구조체
struct VS_INPUT
{
    float4 Pos : POSITION;
    float4 Color : COLOR;
};

struct PS_INPUT
{
    float4 Pos : SV_POSITION;
    float4 Color : COLOR;
};

// 정점 셰이더
// 각 정점에 대해 실행되며, 정점의 위치를 변환하고
// 픽셀 셰이더로 넘겨줄 데이터를 설정합니다.
PS_INPUT VS(VS_INPUT input)
{
    PS_INPUT output = (PS_INPUT)0;
    output.Pos = input.Pos;   // 위치는 그대로 전달
    output.Color = input.Color; // 색상도 그대로 전달
    return output;
}

// 픽셀 셰이더
// 화면에 그려질 각 픽셀에 대해 실행되며,
// 최종 색상을 결정하여 반환합니다.
float4 PS(PS_INPUT input) : SV_Target
{
    return input.Color; // 정점에서 보간된 색상을 그대로 출력
}
```
