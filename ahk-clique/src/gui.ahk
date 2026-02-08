;==============================================================================
; GUI Components Module
; Handles all user interface elements
;==============================================================================

global MainGui := ""

;==============================================================================
; Create Main GUI Window
;==============================================================================
CreateMainGUI() {
    global MainGui := Gui("+AlwaysOnTop", "Hey! What are you doing?! 👀")
    MainGui.SetFont("s10", "Segoe UI")
    
    ; Coordinate Section
    MainGui.Add("GroupBox", "x10 y10 w380 h100", "Target Coordinate")
    MainGui.Add("Text", "x20 y35", "X Coordinate:")
    global xCoordEdit := MainGui.Add("Edit", "x120 y32 w80 Number", AppState.targetX)
    MainGui.Add("Text", "x220 y35", "Y Coordinate:")
    global yCoordEdit := MainGui.Add("Edit", "x320 y32 w60 Number", AppState.targetY)
    
    global captureBtn := MainGui.Add("Button", "x20 y65 w150", "Capture Coordinate (F3)")
    captureBtn.OnEvent("Click", (*) => StartCoordinateCapture())
    
    global testBtn := MainGui.Add("Button", "x180 y65 w100", "Test Click")
    testBtn.OnEvent("Click", (*) => TestClick())
    
    ; Intervals Section
    MainGui.Add("GroupBox", "x10 y120 w380 h150", "Click Settings")
    
    MainGui.Add("Text", "x20 y145", "Modifier Key:")
    global modifierDropDown := MainGui.Add("DropDownList", "x120 y142 w100", ["None", "Shift", "Ctrl", "Alt"])
    modifierDropDown.Text := AppState.modifierKey
    MainGui.Add("Text", "x230 y145 c888888", "(pressed with click)")
    
    MainGui.Add("Text", "x20 y175", "Interval 1:")
    global interval1Edit := MainGui.Add("Edit", "x120 y172 w100 Number", AppState.interval1)
    MainGui.Add("Text", "x230 y175", "ms")
    
    MainGui.Add("Text", "x20 y205", "Interval 2:")
    global interval2Edit := MainGui.Add("Edit", "x120 y202 w100 Number", AppState.interval2)
    MainGui.Add("Text", "x230 y205", "ms")
    
    MainGui.Add("Text", "x20 y235 c888888", "Pattern: Click → Wait Interval1 → Click → Wait Interval2 → Repeat")
    
    ; Control Buttons Section
    MainGui.Add("GroupBox", "x10 y280 w380 h100", "Controls")
    
    global startBtn := MainGui.Add("Button", "x20 y305 w110 h40", "Start (F1)")
    startBtn.OnEvent("Click", (*) => StartAutomation())
    
    global stopBtn := MainGui.Add("Button", "x140 y305 w110 h40 Disabled", "Stop (F2)")
    stopBtn.OnEvent("Click", (*) => StopAutomation())
    
    global emergencyBtn := MainGui.Add("Button", "x260 y305 w120 h40 cRed", "EMERGENCY (ESC)")
    emergencyBtn.OnEvent("Click", (*) => EmergencyStop())
    
    ; Status Section
    MainGui.Add("GroupBox", "x10 y390 w380 h80", "Status")
    global statusText := MainGui.Add("Text", "x20 y415 w360 h50", "Ready - Press F3 to capture a coordinate")
    
    ; Save button
    global saveBtn := MainGui.Add("Button", "x10 y480 w380 h35", "Save Settings")
    saveBtn.OnEvent("Click", (*) => SaveCurrentSettings())
    
    ; Handle window close
    MainGui.OnEvent("Close", (*) => ExitApp())
    
    ; Show the GUI
    MainGui.Show("w400 h530")
}

;==============================================================================
; Update Status Display
;==============================================================================
UpdateStatus(message, duration := 0) {
    global statusText
    statusText.Value := message
    
    if (duration > 0) {
        SetTimer(() => statusText.Value := "Ready", -duration)
    }
}

;==============================================================================
; Toggle GUI Controls Based on State
;==============================================================================
UpdateGUIState(running := false) {
    global startBtn, stopBtn, captureBtn, testBtn
    global xCoordEdit, yCoordEdit, interval1Edit, interval2Edit, modifierDropDown
    
    if (running) {
        startBtn.Enabled := false
        stopBtn.Enabled := true
        captureBtn.Enabled := false
        testBtn.Enabled := false
        xCoordEdit.Enabled := false
        yCoordEdit.Enabled := false
        interval1Edit.Enabled := false
        interval2Edit.Enabled := false
        modifierDropDown.Enabled := false
    } else {
        startBtn.Enabled := true
        stopBtn.Enabled := false
        captureBtn.Enabled := true
        testBtn.Enabled := true
        xCoordEdit.Enabled := true
        yCoordEdit.Enabled := true
        interval1Edit.Enabled := true
        interval2Edit.Enabled := true
        modifierDropDown.Enabled := true
    }
}

;==============================================================================
; Save Current Settings from GUI
;==============================================================================
SaveCurrentSettings() {
    global xCoordEdit, yCoordEdit, interval1Edit, interval2Edit, modifierDropDown
    
    ; Update state from GUI
    AppState.targetX := Number(xCoordEdit.Value)
    AppState.targetY := Number(yCoordEdit.Value)
    AppState.interval1 := Number(interval1Edit.Value)
    AppState.interval2 := Number(interval2Edit.Value)
    AppState.modifierKey := modifierDropDown.Text
    
    ; Validate intervals
    if (AppState.interval1 < 100) {
        MsgBox("Interval 1 must be at least 100ms", "Invalid Input", 48)
        return
    }
    if (AppState.interval2 < 100) {
        MsgBox("Interval 2 must be at least 100ms", "Invalid Input", 48)
        return
    }
    
    ; Save to file
    SaveSettings()
    UpdateStatus("Settings saved successfully!", 3000)
}

;==============================================================================
; Test Click Function
;==============================================================================
TestClick() {
    global xCoordEdit, yCoordEdit, modifierDropDown
    
    x := Number(xCoordEdit.Value)
    y := Number(yCoordEdit.Value)
    modifier := modifierDropDown.Text
    
    if (x = 0 && y = 0) {
        MsgBox("Please set coordinates first", "Invalid Coordinates", 48)
        return
    }
    
    modifierText := modifier != "None" ? " with " . modifier : ""
    UpdateStatus("Test clicking at (" . x . ", " . y . ")" . modifierText . "...", 3000)
    
    ; Save current position
    MouseGetPos(&currentX, &currentY)
    
    ; Perform test click with modifier
    PerformModifierClick(x, y, modifier)
    
    ; Return to original position
    MouseMove(currentX, currentY)
}

;==============================================================================
; Visual Feedback for Coordinate Capture
;==============================================================================
ShowCaptureOverlay() {
    global CaptureOverlay := Gui("+AlwaysOnTop -Caption +ToolWindow")
    CaptureOverlay.BackColor := "Red"
    WinSetTransparent(100, CaptureOverlay)
    
    ; Get screen dimensions
    MonitorGetWorkArea(, , , &screenWidth, &screenHeight)
    
    ; Show crosshair guides
    CaptureOverlay.Show("x0 y0 w" . screenWidth . " h2")
}

HideCaptureOverlay() {
    global CaptureOverlay
    if (IsSet(CaptureOverlay))
        CaptureOverlay.Destroy()
}
