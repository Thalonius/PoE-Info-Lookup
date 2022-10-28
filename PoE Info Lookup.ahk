#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Selection := ""
Loop, Files, %A_ScriptDir%\*.txt
{
    Selection := Selection SubStr(A_LoopFileName, 1, StrLen(A_LoopFileName)-4) "|"
    if A_Index = 1
        Selection := Selection "|"
}

Gui, +AlwaysonTop
Gui, Add, DropDownList, x12 y15 section vFileSelection gLoadSelectedFile, %Selection%
Gui, Add, Text, x+10 ys+3, Search
Gui, Add, Edit, x+10 ys+0 w185 vInputSearch gOK,
Gui, Add, ListView,grid x12 y47 h195 w350 -LV0x10 vDataLV gDataLV Sort -Multi List AltSubmit, Name|Description
Gui, Add, Edit, x+10 yp+0 h195 w250 +ReadOnly +Border vDataText

LoadSelectedFile()

Gui, Show, Hide
Menu, Tray, Add, Show (Ctrl+i), ShowGUI
Menu, Tray, Add, Exit, Exit
Hotkey, ^i, ShowGui
Return

ShowGui:
Gui, Show
Return

GuiClose:
Gui, Show, Hide
Return

Exit:
ExitApp

LoadSelectedFile:
LoadSelectedFile()
Gosub, OK
Return

LoadSelectedFile()
{
    global NameArr, DataArr, DataCount
    GuiControlGet, FileSelection, , FileSelection

    FileRead, Dataset, %FileSelection%.txt

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
    LoadLineText(1)
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

LoadLineText(1)
Gui, Show
Return

DataLV:
RowNo := LV_GetNext(0, "F")
LoadLineText(RowNo)
return

LoadLineText(RowNo)
{
    global
    if RowNo = 0
        Return
    if RowNo = 1
        ControlSend, DataLV, ^Home
    LV_GetText(DataTextLine, RowNo, 2)
    GuiControl, , DataText, %DataTextLine%
}