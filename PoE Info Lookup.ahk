#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

GoSub, InitSettings

Selection := ""
Loop, Files, %A_ScriptDir%\Data\*.txt
{
    FileNameNoExt := SubStr(A_LoopFileName, 1, StrLen(A_LoopFileName)-4)
    Selection := Selection FileNameNoExt "|"
    if ((LastSelection = "") AND (A_Index = "1")) OR (FileNameNoExt = LastSelection)
        Selection := Selection "|"
}

if A_IsCompiled
    Menu, Tray, NoStandard
Menu, Tray, Icon, 
Menu, Tray, Add, Show (Ctrl+i), ShowGUI
Menu, Tray, Add, Open Config, OpenConfig
Menu, Tray, Add, Reload, Reload
Menu, Tray, Add, Exit, Exit
Menu, Tray, Default, Show (Ctrl+i)
Menu, Tray, Icon, wmploc.dll, 124
Hotkey, ^i, ShowGui

Gui, +AlwaysonTop +LastFound
Gui, Add, DropDownList, x12 y15 section vFileSelection gLoadSelectedFile, %Selection%
Gui, Add, Text, x+10 ys+3, Search
Gui, Add, Edit, x+10 ys+0 w185 vInputSearch gOK,
Gui, Add, ListView,grid x12 y47 h195 w350 -LV0x10 vDataLV gDataLV Sort List AltSubmit, Name|Description
Gui, Add, Edit, x+10 yp+0 h195 w250 +ReadOnly +Border vDataText

LoadSelectedFile()

GuiShowString :=
if SavePosition
    GuiShowString := GuiShowString " X" WinPosX " Y" WinPosY

if StartMinimized
{
    if MinimizeToTray
        GuiShowString := GuiShowString " Hide"
    Else
        GuiShowString := GuiShowString " Minimize"
}

if CloseToBubble
{
    Gui, 2:+AlwaysOnTop -Caption
    Gui, 2:Add, Picture, x0 y0 w64 h64 hwndIcon gRestoreFromBubble
    SetGuiStaticIcon(Icon, "wmploc.dll", 124, 64)
    Gui, 2:Show, % "Hide X" WinPosX " Y" WinPosY " w64 h64", PoE Info Lookup Bubble1
    WinSet, Region, 0-4 w58 h58 R58-58, PoE Info Lookup Bubble
}

if StartClosed & !StartMinimized
{
    Gui, 1:Show, % "hide " GuiShowString
    GoSub, CloseMainWindow
}
Else
    Gui, Show, %GuiShowString%

if MinimizeToTray
{
    SC_Minimize := 61472
    OnMessage(0x112, "WM_SYSCOMMAND")   ;MinToTray
}
Return

InitSettings:
IniRead, MinimizeToTray, %A_ScriptDir%\config.ini, General, Minimize to tray, Not initialized
if (MinimizeToTray = "Not initialized")
{
    IniWrite, % False, %A_ScriptDir%\config.ini, General, Minimize to tray
    MinimizeToTray := False
}

IniRead, StartMinimized, %A_ScriptDir%\config.ini, General, Start minimized, Not initialized
if (StartMinimized = "Not initialized")
{
    IniWrite, % False, %A_ScriptDir%\config.ini, General, Start minimized
    StartMinimized := False
}

IniRead, StartClosed, %A_ScriptDir%\config.ini, General, Start closed, Not initialized
if (StartClosed = "Not initialized")
{
    IniWrite, % False, %A_ScriptDir%\config.ini, General, Start closed
    StartClosed := False
}

IniRead, CloseToBubble, %A_ScriptDir%\config.ini, General, Close to bubble, Not initialized
if (CloseToBubble = "Not initialized")
{
    IniWrite, % False, %A_ScriptDir%\config.ini, General, Close to bubble
    CloseToBubble := False
}

IniRead, CloseToTray, %A_ScriptDir%\config.ini, General, Close to tray, Not initialized
if (CloseToTray = "Not initialized")
{
    IniWrite, % False, %A_ScriptDir%\config.ini, General, Close to tray
    CloseToTray := False
}

IniRead, SavePosition, %A_ScriptDir%\config.ini, General, Save position, Not initialized
if (SavePosition = "Not initialized")
{
    IniWrite, % True, %A_ScriptDir%\config.ini, General, Save position
    SavePosition := True
}

if SavePosition
{
    IniRead, WinPosX, %A_ScriptDir%\config.ini, Session, XPos, 10
    IniRead, WinPosY, %A_ScriptDir%\config.ini, Session, YPos, 10
}

IniRead, LastSelection, %A_ScriptDir%\config.ini, Session, Last selection, %Empty%
Return

Reload:
Reload

2GuiClose:
Gui, 2:Hide
Gosub, ShowGui
Return

RestoreFromBubble:
if A_GuiEvent = DoubleClick
{
    Gui, 2:Hide
    Gosub, ShowGui
}
Return

ShowGui:
Gui, 1:-E0x80 +AlwaysOnTop
Gui, 1:Show
Return

GuiClose:
WinGetPos, NewWinPosX, NewWinPosY, , , A
if SavePosition
{
    if (NewWinPosX <> WinPosX)
        IniWrite, %NewWinPosX%, %A_ScriptDir%\config.ini, Session, XPos
    if (NewWinPosY <> WinPosY)
        IniWrite, %NewWinPosY%, %A_ScriptDir%\config.ini, Session, YPos
}
if (NewWinPosX <> WinPosX)
    WinPosX := NewWinPosX
if (NewWinPosY <> WinPosY)
    WinPosY := NewWinPosY
GoSub, CloseMainWindow
Return

CloseMainWindow:
if CloseToBubble
{
    Gui, 1:Show, Hide
    Gui, 2:Show, % "X" WinPosX " Y" WinPosY
    WinSet, Region, 0-4 w58 h58 R58-58, PoE Info Lookup Bubble
}
Else IF CloseToTray
    Gui, 1:Show, Hide
Else
    ExitApp
Return

Exit:
ExitApp

OpenConfig:
Run %A_ScriptDir%\config.ini
Return

LoadSelectedFile:
LoadSelectedFile()
Gosub, OK
Return

LoadSelectedFile()
{
    global NameArr, DataArr, DataCount
    GuiControlGet, FileSelection, , FileSelection
    IniWrite, %FileSelection%, %A_ScriptDir%\config.ini, Session, Last selection

    FileRead, Dataset, %A_ScriptDir%\Data\%FileSelection%.txt

    NameArr := []
    DataArr := []
    i := 0
    for index,mod in StrSplit(Dataset, ["[","]"], " `r`n")
    {
        if index > 1
        {
            if Mod(index,2) = 0
                Name := mod
            Else
            {
                i += 1
                NameArr[i] := Name
                DataArr[i] := mod
            }
        }
    }
    DataCount := i

    i := 0
    while i < DataCount
    {
        i += 1
        LV_Add("", NameArr[i], DataArr[i])
    }
    GuiControl, , DataText, % LoadLineText(1)
}

OK:
Gui, Submit, NoHide
Gui, 1:Default
Gui, Listview, DataLV

LV_Delete()
/*
; Searches only in Name:
For index,Mod in NameArr
{
    If InStr(Mod, InputSearch)
        LV_Add("", NameArr[index], DataArr[index])
}
*/

; Searches Name and Description
i := 0
while i < DataCount
{
    i += 1
        
    If InStr(NameArr[i], InputSearch)
        LV_Add("", NameArr[i], DataArr[i])
    Else IF InStr(DataArr[i], InputSearch)
        LV_Add("", NameArr[i], DataArr[i])
}

GuiControl, , DataText, % LoadLineText(1)
Gui, 1:Show
Return

DataLV:
if (A_GuiEvent = "I")
{
    Result =
    GuiControl, , DataText, 
    LoadHeaders := LV_GetCount("S") > 1
    RowNo := LV_GetNext(0)
    While(RowNo > 0)
    {
        Result := Result LoadLineText(RowNo,LoadHeaders)
        RowNo := LV_GetNext(RowNo)
    }
    GuiControl, , DataText, %Result%
}
return

LoadLineText(RowNo,WithHeader=0)
{
    global
    if RowNo = 0
        Return
    if RowNo = 1
        ControlSend, DataLV, ^Home
    LV_GetText(DataTextLine, RowNo, 2)
    if WithHeader
    {
        LV_GetText(DataTextHeader, RowNo, 1)
        Return "---" DataTextHeader "---`n" DataTextLine "`n`n"
    }
    Return DataTextLine
}

WM_SYSCOMMAND(wParam)
{
    global SC_Minimize

    If (wParam = SC_Minimize)
    {
        Gui, 1:+E0x80 -AlwaysOnTop
        Gui, 1:Hide
    }
}



SetGuiStaticIcon(ControlHwnd, Filename, IconNumber := 1, IconSize := 0) {
   If !DllCall("PrivateExtractIcons", "Str", Filename, "Int", IconNumber - 1, "Int", IconSize, "Int", IconSize
                                    , "PtrP", hIcon, "UIntP", 0, "UInt", 1, "UInt", 0, "UInt")
      Return False
   If !(hBitmap := GetBitmapFromIcon32Bit(hIcon, IconSize, IconSize))
      Return False
   ; Destroy unneeded icon.
   DllCall("DestroyIcon", "Ptr", hIcon)
   ; Convert the Static control to SS_BITMAP (might be unnecessary).
   WinGet Style, Style, ahk_id %ControlHwnd%
   Style := (Style & ~0x1F) | 0xE  ; SS_BITMAP = 0xE, SS_TYPEMASK = 0x1F
   WinSet Style, %Style%, ahk_id %ControlHwnd%
   ; Set the control's bitmap.
   SendMessage % 0x172, 0, %hBitmap%, , ahk_id %ControlHwnd%  ; STM_SETIMAGE = 0x172, IMAGE_BITMAP = 0
   If (ErrorLevel <> 0)
      DllCall("DeleteObject", "Ptr", ErrorLevel)
   Return True
}
; ==================================================================================================================================
; Originally released by lexikos -> http://www.autohotkey.com/board/topic/20253-menu-icons-v2/
; Note: 32-bit alpha-blended menu item bitmaps are supported only on Windows Vista.
; Article on menu icons in Vista:
; http://shellrevealed.com/blogs/shellblog/archive/2007/02/06/Vista-Style-Menus_2C00_-Part-1-_2D00_-Adding-icons-to-standard-menus.aspx
GetBitmapFromIcon32Bit(hIcon, Width := 0, Height := 0) {
   VarSetCapacity(Buf, 40, 0) ; used as ICONINFO, BITMAP, BITMAPINFO
   If DllCall("GetIconInfo", "Ptr", hIcon, "Ptr",&Buf) {
      hbmColor := NumGet(Buf, A_PtrSize = 8 ? 24 : 16, "UPtr")  ; used to measure the icon
      hbmMask  := NumGet(Buf, A_PtrSize = 8 ? 16 : 12, "UPtr")  ; used to generate alpha data (If necessary)
   }
   If !(Width && Height) {
      If !hbmColor or !DllCall("GetObject", "Ptr", hbmColor, "Int", A_PtrSize = 8 ? 32 : 24, "Ptr", &Buf)
         Return 0
      Width := NumGet(Buf, 4, "Int")
      , Height := NumGet(Buf, 8, "Int")
      MsgBox, %Width% - %Height%
   }
   ; Create a device context compatible with the screen.
   If (hdcDest := DllCall("CreateCompatibleDC", "Ptr", 0)) {
      ; Create a 32-bit bitmap to draw the icon onto.
      VarSetCapacity(Buf, 48, 0) ; BITMAPINFO
      , NumPut(40, Buf, "UInt")
      , NumPut(Width, Buf, 4, "Int")
      , NumPut(Height, Buf, 8, "Int")
      , NumPut(1, Buf, 12, "UShort")
      , NumPut(32, Buf, 14,"UShort")
      If (hBm := DllCall("CreateDIBSection", "Ptr", hdcDest, "Ptr", &Buf, "UInt", 0, "PtrP", pBits, "UInt", 0, "UInt", 0, "UPtr")) {
         ; SelectObject -- use hdcDest to draw onto hBm
         If (hBmOld := DllCall("SelectObject", "Ptr", hdcDest, "Ptr", hBm, "UPtr")) {
            ; Draw the icon onto the 32-bit bitmap.
            DllCall("DrawIconEx", "Ptr", hdcDest, "Int", 0, "Int", 0, "Ptr", hIcon, "UInt", Width, "UInt", Height
                                , "UInt", 0, "Ptr", 0, "UInt", 3)
            DllCall("SelectObject", "Ptr", hdcDest, "Ptr", hBmOld)
         }
         ; Check for alpha data.
         HasAlphaData := False
         Loop, % (Height * Width)
            If NumGet(pBits + 0, (A_Index - 1) * 4, "UInt") & 0xFF000000 {
               HasAlphaData := True
               Break
            }
         If !(HasAlphaData) {
            ; Ensure the mask is the right size.
            hbmMask := DllCall("CopyImage", "Ptr", hbmMask, "uint", 0, "Int", Width, "Int", Height, "UInt", 4 | 8, "UPtr")
            VarSetCapacity(MaskBits, Width * Height * 4, 0)
            If DllCall("GetDIBits", "Ptr", hdcDest, "Ptr", hbmMask, "UInt", 0, "UInt", Height
                                  , "Ptr", &MaskBits, "Ptr", &Buf, "UInt", 0) {
               ; Use icon mask to generate alpha data.
               Loop, % (Height * Width) {
                  Offset := (A_Index - 1) * 4
                  If NumGet(MaskBits, Offset, "UInt")
                     NumPut(0, pBits + Offset, "UInt")
                  Else
                     NumPut(NumGet(pBits + Offset, "UInt") | 0xFF000000, pBits + Offset, "UInt")
               }
            }
            Else { ; Make the bitmap entirely opaque.
               Loop, % (Height * Width)
                  Offset := (A_Index - 1) * 4
                  , NumPut(NumGet(pBits + Offset, "UInt") | 0xFF000000, pBits + Offset, "UInt")
            }
         }
      }
      ; Done using the device context.
      DllCall("DeleteDC", "Ptr", hdcDest)
   }
   If hbmColor
     DllCall("DeleteObject", "Ptr", hbmColor)
   If hbmMask
     DllCall("DeleteObject", "Ptr", hbmMask)
   Return hBm
}