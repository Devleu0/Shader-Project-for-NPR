1. win api 예제
// HelloWorldWindow.cpp
// Windows API를 사용하여 기본적인 윈도우를 생성하는 예제 코드입니다.

#include <windows.h>

// 전역 변수 선언
HINSTANCE hInst;                                // 현재 인스턴스
WCHAR szTitle[] = L"My First Window";           // 제목 표시줄 텍스트
WCHAR szWindowClass[] = L"MyWindowClass";      // 기본 창 클래스 이름

// 이 코드 모듈에 포함된 함수의 선언을 전달합니다.
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);

// 프로그램의 시작점 (Entry Point)
int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPWSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    // 1. 윈도우 클래스를 등록합니다.
    MyRegisterClass(hInstance);

    // 2. 애플리케이션 초기화를 수행합니다:
    if (!InitInstance (hInstance, nCmdShow))
    {
        return FALSE;
    }

    // 3. 기본 메시지 루프입니다.
    // 운영체제로부터 메시지를 받아 처리합니다.
    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        TranslateMessage(&msg); // 키보드 메시지를 변환
        DispatchMessage(&msg);  // 윈도우 프로시저로 메시지를 전달
    }

    return (int) msg.wParam;
}

//
//  함수: MyRegisterClass()
//
//  용도: 창 클래스를 등록합니다.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEXW wcex;

    wcex.cbSize = sizeof(WNDCLASSEX);

    wcex.style          = CS_HREDRAW | CS_VREDRAW; // 창 크기 변경 시 다시 그림
    wcex.lpfnWndProc    = WndProc; // 메시지를 처리할 함수(윈도우 프로시저) 지정
    wcex.cbClsExtra     = 0;
    wcex.cbWndExtra     = 0;
    wcex.hInstance      = hInstance; // 프로그램 인스턴스 핸들
    wcex.hIcon          = LoadIcon(nullptr, IDI_APPLICATION); // 기본 아이콘
    wcex.hCursor        = LoadCursor(nullptr, IDC_ARROW); // 기본 커서
    wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1); // 배경색
    wcex.lpszMenuName   = nullptr; // 메뉴 없음
    wcex.lpszClassName  = szWindowClass; // 이 클래스의 이름
    wcex.hIconSm        = LoadIcon(wcex.hInstance, IDI_APPLICATION); // 작은 아이콘

    return RegisterClassExW(&wcex); // 운영체제에 이 클래스를 등록
}

//
//   함수: InitInstance(HINSTANCE, int)
//
//   용도: 인스턴스 핸들을 저장하고 주 창을 만듭니다.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   hInst = hInstance; // 인스턴스 핸들을 전역 변수에 저장합니다.

   HWND hWnd = CreateWindowW(
       szWindowClass,       // 등록된 윈도우 클래스의 이름
       szTitle,             // 윈도우 제목
       WS_OVERLAPPEDWINDOW, // 윈도우 스타일
       CW_USEDEFAULT, 0,    // 윈도우의 시작 위치 (x, y)
       800, 600,            // 윈도우의 크기 (width, height)
       nullptr,             // 부모 윈도우 (없음)
       nullptr,             // 메뉴 (없음)
       hInstance,           // 프로그램 인스턴스
       nullptr);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow); // 윈도우를 화면에 보여줌
   UpdateWindow(hWnd); // 윈도우를 한 번 그리도록 함

   return TRUE;
}

//
//  함수: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  용도: 주 창의 메시지를 처리합니다.
//
//  WM_DESTROY  - 종료 메시지를 게시하고 반환합니다.
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    // 윈도우가 파괴될 때 (예: 우측 상단의 'X' 버튼 클릭)
    case WM_DESTROY:
        PostQuitMessage(0); // 메시지 루프를 종료하기 위해 WM_QUIT 메시지를 보냄
        break;
    default:
        // 처리하지 않은 메시지는 기본 처리 함수로 전달
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}
