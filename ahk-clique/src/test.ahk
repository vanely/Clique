;==============================================================================
; Simple Test Script for Desktop Automation Tool
; This script tests basic functionality without the full GUI
;==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; Set coordinate mode
CoordMode("Mouse", "Screen")
CoordMode("ToolTip", "Screen")

; Show welcome message
MsgBox(
    "Desktop Automation Tool - Test Script`n`n"
    . "This will test basic functionality:`n"
    . "1. Coordinate capture`n"
    . "2. Mouse clicking`n"
    . "3. Timers`n"
    . "4. Visual feedback`n`n"
    . "Press OK to begin",
    "Test Script",
    0
)

; Test 1: Coordinate Capture
ToolTip("TEST 1: Coordinate Capture`nMove your mouse and click anywhere", 10, 10)
Sleep(1000)

KeyWait("LButton", "D")
MouseGetPos(&testX, &testY)
ToolTip("✓ Captured: (" . testX . ", " . testY . ")", 10, 10)
Sleep(2000)

; Test 2: Mouse Click
ToolTip("TEST 2: Mouse Click`nWill click at captured location in 2 seconds...", 10, 10)
Sleep(2000)

Click(testX, testY)
ToolTip("✓ Click performed!", 10, 10)
Sleep(2000)

; Test 3: Visual Feedback
ToolTip("TEST 3: Visual Feedback`nShowing click indicator...", 10, 10)
Sleep(1000)

ShowClickIndicator(testX, testY)
Sleep(2000)

; Test 4: Multiple Clicks with Timer
ToolTip("TEST 4: Timed Clicks`nWill perform 3 clicks with 1s intervals...", 10, 10)
Sleep(2000)

global clickCount := 0
global maxClicks := 3

TimedClick() {
    global clickCount, maxClicks, testX, testY
    
    if (clickCount >= maxClicks) {
        SetTimer(TimedClick, 0)
        ToolTip("✓ All tests completed successfully!", 10, 10)
        SetTimer(() => ToolTip(), -3000)
        Sleep(3000)
        
        ; Final message
        MsgBox(
            "✅ ALL TESTS PASSED!`n`n"
            . "Your AutoHotkey installation is working correctly.`n`n"
            . "The automation tool should work perfectly!`n`n"
            . "Next: Run main.ahk to use the full tool.",
            "Success!",
            64
        )
        ExitApp()
        return
    }
    
    clickCount++
    Click(testX, testY)
    ShowClickIndicator(testX, testY)
    ToolTip("Click " . clickCount . "/" . maxClicks, 10, 10)
}

SetTimer(TimedClick, 1000)

; Helper function to show click indicator
ShowClickIndicator(x, y) {
    indicator := Gui("+AlwaysOnTop -Caption +ToolWindow")
    indicator.BackColor := "Yellow"
    WinSetTransparent(150, indicator)
    indicator.Show("x" . (x - 5) . " y" . (y - 5) . " w10 h10 NoActivate")
    
    SetTimer(() => indicator.Destroy(), -100)
}

; Keep script running
return
