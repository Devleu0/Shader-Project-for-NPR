# DirectX 11 1단계
기초 다지기
## 목표
이 학습 자료의 목표는 DirectX 11을 사용하여 렌더링을 하기 위한 가장 기본적인 환경을 구축하고, 렌더링 파이프라인의 흐름을 이해하여 화면에 첫 결과물(색상이 있는 삼각형)을 출력하는 것입니다. 이 과정을 통해 DirectX 11의 핵심 구성 요소들의 역할과 상호작용을 파악하게 됩니다.

## 1. 개발 환경 설정
DirectX 11 개발을 위해서는 Visual Studio와 Windows SDK가 필요합니다. 최신 Visual Studio에는 Windows SDK가 기본적으로 포함되어 있습니다.

Visual Studio 설치: Visual Studio 다운로드 페이지에서 Community 버전을 받아 설치합니다. 설치 시 'C++를 사용한 데스크톱 개발' 워크로드를 반드시 선택해야 합니다.

프로젝트 생성:

Visual Studio를 실행하고 '새 프로젝트 만들기'를 선택합니다.

'Windows 데스크톱 마법사' 또는 'Windows 데스크톱 애플리케이션' 템플릿을 선택합니다.

프로젝트 이름을 정하고 만들기를 누릅니다.

## 2. Win32 윈도우 생성
DirectX는 렌더링 결과를 출력할 '창(Window)'이 필요합니다. Win32 API를 사용하여 기본적인 윈도우를 생성합니다.

WinMain: 모든 Win32 애플리케이션의 시작점입니다.

WNDCLASSEX: 생성할 윈도우의 속성(스타일, 아이콘, 커서 등)을 정의하는 구조체입니다.

RegisterClassEx: 운영체제에 윈도우 클래스를 등록합니다.

CreateWindow: 등록된 클래스 정보를 바탕으로 실제 윈도우를 생성합니다.

메시지 루프: 운영체제로부터 발생하는 이벤트(키보드 입력, 마우스 움직임 등)를 처리하는 핵심 루프입니다. 이 루프가 활성화되어 있는 동안 프로그램이 실행됩니다.

아래는 기본적인 Win32 윈도우 코드의 구조입니다. 실제 전체 코드는 마지막 예제에서 확인하실 수 있습니다.
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

Back Buffer에 그리기가 완료되면, SwapChain이 두 버퍼를 '교체(Swap)'하여 화면 깜빡임(Tearing) 없이 부드러운 화면을 보여줍니다.

Render Target View (ID3D11RenderTargetView)

렌더링의 '목표'가 되는 리소스에 대한 뷰(View)입니다. 우리는 SwapChain의 Back Buffer를 렌더링 목표로 삼을 것이므로, Back Buffer에 대한 Render Target View를 생성해야 합니다.

Depth Stencil View (ID3D11DepthStencilView)

3D 공간에서 객체의 깊이(앞뒤 관계)를 처리하기 위한 버퍼(Depth Buffer)와, 특정 픽셀의 렌더링 여부를 결정하는 스텐실(Stencil) 버퍼에 대한 뷰입니다. 지금은 2D 삼각형 하나만 그리지만, 3D 렌더링의 기본 구조이므로 함께 생성합니다.

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

화면 지우기: ClearRenderTargetView 함수로 매 프레임 그리기를 시작하기 전에 이전 프레임의 내용을 특정 색(예: 파란색)으로 지웁니다. ClearDepthStencilView로 깊이 버퍼도 초기화합니다.

IA 단계 설정: Input Assembler(입력 조립기) 단계에 필요한 정보를 설정합니다.

IASetInputLayout: 생성한 입력 레이아웃 설정

IASetVertexBuffers: 사용할 정점 버퍼 설정

IASetPrimitiveTopology: 그릴 도형의 종류(예: 삼각형 목록) 설정

셰이더 설정: VSSetShader와 PSSetShader로 우리가 만든 Vertex/Pixel 셰이더를 파이프라인에 바인딩합니다.

그리기: Draw 함수를 호출하여 정점 버퍼에 있는 데이터로 실제 그리기를 GPU에 명령합니다. (정점 3개로 그리라고 명령)

화면 표시: m_pSwapChain->Present(1, 0)을 호출하여 Back Buffer의 내용을 Front Buffer로 교체하여 화면에 최종 결과를 보여줍니다.

이제 아래의 전체 코드를 프로젝트에 추가하고 실행해보세요. 화면에 알록달록한 삼각형이 나타날 것입니다!


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