;==============================================================================
; GUI Components Module
; Handles all user interface elements
;==============================================================================

global MainGui := ""

;==============================================================================
; Create Main GUI Window
;==============================================================================
CreateMainGUI() {
    global MainGui := Gui("+AlwaysOnTop", "Hey! What are you doing Phil?! 👀")
    MainGui.SetFont("s10", "Segoe UI")
    
    ; Coordinate Section
    MainGui.Add("GroupBox", "x10 y10 w380 h130", "Target Coordinate")
    MainGui.Add("Text", "x20 y35", "X Coordinate:")
    global xCoordEdit := MainGui.Add("Edit", "x120 y32 w80 Number", AppState.targetX)
    MainGui.Add("Text", "x220 y35", "Y Coordinate:")
    global yCoordEdit := MainGui.Add("Edit", "x320 y32 w60 Number", AppState.targetY)
    
    ; Click Type Radio Buttons
    MainGui.Add("Text", "x20 y65", "Click Type:")
    global leftClickRadio := MainGui.Add("Radio", "x120 y62 Checked" . (AppState.clickType = "Left" ? "1" : "0"), "Left Click")
    global rightClickRadio := MainGui.Add("Radio", "x220 y62 Checked" . (AppState.clickType = "Right" ? "1" : "0"), "Right Click")
    leftClickRadio.OnEvent("Click", (*) => (AppState.clickType := "Left"))
    rightClickRadio.OnEvent("Click", (*) => (AppState.clickType := "Right"))
    
    global captureBtn := MainGui.Add("Button", "x20 y95 w150", "Capture Coordinate (F3)")
    captureBtn.OnEvent("Click", (*) => StartCoordinateCapture())
    
    global testBtn := MainGui.Add("Button", "x180 y95 w100", "Test Click")
    testBtn.OnEvent("Click", (*) => TestClick())
    
    ; Intervals Section
    MainGui.Add("GroupBox", "x10 y150 w380 h200", "Click Settings")
    
    MainGui.Add("Text", "x20 y175", "Modifier Key:")
    global modifierDropDown := MainGui.Add("DropDownList", "x120 y172 w100", ["None", "Shift", "Ctrl", "Alt"])
    modifierDropDown.Text := AppState.modifierKey
    MainGui.Add("Text", "x230 y175 c888888", "(pressed with click)")
    
    ; Intervals header with Add/Remove buttons
    MainGui.Add("Text", "x20 y205", "Intervals:")
    global addIntervalBtn := MainGui.Add("Button", "x120 y202 w60 h25", "+ Add")
    addIntervalBtn.OnEvent("Click", (*) => AddInterval())
    global removeIntervalBtn := MainGui.Add("Button", "x185 y202 w80 h25", "- Remove")
    removeIntervalBtn.OnEvent("Click", (*) => RemoveInterval())
    
    ; Container for dynamic interval fields (starts at y235)
    global intervalStartY := 235
    global intervalSpacing := 30
    
    ; Build initial interval fields
    RebuildIntervalControls()
    
    ; Pattern description
    global patternText := MainGui.Add("Text", "x20 y320 c888888 w350", "")
    UpdatePatternDescription()
    
    ; Control Buttons Section
    MainGui.Add("GroupBox", "x10 y360 w380 h100", "Controls")
    
    global startBtn := MainGui.Add("Button", "x20 y385 w110 h40", "Start (F1)")
    startBtn.OnEvent("Click", (*) => StartAutomation())
    
    global stopBtn := MainGui.Add("Button", "x140 y385 w110 h40 Disabled", "Stop (F2)")
    stopBtn.OnEvent("Click", (*) => StopAutomation())
    
    global emergencyBtn := MainGui.Add("Button", "x260 y385 w120 h40 cRed", "EMERGENCY (ESC)")
    emergencyBtn.OnEvent("Click", (*) => EmergencyStop())
    
    ; Status Section
    MainGui.Add("GroupBox", "x10 y470 w380 h80", "Status")
    global statusText := MainGui.Add("Text", "x20 y495 w360 h50", "Ready - Press F3 to capture a coordinate")
    
    ; Save button
    global saveBtn := MainGui.Add("Button", "x10 y560 w380 h35", "Save Settings")
    saveBtn.OnEvent("Click", (*) => SaveCurrentSettings())
    
    ; Handle window close
    MainGui.OnEvent("Close", (*) => ExitApp())
    
    ; Show the GUI
    MainGui.Show("w400 h610")
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
    global xCoordEdit, yCoordEdit, modifierDropDown
    global leftClickRadio, rightClickRadio
    global addIntervalBtn, removeIntervalBtn, intervalControls
    
    if (running) {
        startBtn.Enabled := false
        stopBtn.Enabled := true
        captureBtn.Enabled := false
        testBtn.Enabled := false
        xCoordEdit.Enabled := false
        yCoordEdit.Enabled := false
        modifierDropDown.Enabled := false
        leftClickRadio.Enabled := false
        rightClickRadio.Enabled := false
        addIntervalBtn.Enabled := false
        removeIntervalBtn.Enabled := false
        
        ; Disable all interval edit boxes
        for control in intervalControls {
            try {
                if (control.Type = "Edit") {
                    control.Enabled := false
                }
            }
        }
    } else {
        startBtn.Enabled := true
        stopBtn.Enabled := false
        captureBtn.Enabled := true
        testBtn.Enabled := true
        xCoordEdit.Enabled := true
        yCoordEdit.Enabled := true
        modifierDropDown.Enabled := true
        leftClickRadio.Enabled := true
        rightClickRadio.Enabled := true
        addIntervalBtn.Enabled := (AppState.intervals.Length < 3)
        removeIntervalBtn.Enabled := (AppState.intervals.Length > 1)
        
        ; Enable all interval edit boxes
        for control in intervalControls {
            try {
                if (control.Type = "Edit") {
                    control.Enabled := true
                }
            }
        }
    }
}

;==============================================================================
; Save Current Settings from GUI
;==============================================================================
SaveCurrentSettings() {
    global xCoordEdit, yCoordEdit, modifierDropDown
    global leftClickRadio, intervalControls
    
    ; Update state from GUI
    AppState.targetX := Number(xCoordEdit.Value)
    AppState.targetY := Number(yCoordEdit.Value)
    AppState.modifierKey := modifierDropDown.Text
    AppState.clickType := leftClickRadio.Value ? "Left" : "Right"
    
    ; Update intervals from edit controls
    intervalIndex := 1
    for control in intervalControls {
        try {
            if (control.Type = "Edit") {
                value := Number(control.Value)
                
                ; Validate interval
                if (value < 100) {
                    MsgBox("Interval " . intervalIndex . " must be at least 100ms", "Invalid Input", 48)
                    return
                }
                
                AppState.intervals[intervalIndex] := value
                intervalIndex++
            }
        }
    }
    
    ; Save to file
    SaveSettings()
    UpdateStatus("Settings saved successfully!", 3000)
}

;==============================================================================
; Test Click Function
;==============================================================================
TestClick() {
    global xCoordEdit, yCoordEdit, modifierDropDown, leftClickRadio
    
    x := Number(xCoordEdit.Value)
    y := Number(yCoordEdit.Value)
    modifier := modifierDropDown.Text
    clickType := leftClickRadio.Value ? "Left" : "Right"
    
    if (x = 0 && y = 0) {
        MsgBox("Please set coordinates first", "Invalid Coordinates", 48)
        return
    }
    
    modifierText := modifier != "None" ? " with " . modifier : ""
    UpdateStatus("Test " . clickType . " clicking at (" . x . ", " . y . ")" . modifierText . "...", 3000)
    
    ; Save current position
    MouseGetPos(&currentX, &currentY)
    
    ; Perform test click with modifier
    PerformModifierClick(x, y, modifier, clickType)
    
    ; Return to original position
    MouseMove(currentX, currentY)
}

;==============================================================================
; Add Interval
;==============================================================================
AddInterval() {
    if (AppState.intervals.Length >= 3) {
        MsgBox("Maximum of 3 intervals allowed", "Limit Reached", 48)
        return
    }
    
    ; Add new interval with default value
    AppState.intervals.Push(1000)
    
    ; Rebuild the controls
    RebuildIntervalControls()
    UpdatePatternDescription()
}

;==============================================================================
; Remove Interval
;==============================================================================
RemoveInterval() {
    if (AppState.intervals.Length <= 1) {
        MsgBox("Minimum of 1 interval required", "Cannot Remove", 48)
        return
    }
    
    ; Remove last interval
    AppState.intervals.Pop()
    
    ; Rebuild the controls
    RebuildIntervalControls()
    UpdatePatternDescription()
}

;==============================================================================
; Rebuild Interval Controls
;==============================================================================
RebuildIntervalControls() {
    global intervalControls, intervalStartY, intervalSpacing
    global addIntervalBtn, removeIntervalBtn, MainGui
    
    ; First pass: hide and delete all existing interval controls
    Loop intervalControls.Length {
        try {
            intervalControls[A_Index].Visible := false
        }
    }
    
    ; Second pass: destroy after hiding
    for control in intervalControls {
        try {
            control.Destroy()
        }
    }
    
    ; Clear the array
    intervalControls := []
    
    ; Small delay to ensure cleanup
    Sleep(10)
    
    ; Create new controls for each interval
    Loop AppState.intervals.Length {
        y := intervalStartY + ((A_Index - 1) * intervalSpacing)
        
        ; Label
        label := MainGui.Add("Text", "x20 y" . y, "Interval " . A_Index . ":")
        intervalControls.Push(label)
        
        ; Edit box
        edit := MainGui.Add("Edit", "x120 y" . (y - 3) . " w100 Number", AppState.intervals[A_Index])
        intervalControls.Push(edit)
        
        ; "ms" label
        msLabel := MainGui.Add("Text", "x230 y" . y, "ms")
        intervalControls.Push(msLabel)
    }
    
    ; Update button states
    addIntervalBtn.Enabled := (AppState.intervals.Length < 3)
    removeIntervalBtn.Enabled := (AppState.intervals.Length > 1)
    
    ; Force GUI to redraw
    MainGui.Show("NoActivate")
}

;==============================================================================
; Update Pattern Description
;==============================================================================
UpdatePatternDescription() {
    global patternText
    
    pattern := "Pattern: Click"
    
    Loop AppState.intervals.Length {
        pattern .= " → Wait Interval" . A_Index
        pattern .= " → Click"
    }
    
    pattern .= " → Repeat"
    patternText.Value := pattern
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
