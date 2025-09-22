// 파일 검색기 리소스 스크립트
//Microsoft Visual C++에서 생성한 리소스 스크립트입니다.

#include "resource.h"

/////////////////////////////////////////////////////////////////////////////
//
// Dialog
//

IDD_MAIN DIALOGEX 0, 0, 345, 185
STYLE DS_SETFONT | DS_MODALFRAME | DS_FIXEDSYS | WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU
CAPTION "File Searcher"
FONT 9, "MS Shell Dlg", 400, 0, 0x1
BEGIN
    LTEXT           "Search Path:",IDC_STATIC,7,14,46,8
    EDITTEXT        IDC_EDIT_PATH,58,12,280,14,ES_AUTOHSCROLL
    LTEXT           "Containing Text:",IDC_STATIC,7,38,51,8
    EDITTEXT        IDC_EDIT_TERM,58,36,211,14,ES_AUTOHSCROLL
    PUSHBUTTON      "Search",IDC_BUTTON_SEARCH,280,35,58,16
    LISTBOX         IDC_LIST_RESULTS,7,58,331,120,LBS_NOINTEGRALHEIGHT | WS_VSCROLL | WS_TABSTOP
END

