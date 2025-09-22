// 리소스 스크립트
// Microsoft Visual C++에서 생성한 리소스 스크립트입니다.

#include "resource.h"

/////////////////////////////////////////////////////////////////////////////
//
// Menu
//

IDR_MENU MENU
BEGIN
    POPUP "&File"
    BEGIN
        MENUITEM "&Open\tCtrl+O",             IDM_FILE_OPEN
        MENUITEM "&Save\tCtrl+S",             IDM_FILE_SAVE
        MENUITEM SEPARATOR
        MENUITEM "E&xit",                     IDM_FILE_EXIT
    END
END
