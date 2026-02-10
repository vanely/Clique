;==============================================================================
; GUI Components Module
; Handles all user interface elements with tab-based click steps
;==============================================================================

global MainGui := ""
global currentTabIndex := 1

;==============================================================================
; Create Main GUI Window
;==============================================================================
CreateMainGUI() {
    global MainGui := Gui("+AlwaysOnTop", "Hey! What are you doing Phil?! 👀")
    MainGui.SetFont("s10", "Segoe UI")
    
    ; Click Steps Management Section
    MainGui.Add("GroupBox", "x10 y10 w780 h50", "Click Steps")
    MainGui.Add("Text", "x20 y30", "Manage Steps:")
    global addStepBtn := MainGui.Add("Button", "x120 y27 w100 h25", "+ Add Step")
    addStepBtn.OnEvent("Click", (*) => AddClickStep())
    global removeStepBtn := MainGui.Add("Button", "x230 y27 w100 h25", "- Remove Step")
    removeStepBtn.OnEvent("Click", (*) => RemoveClickStep())
    
    ; Tab Control for Click Steps
    global stepTabControl := MainGui.Add("Tab3", "x10 y70 w780 h520", [])
    
    ; Initialize tabs
    RebuildStepTabs()
    
    ; Control Buttons Section
    MainGui.Add("GroupBox", "x10 y600 w780 h100", "Controls")
    
    global startBtn := MainGui.Add("Button", "x20 y625 w150 h40", "Start Sequence (F1)")
    startBtn.OnEvent("Click", (*) => StartAutomation())
    
    global stopBtn := MainGui.Add("Button", "x180 y625 w150 h40 Disabled", "Stop (F2)")
    stopBtn.OnEvent("Click", (*) => StopAutomation())
    
    global emergencyBtn := MainGui.Add("Button", "x340 y625 w150 h40 cRed", "EMERGENCY (ESC)")
    emergencyBtn.OnEvent("Click", (*) => EmergencyStop())
    
    ; Save button
    global saveBtn := MainGui.Add("Button", "x500 y625 w280 h40", "Save All Settings")
    saveBtn.OnEvent("Click", (*) => SaveCurrentSettings())
    
    ; Status Section
    MainGui.Add("GroupBox", "x10 y710 w780 h80", "Status")
    global statusText := MainGui.Add("Text", "x20 y735 w760 h50", "Ready - Configure click steps and press F1 to start")
    
    ; Handle window close
    MainGui.OnEvent("Close", (*) => ExitApp())
    
    ; Show the GUI
    MainGui.Show("w800 h800")
    
    ; Force a redraw to ensure all tab controls are visible
    Sleep(50)
    MainGui.Show("NoActivate")
}

;==============================================================================
; Add Click Step
;==============================================================================
AddClickStep() {
    if (AppState.clickSteps.Length >= 10) {
        MsgBox("Maximum of 10 click steps allowed", "Limit Reached", 48)
        return
    }
    
    ; Save current values before rebuilding
    SaveAllStepValues()
    
    ; Add new step with default values
    AppState.clickSteps.Push({
        targetX: 0,
        targetY: 0,
        clickType: "Left",
        modifierKey: "None",
        intervals: [1000]
    })
    
    ; Rebuild tabs
    RebuildStepTabs()
    
    ; Switch to new tab
    stepTabControl.Value := AppState.clickSteps.Length
}

;==============================================================================
; Remove Click Step
;==============================================================================
RemoveClickStep() {
    if (AppState.clickSteps.Length <= 1) {
        MsgBox("Minimum of 1 click step required", "Cannot Remove", 48)
        return
    }
    
    ; Save current values before rebuilding
    SaveAllStepValues()
    
    ; Remove last step
    AppState.clickSteps.Pop()
    
    ; Rebuild tabs
    RebuildStepTabs()
}

;==============================================================================
; Rebuild Step Tabs
;==============================================================================
RebuildStepTabs() {
    global stepTabControl, stepControls, currentTabIndex
    
    ; Save which tab was active (with safer fallback)
    if (IsSet(stepTabControl)) {
        try {
            currentTabIndex := stepTabControl.Value
        } catch {
            currentTabIndex := 1
        }
    } else {
        currentTabIndex := 1
    }
    
    ; Destroy existing step controls carefully
    for stepCtrl in stepControls {
        if (IsObject(stepCtrl)) {
            ; Destroy known control properties individually
            try {
                if (IsObject(stepCtrl.xCoordEdit)) {
                    stepCtrl.xCoordEdit.Destroy()
                }
            }
            try {
                if (IsObject(stepCtrl.yCoordEdit)) {
                    stepCtrl.yCoordEdit.Destroy()
                }
            }
            try {
                if (IsObject(stepCtrl.leftClickRadio)) {
                    stepCtrl.leftClickRadio.Destroy()
                }
            }
            try {
                if (IsObject(stepCtrl.rightClickRadio)) {
                    stepCtrl.rightClickRadio.Destroy()
                }
            }
            try {
                if (IsObject(stepCtrl.captureBtn)) {
                    stepCtrl.captureBtn.Destroy()
                }
            }
            try {
                if (IsObject(stepCtrl.testBtn)) {
                    stepCtrl.testBtn.Destroy()
                }
            }
            try {
                if (IsObject(stepCtrl.modifierDropDown)) {
                    stepCtrl.modifierDropDown.Destroy()
                }
            }
            try {
                if (IsObject(stepCtrl.addIntervalBtn)) {
                    stepCtrl.addIntervalBtn.Destroy()
                }
            }
            try {
                if (IsObject(stepCtrl.removeIntervalBtn)) {
                    stepCtrl.removeIntervalBtn.Destroy()
                }
            }
            try {
                if (IsObject(stepCtrl.patternText)) {
                    stepCtrl.patternText.Destroy()
                }
            }
            
            ; Handle interval controls array separately
            try {
                if (IsObject(stepCtrl.intervalControls)) {
                    for intervalCtrl in stepCtrl.intervalControls {
                        try intervalCtrl.Destroy()
                    }
                }
            }
        }
    }
    stepControls := []
    
    ; Build tab names
    tabNames := []
    Loop AppState.clickSteps.Length {
        tabNames.Push("Step " . A_Index)
    }
    
    ; Clear and recreate tabs
    Loop 10 {  ; Clear up to 10 possible existing tabs
        try stepTabControl.Delete(1)
    }
    
    Loop AppState.clickSteps.Length {
        stepTabControl.Add([tabNames[A_Index]])
    }
    
    ; Small delay for tab control to stabilize
    Sleep(20)
    
    ; Create content for each tab
    Loop AppState.clickSteps.Length {
        stepNum := A_Index
        CreateStepContent(stepNum)
    }
    
    ; Restore tab selection safely
    if (currentTabIndex > AppState.clickSteps.Length) {
        currentTabIndex := AppState.clickSteps.Length
    }
    if (currentTabIndex < 1) {
        currentTabIndex := 1
    }
    stepTabControl.Value := currentTabIndex
    
    ; Update button states
    addStepBtn.Enabled := (AppState.clickSteps.Length < 10)
    removeStepBtn.Enabled := (AppState.clickSteps.Length > 1)
    
    ; Force GUI to refresh and show all controls
    MainGui.Show("NoActivate")
}

;==============================================================================
; Create Content for a Single Step Tab
;==============================================================================
CreateStepContent(stepNum) {
    global stepTabControl, stepControls
    
    step := AppState.clickSteps[stepNum]
    controls := {}
    
    stepTabControl.UseTab(stepNum)
    
    baseX := 30
    baseY := 100
    
    ; Target Coordinate Section
    MainGui.Add("GroupBox", "x" . baseX . " y" . baseY . " w720 h130", "Target Coordinate")
    MainGui.Add("Text", "x" . (baseX + 10) . " y" . (baseY + 25), "X Coordinate:")
    controls.xCoordEdit := MainGui.Add("Edit", "x" . (baseX + 110) . " y" . (baseY + 22) . " w80 Number")
    MainGui.Add("Text", "x" . (baseX + 210) . " y" . (baseY + 25), "Y Coordinate:")
    controls.yCoordEdit := MainGui.Add("Edit", "x" . (baseX + 310) . " y" . (baseY + 22) . " w80 Number")
    
    ; Click Type Radio Buttons
    MainGui.Add("Text", "x" . (baseX + 10) . " y" . (baseY + 55), "Click Type:")
    controls.leftClickRadio := MainGui.Add("Radio", "x" . (baseX + 110) . " y" . (baseY + 52), "Left Click")
    controls.rightClickRadio := MainGui.Add("Radio", "x" . (baseX + 210) . " y" . (baseY + 52), "Right Click")
    
    ; Add event handlers with safe index checking
    controls.leftClickRadio.OnEvent("Click", RadioClickHandler.Bind("Left", stepNum))
    controls.rightClickRadio.OnEvent("Click", RadioClickHandler.Bind("Right", stepNum))
    
    ; Capture and Test buttons
    controls.captureBtn := MainGui.Add("Button", "x" . (baseX + 10) . " y" . (baseY + 85) . " w150", "Capture Coordinate (F3)")
    controls.captureBtn.OnEvent("Click", (*) => StartCoordinateCapture(stepNum))
    controls.testBtn := MainGui.Add("Button", "x" . (baseX + 170) . " y" . (baseY + 85) . " w100", "Test Click")
    controls.testBtn.OnEvent("Click", (*) => TestClick(stepNum))
    
    ; Click Settings Section
    baseY += 140
    MainGui.Add("GroupBox", "x" . baseX . " y" . baseY . " w720 h230", "Click Settings")
    
    MainGui.Add("Text", "x" . (baseX + 10) . " y" . (baseY + 25), "Modifier Key:")
    controls.modifierDropDown := MainGui.Add("DropDownList", "x" . (baseX + 110) . " y" . (baseY + 22) . " w100", ["None", "Shift", "Ctrl", "Alt"])
    MainGui.Add("Text", "x" . (baseX + 220) . " y" . (baseY + 25) . " c888888", "(pressed with click)")
    
    ; Intervals header with Add/Remove buttons
    MainGui.Add("Text", "x" . (baseX + 10) . " y" . (baseY + 55), "Intervals:")
    controls.addIntervalBtn := MainGui.Add("Button", "x" . (baseX + 110) . " y" . (baseY + 52) . " w60 h25", "+ Add")
    controls.addIntervalBtn.OnEvent("Click", (*) => AddInterval(stepNum))
    controls.removeIntervalBtn := MainGui.Add("Button", "x" . (baseX + 175) . " y" . (baseY + 52) . " w80 h25", "- Remove")
    controls.removeIntervalBtn.OnEvent("Click", (*) => RemoveInterval(stepNum))
    
    ; Interval controls (dynamic)
    controls.intervalControls := []
    controls.intervalStartY := baseY + 85
    controls.intervalSpacing := 30
    
    ; Create initial interval controls directly (don't call RebuildIntervalControls yet)
    Loop step.intervals.Length {
        y := controls.intervalStartY + ((A_Index - 1) * controls.intervalSpacing)
        
        intervalBaseX := 40
        
        ; Label
        label := MainGui.Add("Text", "x" . intervalBaseX . " y" . y, "Interval " . A_Index . ":")
        controls.intervalControls.Push(label)
        
        ; Edit box - create without value first
        edit := MainGui.Add("Edit", "x" . (intervalBaseX + 100) . " y" . (y - 3) . " w100 Number")
        controls.intervalControls.Push(edit)
        
        ; "ms" label
        msLabel := MainGui.Add("Text", "x" . (intervalBaseX + 210) . " y" . y, "ms")
        controls.intervalControls.Push(msLabel)
    }
    
    ; Pattern description
    controls.patternText := MainGui.Add("Text", "x" . (baseX + 10) . " y" . (baseY + 180) . " c888888 w700", "")
    
    stepTabControl.UseTab()
    
    ; Store controls for this step BEFORE setting values
    stepControls.Push(controls)
    
    ; NOW set all values explicitly after controls are created and stored
    controls.xCoordEdit.Value := step.targetX
    controls.yCoordEdit.Value := step.targetY
    
    ; Set click type radio buttons
    if (step.clickType = "Left") {
        controls.leftClickRadio.Value := 1
    } else {
        controls.rightClickRadio.Value := 1
    }
    
    ; Set modifier dropdown
    controls.modifierDropDown.Text := step.modifierKey
    
    ; Set interval values
    intervalIndex := 1
    for ctrl in controls.intervalControls {
        try {
            if (ctrl.Type = "Edit" && intervalIndex <= step.intervals.Length) {
                ctrl.Value := step.intervals[intervalIndex]
                intervalIndex++
            }
        }
    }
    
    ; Update button states
    controls.addIntervalBtn.Enabled := (step.intervals.Length < 3)
    controls.removeIntervalBtn.Enabled := (step.intervals.Length > 1)
    
    ; Update pattern description
    UpdatePatternDescription(stepNum)
    
    ; Force redraw of this tab's controls
    try {
        controls.xCoordEdit.Redraw()
        controls.yCoordEdit.Redraw()
    }
}

;==============================================================================
; Add Interval to Specific Step
;==============================================================================
AddInterval(stepNum) {
    step := AppState.clickSteps[stepNum]
    
    if (step.intervals.Length >= 3) {
        MsgBox("Maximum of 3 intervals allowed per step", "Limit Reached", 48)
        return
    }
    
    ; Save current values
    SaveCurrentIntervalValues(stepNum)
    
    ; Add new interval
    step.intervals.Push(1000)
    
    ; Rebuild controls
    RebuildIntervalControls(stepNum)
    UpdatePatternDescription(stepNum)
}

;==============================================================================
; Remove Interval from Specific Step
;==============================================================================
RemoveInterval(stepNum) {
    step := AppState.clickSteps[stepNum]
    
    if (step.intervals.Length <= 1) {
        MsgBox("Minimum of 1 interval required per step", "Cannot Remove", 48)
        return
    }
    
    ; Save current values
    SaveCurrentIntervalValues(stepNum)
    
    ; Remove last interval
    step.intervals.Pop()
    
    ; Rebuild controls
    RebuildIntervalControls(stepNum)
    UpdatePatternDescription(stepNum)
}

;==============================================================================
; Save Current Interval Values for a Specific Step
;==============================================================================
SaveCurrentIntervalValues(stepNum) {
    global stepControls
    
    if (stepNum > stepControls.Length || stepNum < 1) {
        return
    }
    
    controls := stepControls[stepNum]
    step := AppState.clickSteps[stepNum]
    
    if (!IsObject(controls)) {
        return
    }
    
    ; Check if intervalControls property exists using try/catch
    try {
        if (!IsObject(controls.intervalControls)) {
            return
        }
    } catch {
        return
    }
    
    intervalIndex := 1
    for ctrl in controls.intervalControls {
        try {
            if (ctrl.Type = "Edit" && intervalIndex <= step.intervals.Length) {
                value := Number(ctrl.Value)
                ; Only update if it's a valid positive number
                if (value > 0) {
                    step.intervals[intervalIndex] := value
                }
                intervalIndex++
            }
        }
    }
}

;==============================================================================
; Rebuild Interval Controls for a Specific Step
;==============================================================================
RebuildIntervalControls(stepNum) {
    global stepControls, stepTabControl
    
    if (stepNum > stepControls.Length || stepNum < 1) {
        return
    }
    
    controls := stepControls[stepNum]
    
    if (!IsObject(controls)) {
        return
    }
    
    step := AppState.clickSteps[stepNum]
    
    ; Hide and destroy existing interval controls using try/catch
    try {
        if (IsObject(controls.intervalControls)) {
            for ctrl in controls.intervalControls {
                try {
                    ctrl.Visible := false
                }
            }
            for ctrl in controls.intervalControls {
                try {
                    ctrl.Destroy()
                }
            }
        }
    }
    controls.intervalControls := []
    
    Sleep(10)
    
    ; Switch to this tab to create controls
    stepTabControl.UseTab(stepNum)
    
    ; Create new interval controls
    Loop step.intervals.Length {
        y := controls.intervalStartY + ((A_Index - 1) * controls.intervalSpacing)
        
        baseX := 40
        
        ; Label
        label := MainGui.Add("Text", "x" . baseX . " y" . y, "Interval " . A_Index . ":")
        controls.intervalControls.Push(label)
        
        ; Edit box
        edit := MainGui.Add("Edit", "x" . (baseX + 100) . " y" . (y - 3) . " w100 Number", step.intervals[A_Index])
        controls.intervalControls.Push(edit)
        
        ; "ms" label
        msLabel := MainGui.Add("Text", "x" . (baseX + 210) . " y" . y, "ms")
        controls.intervalControls.Push(msLabel)
    }
    
    stepTabControl.UseTab()
    
    ; Update button states with try/catch
    try {
        if (IsObject(controls.addIntervalBtn)) {
            controls.addIntervalBtn.Enabled := (step.intervals.Length < 3)
        }
    }
    try {
        if (IsObject(controls.removeIntervalBtn)) {
            controls.removeIntervalBtn.Enabled := (step.intervals.Length > 1)
        }
    }
    
    ; Ensure controls are visible
    for ctrl in controls.intervalControls {
        try {
            ctrl.Visible := true
        }
    }
}

;==============================================================================
; Update Pattern Description for a Specific Step
;==============================================================================
UpdatePatternDescription(stepNum) {
    global stepControls
    
    if (stepNum > stepControls.Length) {
        return
    }
    
    controls := stepControls[stepNum]
    step := AppState.clickSteps[stepNum]
    
    pattern := "Pattern: Click"
    
    Loop step.intervals.Length {
        pattern .= " → Wait " . step.intervals[A_Index] . "ms → Click"
    }
    
    pattern .= " → Next Step"
    controls.patternText.Value := pattern
}

;==============================================================================
; Start Coordinate Capture for Specific Step
;==============================================================================
StartCoordinateCapture(stepNum := 1) {
    global stepControls
    
    if (AppState.isRunning) {
        MsgBox("Cannot capture while automation is running", "Error", 48)
        return
    }
    
    AppState.isCapturing := true
    UpdateStatus("Move mouse to target position and press LEFT CLICK for Step " . stepNum)
    
    ToolTip("Click anywhere to capture that coordinate for Step " . stepNum, 10, 10)
    
    KeyWait("LButton", "D")
    
    MouseGetPos(&x, &y)
    
    ; Update state and GUI
    AppState.clickSteps[stepNum].targetX := x
    AppState.clickSteps[stepNum].targetY := y
    
    if (stepNum <= stepControls.Length) {
        controls := stepControls[stepNum]
        controls.xCoordEdit.Value := x
        controls.yCoordEdit.Value := y
    }
    
    AppState.isCapturing := false
    ToolTip()
    
    UpdateStatus("Coordinate captured for Step " . stepNum . ": (" . x . ", " . y . ")", 3000)
    FlashLocation(x, y)
}

;==============================================================================
; Test Click for Specific Step
;==============================================================================
TestClick(stepNum) {
    global stepControls
    
    if (stepNum > stepControls.Length) {
        return
    }
    
    controls := stepControls[stepNum]
    step := AppState.clickSteps[stepNum]
    
    x := Number(controls.xCoordEdit.Value)
    y := Number(controls.yCoordEdit.Value)
    modifier := controls.modifierDropDown.Text
    
    ; Check which radio button is selected
    if (controls.leftClickRadio.Value = 1) {
        clickType := "Left"
    } else if (controls.rightClickRadio.Value = 1) {
        clickType := "Right"
    } else {
        clickType := "Left"  ; Default fallback
    }
    
    if (x = 0 && y = 0) {
        MsgBox("Please set coordinates first for Step " . stepNum, "Invalid Coordinates", 48)
        return
    }
    
    modifierText := modifier != "None" ? " with " . modifier : ""
    UpdateStatus("Test " . clickType . " clicking at (" . x . ", " . y . ")" . modifierText . " for Step " . stepNum . "...", 3000)
    
    MouseGetPos(&currentX, &currentY)
    
    PerformModifierClick(x, y, modifier, clickType)
    
    MouseMove(currentX, currentY)
}

;==============================================================================
; Flash Location Indicator
;==============================================================================
FlashLocation(x, y) {
    indicator := Gui("+AlwaysOnTop -Caption +ToolWindow")
    indicator.BackColor := "Lime"
    WinSetTransparent(200, indicator)
    
    indicator.Show("x" . (x - 10) . " y" . (y - 10) . " w20 h20 NoActivate")
    
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
; Save All Step Values from GUI
;==============================================================================
SaveAllStepValues() {
    global stepControls
    
    ; Only save steps that have controls initialized
    maxStepsToSave := Min(AppState.clickSteps.Length, stepControls.Length)
    
    Loop maxStepsToSave {
        stepNum := A_Index
        
        controls := stepControls[stepNum]
        
        if (!IsObject(controls)) {
            continue
        }
        
        step := AppState.clickSteps[stepNum]
        
        ; Save basic settings with error handling using property access
        try {
            if (IsObject(controls.xCoordEdit)) {
                step.targetX := Number(controls.xCoordEdit.Value)
            }
        }
        try {
            if (IsObject(controls.yCoordEdit)) {
                step.targetY := Number(controls.yCoordEdit.Value)
            }
        }
        try {
            if (IsObject(controls.modifierDropDown)) {
                step.modifierKey := controls.modifierDropDown.Text
            }
        }
        try {
            if (IsObject(controls.leftClickRadio) && IsObject(controls.rightClickRadio)) {
                ; Check which radio button is selected (Value = 1 means selected)
                leftValue := controls.leftClickRadio.Value
                rightValue := controls.rightClickRadio.Value
                
                if (leftValue = 1) {
                    step.clickType := "Left"
                } else if (rightValue = 1) {
                    step.clickType := "Right"
                } else {
                    ; Fallback - if neither is explicitly set, keep current value or default to Left
                    if (!step.HasOwnProp("clickType") || step.clickType = "") {
                        step.clickType := "Left"
                    }
                }
            }
        }
        
        ; Save intervals
        SaveCurrentIntervalValues(stepNum)
    }
}

;==============================================================================
; Min Helper Function
;==============================================================================
Min(a, b) {
    return (a < b) ? a : b
}

;==============================================================================
; Radio Button Click Handler (Safe)
;==============================================================================
RadioClickHandler(clickType, stepNum, *) {
    ; Safely check if step still exists
    if (stepNum <= AppState.clickSteps.Length && stepNum > 0) {
        AppState.clickSteps[stepNum].clickType := clickType
    }
}

;==============================================================================
; Save Current Settings
;==============================================================================
SaveCurrentSettings() {
    ; Save all values from GUI first
    SaveAllStepValues()
    
    ; Validate all intervals
    Loop AppState.clickSteps.Length {
        step := AppState.clickSteps[A_Index]
        
        Loop step.intervals.Length {
            if (step.intervals[A_Index] < 100) {
                MsgBox("Step " . A_Index . " Interval " . A_Index . " must be at least 100ms", "Invalid Input", 48)
                return
            }
        }
    }
    
    ; Save to file
    SaveSettings()
    UpdateStatus("All settings saved successfully!", 3000)
}

;==============================================================================
; Toggle GUI Controls Based on State
;==============================================================================
UpdateGUIState(running := false) {
    global startBtn, stopBtn, addStepBtn, removeStepBtn, saveBtn, stepControls
    
    if (running) {
        startBtn.Enabled := false
        stopBtn.Enabled := true
        addStepBtn.Enabled := false
        removeStepBtn.Enabled := false
        saveBtn.Enabled := false
        
        ; Disable all step controls
        for controls in stepControls {
            try {
                controls.xCoordEdit.Enabled := false
                controls.yCoordEdit.Enabled := false
                controls.leftClickRadio.Enabled := false
                controls.rightClickRadio.Enabled := false
                controls.captureBtn.Enabled := false
                controls.testBtn.Enabled := false
                controls.modifierDropDown.Enabled := false
                controls.addIntervalBtn.Enabled := false
                controls.removeIntervalBtn.Enabled := false
                
                for ctrl in controls.intervalControls {
                    try {
                        if (ctrl.Type = "Edit") {
                            ctrl.Enabled := false
                        }
                    }
                }
            }
        }
    } else {
        startBtn.Enabled := true
        stopBtn.Enabled := false
        addStepBtn.Enabled := (AppState.clickSteps.Length < 10)
        removeStepBtn.Enabled := (AppState.clickSteps.Length > 1)
        saveBtn.Enabled := true
        
        ; Enable all step controls
        Loop AppState.clickSteps.Length {
            stepNum := A_Index
            
            if (stepNum > stepControls.Length) {
                continue
            }
            
            controls := stepControls[stepNum]
            step := AppState.clickSteps[stepNum]
            
            try {
                controls.xCoordEdit.Enabled := true
                controls.yCoordEdit.Enabled := true
                controls.leftClickRadio.Enabled := true
                controls.rightClickRadio.Enabled := true
                controls.captureBtn.Enabled := true
                controls.testBtn.Enabled := true
                controls.modifierDropDown.Enabled := true
                controls.addIntervalBtn.Enabled := (step.intervals.Length < 3)
                controls.removeIntervalBtn.Enabled := (step.intervals.Length > 1)
                
                for ctrl in controls.intervalControls {
                    try {
                        if (ctrl.Type = "Edit") {
                            ctrl.Enabled := true
                        }
                    }
                }
            }
        }
    }
}

