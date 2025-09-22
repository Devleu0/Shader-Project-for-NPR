// 4. FileSearcher.cpp
// 멀티스레딩을 이용한 파일 검색기 예제 코드입니다.

#include <windows.h>
#include <shlwapi.h> // PathFindFileNameW 사용
#include "resource.h"

#pragma comment(lib, "shlwapi.lib")

// 스레드에 전달할 데이터 구조체
struct ThreadArgs {
    HWND hDlg;
    WCHAR szPath[MAX_PATH];
    WCHAR szTerm[MAX_PATH];
};

// 함수 선언
INT_PTR CALLBACK DlgProc(HWND, UINT, WPARAM, LPARAM);
DWORD WINAPI SearchThread(LPVOID lpParam);
void SearchInDirectory(LPCWSTR szPath, LPCWSTR szTerm, HWND hDlg);
void SaveLastPath(LPCWSTR szPath);
void LoadLastPath(HWND hEdit);

// WinMain: 프로그램 시작점
int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPWSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
    // 모달리스 대화 상자를 메인 윈도우로 사용
    DialogBox(hInstance, MAKEINTRESOURCE(IDD_MAIN), NULL, DlgProc);
    return 0;
}

// 메인 대화 상자의 메시지 처리 프로시저
INT_PTR CALLBACK DlgProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_INITDIALOG:
        // 프로그램 시작 시 레지스트리에서 마지막 경로 불러오기
        LoadLastPath(GetDlgItem(hDlg, IDC_EDIT_PATH));
        return (INT_PTR)TRUE;

    case WM_COMMAND:
        if (LOWORD(wParam) == IDC_BUTTON_SEARCH)
        {
            // 리스트 박스 초기화
            SendDlgItemMessage(hDlg, IDC_LIST_RESULTS, LB_RESETCONTENT, 0, 0);

            // 스레드에 전달할 인자 설정
            ThreadArgs* args = new ThreadArgs;
            args->hDlg = hDlg;
            GetDlgItemText(hDlg, IDC_EDIT_PATH, args->szPath, MAX_PATH);
            GetDlgItemText(hDlg, IDC_EDIT_TERM, args->szTerm, MAX_PATH);

            // 작업자 스레드 생성
            HANDLE hThread = CreateThread(NULL, 0, SearchThread, args, 0, NULL);
            if (hThread)
            {
                CloseHandle(hThread); // 스레드 핸들은 바로 닫아도 됨
            }
            else
            {
                delete args; // 스레드 생성 실패 시 메모리 해제
            }
            return (INT_PTR)TRUE;
        }
        if (LOWORD(wParam) == IDCANCEL || LOWORD(wParam) == IDOK) // Enter/ESC 키 처리
        {
            // 프로그램 종료 전 마지막 경로 저장
            WCHAR szPath[MAX_PATH];
            GetDlgItemText(hDlg, IDC_EDIT_PATH, szPath, MAX_PATH);
            SaveLastPath(szPath);
            EndDialog(hDlg, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;

    case WM_APP + 1: // 작업자 스레드로부터 온 메시지 (파일 찾음)
        {
            LPCWSTR filePath = (LPCWSTR)lParam;
            SendDlgItemMessage(hDlg, IDC_LIST_RESULTS, LB_ADDSTRING, 0, (LPARAM)filePath);
            delete[] filePath; // 동적으로 할당된 메모리 해제
        }
        break;

    case WM_CLOSE: // 닫기 버튼
        {
            WCHAR szPath[MAX_PATH];
            GetDlgItemText(hDlg, IDC_EDIT_PATH, szPath, MAX_PATH);
            SaveLastPath(szPath);
            EndDialog(hDlg, 0);
        }
        return (INT_PTR)TRUE;
    }
    return (INT_PTR)FALSE;
}

// 작업자 스레드가 실행할 함수
DWORD WINAPI SearchThread(LPVOID lpParam)
{
    ThreadArgs* args = (ThreadArgs*)lpParam;
    SearchInDirectory(args->szPath, args->szTerm, args->hDlg);
    delete args; // 작업 완료 후 인자 메모리 해제
    return 0;
}

// 재귀적으로 디렉터리를 검색하는 함수
void SearchInDirectory(LPCWSTR szPath, LPCWSTR szTerm, HWND hDlg)
{
    WCHAR szSearchPath[MAX_PATH];
    wsprintf(szSearchPath, L"%s\\*", szPath);

    WIN32_FIND_DATA findData;
    HANDLE hFind = FindFirstFile(szSearchPath, &findData);

    if (hFind == INVALID_HANDLE_VALUE) return;

    do
    {
        if (wcscmp(findData.cFileName, L".") == 0 || wcscmp(findData.cFileName, L"..") == 0)
            continue;

        WCHAR szFullPath[MAX_PATH];
        wsprintf(szFullPath, L"%s\\%s", szPath, findData.cFileName);

        if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
        {
            SearchInDirectory(szFullPath, szTerm, hDlg); // 하위 디렉터리 재귀 호출
        }
        else
        {
            // 파일 내용에 검색어가 있는지 확인 (간단한 버전)
            HANDLE hFile = CreateFile(szFullPath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
            if (hFile != INVALID_HANDLE_VALUE)
            {
                DWORD dwFileSize = GetFileSize(hFile, NULL);
                if (dwFileSize > 0 && dwFileSize < 10000000) // 10MB 미만 파일만
                {
                    char* buffer = new char[dwFileSize + 1];
                    DWORD dwRead;
                    if (ReadFile(hFile, buffer, dwFileSize, &dwRead, NULL))
                    {
                        buffer[dwRead] = '\0';
                        // ANSI 문자열로 변환하여 검색
                        char szTermA[MAX_PATH];
                        WideCharToMultiByte(CP_ACP, 0, szTerm, -1, szTermA, MAX_PATH, NULL, NULL);
                        if (StrStrIA(buffer, szTermA))
                        {
                            // 찾았으면 메인 스레드에 메시지 전송
                            int len = wcslen(szFullPath) + 1;
                            WCHAR* foundPath = new WCHAR[len];
                            wcscpy_s(foundPath, len, szFullPath);
                            PostMessage(hDlg, WM_APP + 1, 0, (LPARAM)foundPath);
                        }
                    }
                    delete[] buffer;
                }
                CloseHandle(hFile);
            }
        }
    } while (FindNextFile(hFind, &findData));

    FindClose(hFind);
}

void SaveLastPath(LPCWSTR szPath)
{
    HKEY hKey;
    if (RegCreateKeyEx(HKEY_CURRENT_USER, L"Software\\MyFileSearcher", 0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS)
    {
        RegSetValueEx(hKey, L"LastPath", 0, REG_SZ, (const BYTE*)szPath, (wcslen(szPath) + 1) * sizeof(WCHAR));
        RegCloseKey(hKey);
    }
}

void LoadLastPath(HWND hEdit)
{
    HKEY hKey;
    if (RegOpenKeyEx(HKEY_CURRENT_USER, L"Software\\MyFileSearcher", 0, KEY_READ, &hKey) == ERROR_SUCCESS)
    {
        WCHAR szPath[MAX_PATH];
        DWORD dwSize = sizeof(szPath);
        if (RegQueryValueEx(hKey, L"LastPath", NULL, NULL, (LPBYTE)szPath, &dwSize) == ERROR_SUCCESS)
        {
            SetWindowText(hEdit, szPath);
        }
        RegCloseKey(hKey);
    }
}

