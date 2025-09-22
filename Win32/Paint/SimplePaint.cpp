2. win api 예제
// SimplePaint.cpp
// Windows API를 사용하여 마우스로 그림을 그리는 예제 코드입니다.

#include <windows.h>
#include <windowsx.h> // GET_X_LPARAM, GET_Y_LPARAM 매크로를 위해 포함

// 전역 변수 선언
HINSTANCE hInst;
WCHAR szTitle[] = L"Simple Paint";           // 제목 표시줄 텍스트
WCHAR szWindowClass[] = L"MyPaintWindowClass"; // 창 클래스 이름

// 그리기 상태를 저장할 전역 변수
POINT ptPrevPos; // 이전 마우스 위치
COLORREF currentColor = RGB(0, 0, 0); // 현재 그리기 색상 (기본: 검정)

// 함수 선언
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);

int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPWSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    MyRegisterClass(hInstance);

    if (!InitInstance (hInstance, nCmdShow))
    {
        return FALSE;
    }

    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return (int) msg.wParam;
}

ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEXW wcex;
    wcex.cbSize = sizeof(WNDCLASSEX);
    wcex.style          = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc    = WndProc;
    wcex.cbClsExtra     = 0;
    wcex.cbWndExtra     = 0;
    wcex.hInstance      = hInstance;
    wcex.hIcon          = LoadIcon(nullptr, IDI_APPLICATION);
    wcex.hCursor        = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1);
    wcex.lpszMenuName   = nullptr;
    wcex.lpszClassName  = szWindowClass;
    wcex.hIconSm        = LoadIcon(wcex.hInstance, IDI_APPLICATION);
    return RegisterClassExW(&wcex);
}

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   hInst = hInstance;

   HWND hWnd = CreateWindowW(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, 800, 600, nullptr, nullptr, hInstance, nullptr);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}

// 주 창의 메시지를 처리하는 윈도우 프로시저
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_LBUTTONDOWN: // 마우스 왼쪽 버튼을 눌렀을 때
        {
            // 현재 마우스 위치를 이전 위치로 저장
            ptPrevPos.x = GET_X_LPARAM(lParam);
            ptPrevPos.y = GET_Y_LPARAM(lParam);
        }
        break;

    case WM_MOUSEMOVE: // 마우스가 움직일 때
        {
            // 마우스 왼쪽 버튼이 눌린 상태에서 움직이면
            if (wParam & MK_LBUTTON)
            {
                HDC hdc = GetDC(hWnd); // 윈도우의 DC를 얻음

                // 현재 색상으로 펜 생성
                HPEN hPen = CreatePen(PS_SOLID, 2, currentColor);
                HPEN hOldPen = (HPEN)SelectObject(hdc, hPen);

                // 이전 위치에서 현재 위치까지 선을 그림
                MoveToEx(hdc, ptPrevPos.x, ptPrevPos.y, NULL);
                LineTo(hdc, GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam));

                // 사용한 펜 정리
                SelectObject(hdc, hOldPen);
                DeleteObject(hPen);
                
                ReleaseDC(hWnd, hdc); // DC 해제

                // 현재 위치를 이전 위치로 갱신
                ptPrevPos.x = GET_X_LPARAM(lParam);
                ptPrevPos.y = GET_Y_LPARAM(lParam);
            }
        }
        break;

    case WM_RBUTTONDOWN: // 마우스 오른쪽 버튼을 눌렀을 때
        {
            // 화면을 강제로 다시 그리게 하여 깨끗하게 지움
            InvalidateRect(hWnd, NULL, TRUE);
        }
        break;

    case WM_KEYDOWN: // 키보드를 눌렀을 때
        {
            switch (wParam)
            {
            case 'R': // 'R' 키
                currentColor = RGB(255, 0, 0); // 빨간색
                break;
            case 'G': // 'G' 키
                currentColor = RGB(0, 255, 0); // 초록색
                break;
            case 'B': // 'B' 키
                currentColor = RGB(0, 0, 255); // 파란색
                break;
            }
        }
        break;
    
    case WM_PAINT: // 창을 다시 그려야 할 때
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hWnd, &ps);
            // TODO: 여기에 그리기 코드를 추가합니다.
            // 지금은 InvalidateRect 호출 시 배경색으로 지우는 역할만 합니다.
            EndPaint(hWnd, &ps);
        }
        break;

    case WM_DESTROY:
        PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

