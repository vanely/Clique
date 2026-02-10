;==============================================================================
; Automation Logic Module
; Handles coordinate capture and automated clicking
;==============================================================================

;==============================================================================
; Start Coordinate Capture Mode
;==============================================================================
StartCoordinateCapture() {
    if (AppState.isRunning) {
        MsgBox("Cannot capture while automation is running", "Error", 48)
        return
    }
    
    AppState.isCapturing := true
    UpdateStatus("Move mouse to target position and press LEFT CLICK")
    
    ; Show visual feedback
    ToolTip("Click anywhere to capture that coordinate", 10, 10)
    
    ; Wait for mouse click
    KeyWait("LButton", "D")
    
    ; Capture the position
    MouseGetPos(&x, &y)
    
    ; Update state and GUI
    AppState.targetX := x
    AppState.targetY := y
    xCoordEdit.Value := x
    yCoordEdit.Value := y
    
    AppState.isCapturing := false
    ToolTip()
    
    UpdateStatus("Coordinate captured: (" . x . ", " . y . ")", 3000)
    
    ; Flash the captured location
    FlashLocation(x, y)
}

;==============================================================================
; Flash Location Indicator
;==============================================================================
FlashLocation(x, y) {
    ; Create a temporary visual indicator
    indicator := Gui("+AlwaysOnTop -Caption +ToolWindow")
    indicator.BackColor := "Lime"
    WinSetTransparent(200, indicator)
    
    ; Show at target location
    indicator.Show("x" . (x - 10) . " y" . (y - 10) . " w20 h20 NoActivate")
    
    ; Flash 3 times
    Loop 3 {
        Sleep(200)
        indicator.Hide()
        Sleep(200)
        indicator.Show("NoActivate")
    }
    
    Sleep(500)
    indicator.Destroy()
}

;==============================================================================
; Start Automation
;==============================================================================
StartAutomation() {
    global intervalControls, modifierDropDown
    
    if (AppState.isRunning) {
        return
    }
    
    ; Validate coordinates
    if (AppState.targetX = 0 && AppState.targetY = 0) {
        MsgBox("Please set target coordinates first", "No Coordinates", 48)
        return
    }
    
    ; Get current values from GUI and validate
    intervalIndex := 1
    for control in intervalControls {
        try {
            if (control.Type = "Edit") {
                value := Number(control.Value)
                
                if (value < 100) {
                    MsgBox("Interval " . intervalIndex . " must be at least 100ms", "Invalid Intervals", 48)
                    return
                }
                
                AppState.intervals[intervalIndex] := value
                intervalIndex++
            }
        }
    }
    
    AppState.modifierKey := modifierDropDown.Text
    
    ; Update state
    AppState.isRunning := true
    AppState.currentIntervalIndex := 1
    UpdateGUIState(true)
    
    clickTypeText := AppState.clickType = "Right" ? "Right-clicking" : "Clicking"
    modifierText := AppState.modifierKey != "None" ? " with " . AppState.modifierKey : ""
    UpdateStatus("RUNNING - " . clickTypeText . modifierText . " with " . AppState.intervals.Length . " interval(s)")
    
    ; Start the automation sequence
    PerformClick()
}

;==============================================================================
; Stop Automation
;==============================================================================
StopAutomation() {
    if (!AppState.isRunning) {
        return
    }
    
    ; Stop the PerformClick timer
    SetTimer(PerformClick, 0)
    
    ; Update state
    AppState.isRunning := false
    AppState.currentIntervalIndex := 1
    UpdateGUIState(false)
    UpdateStatus("Stopped")
}

;==============================================================================
; Emergency Stop (ESC key)
;==============================================================================
EmergencyStop() {
    if (AppState.isRunning) {
        StopAutomation()
        ToolTip("EMERGENCY STOP ACTIVATED", 10, 10)
        SetTimer(() => ToolTip(), -2000)
    }
}

;==============================================================================
; Perform Click Action
;==============================================================================
PerformClick() {
    if (!AppState.isRunning) {
        return
    }
    
    ; Perform the click with modifier key
    PerformModifierClick(AppState.targetX, AppState.targetY, AppState.modifierKey, AppState.clickType)
    
    ; Show brief visual feedback
    ShowClickFeedback(AppState.targetX, AppState.targetY)
    
    ; Get current interval
    currentInterval := AppState.intervals[AppState.currentIntervalIndex]
    
    ; Update status
    UpdateStatus("RUNNING - Next click in " . currentInterval . "ms (Interval " . AppState.currentIntervalIndex . ")")
    
    ; Move to next interval (cycle through)
    AppState.currentIntervalIndex++
    if (AppState.currentIntervalIndex > AppState.intervals.Length) {
        AppState.currentIntervalIndex := 1
    }
    
    ; Schedule next click
    SetTimer(PerformClick, -currentInterval)
}

;==============================================================================
; Show Click Visual Feedback
;==============================================================================
ShowClickFeedback(x, y) {
    ; Create small pulse at click location
    pulse := Gui("+AlwaysOnTop -Caption +ToolWindow")
    pulse.BackColor := "Yellow"
    WinSetTransparent(150, pulse)
    pulse.Show("x" . (x - 5) . " y" . (y - 5) . " w10 h10 NoActivate")
    
    SetTimer(() => pulse.Destroy(), -100)
}

;==============================================================================
; Perform Click with Modifier Key
;==============================================================================
PerformModifierClick(x, y, modifier, clickType := "Left") {
    ; Determine click button
    clickButton := (clickType = "Right") ? "Right" : "Left"
    
    ; Press modifier key if specified
    switch modifier {
        case "Shift":
            Send("{LShift down}")
            Click(x, y, clickButton)
            Send("{LShift up}")
        case "Ctrl":
            SendPlay("{Ctrl down}")
            Click(x, y, clickButton)
            SendPlay("{Ctrl up}")
        case "Alt":
            SendPlay("{Alt down}")
            Click(x, y, clickButton)
            SendPlay("{Alt up}")
        default:  ; "None"
            Click(x, y, clickButton)
    }
}
