//3. win api 예제 
// SimpleNotepad.cpp
// Windows API를 사용하여 간단한 메모장 기능을 구현하는 예제 코드입니다.

#include <windows.h>
#include <windowsx.h>
#include "resource.h" // 리소스 헤더 파일 포함

// 전역 변수 선언
HINSTANCE hInst;
WCHAR szTitle[] = L"Simple Notepad";
WCHAR szWindowClass[] = L"MyNotepadWindowClass";
HWND hEdit; // 에디트 컨트롤의 핸들을 저장할 전역 변수

// 함수 선언
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
void                DoFileOpen(HWND hWnd);
void                DoFileSave(HWND hWnd);

int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPWSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
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
    wcex.lpszMenuName   = MAKEINTRESOURCEW(IDR_MENU); // 리소스에서 메뉴를 로드
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

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_CREATE: // 윈도우가 처음 생성될 때
        {
            // 에디트 컨트롤 생성
            hEdit = CreateWindowEx(
                0, L"EDIT",   // 클래스 이름
                L"",          // 초기 텍스트
                WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_LEFT | ES_MULTILINE | ES_AUTOVSCROLL,
                0, 0, 0, 0,   // 크기와 위치는 WM_SIZE에서 조정
                hWnd,         // 부모 윈도우
                (HMENU)100,   // 컨트롤 ID
                hInst,
                NULL);
        }
        break;

    case WM_SIZE: // 윈도우 크기가 변경될 때
        {
            // 에디트 컨트롤의 크기를 클라이언트 영역에 꽉 차게 조절
            RECT rcClient;
            GetClientRect(hWnd, &rcClient);
            MoveWindow(hEdit, 0, 0, rcClient.right, rcClient.bottom, TRUE);
        }
        break;

    case WM_COMMAND: // 메뉴나 컨트롤로부터 메시지가 올 때
        {
            int wmId = LOWORD(wParam);
            // 메뉴 선택을 구문 분석합니다.
            switch (wmId)
            {
            case IDM_FILE_OPEN:
                DoFileOpen(hWnd);
                break;
            case IDM_FILE_SAVE:
                DoFileSave(hWnd);
                break;
            case IDM_FILE_EXIT:
                DestroyWindow(hWnd);
                break;
            default:
                return DefWindowProc(hWnd, message, wParam, lParam);
            }
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

void DoFileOpen(HWND hWnd)
{
    OPENFILENAME ofn;
    WCHAR szFile[260] = { 0 };

    ZeroMemory(&ofn, sizeof(ofn));
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = hWnd;
    ofn.lpstrFile = szFile;
    ofn.nMaxFile = sizeof(szFile);
    ofn.lpstrFilter = L"Text Files (*.txt)\0*.txt\0All Files (*.*)\0*.*\0";
    ofn.nFilterIndex = 1;
    ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;

    if (GetOpenFileName(&ofn) == TRUE)
    {
        HANDLE hFile = CreateFile(ofn.lpstrFile, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
        if (hFile != INVALID_HANDLE_VALUE)
        {
            DWORD dwFileSize = GetFileSize(hFile, NULL);
            if (dwFileSize != INVALID_FILE_SIZE)
            {
                char* pszText = new char[dwFileSize + 1];
                DWORD dwRead;
                if (ReadFile(hFile, pszText, dwFileSize, &dwRead, NULL))
                {
                    pszText[dwFileSize] = '\0';
                    SetWindowTextA(hEdit, pszText); // ANSI 버전 사용
                }
                delete[] pszText;
            }
            CloseHandle(hFile);
        }
    }
}

void DoFileSave(HWND hWnd)
{
    OPENFILENAME ofn;
    WCHAR szFile[260] = { 0 };

    ZeroMemory(&ofn, sizeof(ofn));
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = hWnd;
    ofn.lpstrFile = szFile;
    ofn.nMaxFile = sizeof(szFile);
    ofn.lpstrFilter = L"Text Files (*.txt)\0*.txt\0All Files (*.*)\0*.*\0";
    ofn.nFilterIndex = 1;
    ofn.Flags = OFN_OVERWRITEPrompt;

    if (GetSaveFileName(&ofn) == TRUE)
    {
        HANDLE hFile = CreateFile(ofn.lpstrFile, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
        if (hFile != INVALID_HANDLE_VALUE)
        {
            int nLength = GetWindowTextLength(hEdit);
            char* pszText = new char[nLength + 1];
            GetWindowTextA(hEdit, pszText, nLength + 1); // ANSI 버전 사용

            DWORD dwWritten;
            WriteFile(hFile, pszText, nLength, &dwWritten, NULL);
            delete[] pszText;
            CloseHandle(hFile);
        }
    }
}

