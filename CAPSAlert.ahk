#Requires AutoHotkey v2.0
#SingleInstance Force

; GitHub: https://github.com/AJ-cubes/CAPSAlert

; Setup
SetWinDelay(-1)
CoordMode("Mouse", "Screen")

; Initialization
global size := 125
global circleGUI := ""
global pulse := 5
global maxTransparency := 255
global minTransparency := 0
global transparency := minTransparency
global color := "00FF00"
global circleOn := 1

; Temporary folder creation
tempDir := A_Temp "\CapsLockTray\"
DirCreate tempDir

; File install - make .ico files available in a standalone .exe after compiling using Ahk2Exe
FileInstall "CAPSAlert_favicon.ico", tempDir "CAPSAlert_favicon.ico", true
FileInstall "CAPSAlert_on+circle.ico", tempDir "CAPSAlert_on+circle.ico", true
FileInstall "CAPSAlert_on-circle.ico", tempDir "CAPSAlert_on-circle.ico", true
FileInstall "CAPSAlert_off+circle.ico", tempDir "CAPSAlert_off+circle.ico", true
FileInstall "CAPSAlert_off-circle.ico", tempDir "CAPSAlert_off-circle.ico", true

; Setting tray icon and tooltip at initialization
TraySetIcon tempDir "CAPSAlert_favicon.ico"
A_IconTip := A_ScriptName " - Checking"

; Add listener for double click on tray icon. If double click, toggle circleOn and return true to block default behaviour.
OnMessage(0x404, Received_AHK_NOTIFYICON)

Received_AHK_NOTIFYICON(wParam, lParam, msg, hwnd)
{
    global circleOn
    if lParam = 0x203
    {
        circleOn := !circleOn
        UpdateTray()
        capsLockMsg := circleOn ? "✅ The circle around the mouse pointer will show" : "❌ The circle around the mouse pointer won't show"
        MsgBox(capsLockMsg, capsLockMsg, "T1")
        return true
    }
}

; Updating the tray icons
UpdateTray()

; CapsLock keypress listener. ~ means let Windows continue with default behaviour. * means run even on any modifiers along with CapsLock. UpdateTray() is linking the button press to the function.
*CapsLock:: {
    Send "{Blind}{CapsLock}"
    UpdateTray()
}

; Update tray function
UpdateTray() {
    ; Set the tray icon and icon tooltip based on the new CapsLock and circle states.
    TraySetIcon tempDir (GetKeyState("CapsLock", "T") ? (circleOn ? "CAPSAlert_on+circle.ico" : "CAPSAlert_on-circle.ico") : (circleOn ? "CAPSAlert_off+circle.ico" : "CAPSAlert_off-circle.ico"))
    A_IconTip := A_ScriptName " - " (GetKeyState("CapsLock", "T") ? "ON" : "OFF")

    ; Show circle or hide circle based on CapsLock state and circleOn.
    if (circleOn) {
        GetKeyState("CapsLock", "T") ? ShowCircle() : HideCircle()
    }
}

; Show circle function
ShowCircle() {
    global circleGUI, size, transparency, pulse, minTransparency, color ; Make variables global

    ; Exit if GUI exists already.
    if (circleGUI) {
        return
    }

    ; Set the transparency and pulse.
    transparency := minTransparency
    pulse := 5

    ; Create the GUI. -Caption means no title or bar at the top of the window. +AlwaysOnTop means always keep the window on top. +ToolWindow prevents it from showing in Alt+Tab. +E0x20 adds the WS_EX_TRANSPARENT to let the user click or hover through the GUI. -DPIScale makes so that the GUI uses raw pixel coordinates from the screen rather than scaling with the DPI. Changes the back color and chooses where to show the GUI.
    circleGUI := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20 -DPIScale")
    circleGUI.BackColor := color
    circleGUI.Show("x0 y-" size " w" size " h" size " NA")

    ; Get the HWND, set transparency to the window, and change the shape to a circle.
    hwnd := circleGUI.Hwnd
    WinSetTransparent(transparency, "ahk_id " hwnd)
    WinSetRegion("0-0 w" size " h" size " E", "ahk_id " hwnd)

    ; Add a interval to update the GUI every 1 second.
    SetTimer(UpdateGUI, 1)
}

; Hide circle function
HideCircle() {
    global circleGUI

    ; Remove the timer for Update GUI
    SetTimer(UpdateGUI, 0)

    ; Check if the GUI exists. If it does, get its HWND and destroy the window using it. Make the variable a empty string, so that it's falsey.
    if (circleGUI) {
        hwnd := circleGUI.Hwnd
        DllCall("DestroyWindow", "ptr", hwnd)
        circleGUI := ""
    }
}

; Update GUI function
UpdateGUI() {
    global circleGUI, size, transparency, pulse, maxTransparency, minTransparency

    ; If CapsLock is not pressed or the GUI doesn't exist, exit the function.
    if (!GetKeyState("CapsLock", "T") || !circleGUI) {
        return
    }

    ; Transparency logic. Transparency adds by pulse. If transparency is more than the maximum transparency, the pulse becomes -5 so that it goes backwards. If it is less than the minimum transparency, the pulse becomes 5 so that it goes forwards.
    transparency += pulse
    if (transparency >= maxTransparency) {
        transparency := maxTransparency
        pulse := -5
    }
    if (transparency <= minTransparency) {
        transparency := minTransparency
        pulse := 5
    }

    ; Get the HWND and change the transparency to create a pulsing effect.
    hwnd := circleGUI.Hwnd
    WinSetTransparent(transparency, "ahk_id " hwnd)

    ; Get the mouse position and move the GUI to the mouse x minus half of size and mouse y minus half of size.
    MouseGetPos(&x, &y)
    x := x - size / 2
    y := y - size / 2
    circleGUI.Move(x, y)
}