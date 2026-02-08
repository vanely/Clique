;==============================================================================
; GUI Components Module (Rebuilt for ClickStep Architecture)
; Handles tabbed interface with multiple click sequences
;==============================================================================

global MainGui := ""
global TabControl := ""
global StepTabs := Map()  ; Store references to step tab controls

;==============================================================================
; Create Main GUI Window with Tabs
;==============================================================================
CreateMainGUI() {
    global MainGui := Gui("+AlwaysOnTop +Resize", "Desktop Automation Tool - Multi-Step")
    MainGui.SetFont("s10", "Segoe UI")
    
    ; Tab Control
    global TabControl := MainGui.Add("Tab3", "x10 y10 w780 h450", [])
    
    ; Add event handler for tab changes
    TabControl.OnEvent("Change", (*) => OnTabChange())
    
    ; Build initial tabs
    RebuildAllTabs()
    
    ; Control Buttons Section (below tabs)
    MainGui.Add("GroupBox", "x10 y470 w780 h80", "Controls")
    
    global startBtn := MainGui.Add("Button", "x20 y495 w150 h40", "Start All (F1)")
    startBtn.OnEvent("Click", (*) => StartAutomation())
    
    global stopBtn := MainGui.Add("Button", "x180 y495 w150 h40 Disabled", "Stop (F2)")
    stopBtn.OnEvent("Click", (*) => StopAutomation())
    
    global emergencyBtn := MainGui.Add("Button", "x340 y495 w150 h40 cRed", "EMERGENCY (ESC)")
    emergencyBtn.OnEvent("Click", (*) => EmergencyStop())
    
    global saveBtn := MainGui.Add("Button", "x500 y495 w280 h40", "Save All Settings")
    saveBtn.OnEvent("Click", (*) => SaveAllSettings())
    
    ; Status Section
    MainGui.Add("GroupBox", "x10 y560 w780 h60", "Status")
    global statusText := MainGui.Add("Text", "x20 y585 w760 h30", "Ready - Press F3 to capture coordinates")
    
    ; Handle window close
    MainGui.OnEvent("Close", (*) => ExitApp())
    
    ; Show the GUI
    MainGui.Show("w800 h630")
}

;==============================================================================
; Rebuild All Tabs (when steps added/removed)
;==============================================================================
RebuildAllTabs() {
    global TabControl, StepTabs
    
    ; Build tab titles
    tabTitles := []
    for index, step in AppState.clickSteps {
        tabTitles.Push("Step " . index)
    }
    tabTitles.Push("+")  ; Add new step tab
    
    ; Recreate tab control with all tabs at once
    TabControl.Delete()
    for title in tabTitles {
        TabControl.Add([title])
    }
    
    ; Clear old step data
    StepTabs := Map()
    
    ; Create content for each step tab
    Loop AppState.clickSteps.Length {
        stepIndex := A_Index
        TabControl.UseTab(stepIndex)
        CreateStepTabContent(stepIndex)
    }
    
    ; Create content for "+" tab
    TabControl.UseTab(AppState.clickSteps.Length + 1)
    CreateAddStepTabContent()
    
    TabControl.UseTab()  ; Finish tab setup
    
    ; Select the active tab (bounds check)
    if (AppState.activeTabIndex > AppState.clickSteps.Length + 1)
        AppState.activeTabIndex := 1
    TabControl.Choose(AppState.activeTabIndex)
}

;==============================================================================
; Create Content for a ClickStep Tab
;==============================================================================
CreateStepTabContent(stepIndex) {
    step := AppState.clickSteps[stepIndex]
    
    ; Store controls in map for this step
    stepControls := Map()
    
    ; Coordinate Section
    MainGui.Add("GroupBox", "x20 y40 w740 h100", "Target Coordinate")
    MainGui.Add("Text", "x30 y65", "X Coordinate:")
    stepControls["xCoord"] := MainGui.Add("Edit", "x130 y62 w80 Number", step.targetX)
    
    MainGui.Add("Text", "x230 y65", "Y Coordinate:")
    stepControls["yCoord"] := MainGui.Add("Edit", "x330 y62 w80 Number", step.targetY)
    
    stepControls["captureBtn"] := MainGui.Add("Button", "x450 y60 w150", "Capture (F3)")
    stepControls["captureBtn"].OnEvent("Click", (*) => CaptureCoordinateForStep(stepIndex))
    
    stepControls["testBtn"] := MainGui.Add("Button", "x610 y60 w130", "Test Click")
    stepControls["testBtn"].OnEvent("Click", (*) => TestClickForStep(stepIndex))
    
    ; Click Settings Section
    MainGui.Add("GroupBox", "x20 y150 w740 h110", "Click Settings")
    
    MainGui.Add("Text", "x30 y175", "Modifier Key:")
    stepControls["modifier"] := MainGui.Add("DropDownList", "x130 y172 w100", ["None", "Shift", "Ctrl", "Alt"])
    stepControls["modifier"].Text := step.modifierKey
    MainGui.Add("Text", "x240 y175 c888888", "(pressed with click)")
    
    ; Intervals Section (dynamic - rows of 4)
    MainGui.Add("Text", "x30 y210", "Intervals (ms):")
    
    stepControls["intervals"] := []
    rowNum := 0
    colNum := 0
    maxCols := 4
    startX := 130
    startY := 207
    colWidth := 120
    rowHeight := 30
    
    for idx, interval in step.intervals {
        ; Calculate position
        xPos := startX + (colNum * colWidth)
        yPos := startY + (rowNum * rowHeight)
        
        ; Add interval edit
        intervalEdit := MainGui.Add("Edit", "x" . xPos . " y" . yPos . " w80 Number", interval)
        
        ; Delete button for intervals (if more than 1)
        if (step.intervals.Length > 1) {
            currentIdx := idx  ; Capture by value
            deleteBtn := MainGui.Add("Button", "x" . (xPos + 85) . " y" . yPos . " w25 h23", "×")
            deleteBtn.OnEvent("Click", ((si, ii) => (*) => RemoveInterval(si, ii))(stepIndex, currentIdx))
        }
        
        stepControls["intervals"].Push(intervalEdit)
        
        ; Move to next position
        colNum++
        if (colNum >= maxCols) {
            colNum := 0
            rowNum++
        }
    }
    
    ; Add interval button (on same row or new row)
    xPos := startX + (colNum * colWidth)
    yPos := startY + (rowNum * rowHeight)
    addIntervalBtn := MainGui.Add("Button", "x" . xPos . " y" . yPos . " w30 h23", "+")
    addIntervalBtn.OnEvent("Click", (*) => AddInterval(stepIndex))
    
    ; Calculate height needed for intervals
    totalRows := rowNum + 1
    intervalsHeight := (totalRows * rowHeight) + 40
    
    ; Adjust pattern text position
    patternY := 207 + (totalRows * rowHeight) + 5
    MainGui.Add("Text", "x30 y" . patternY . " c888888", "Pattern: Click → Wait Int1 → Click → Wait Int2 → ... → Next Step")
    
    ; Adjust Step Management section position
    stepMgmtY := patternY + 30
    MainGui.Add("GroupBox", "x20 y" . stepMgmtY . " w740 h140", "Step Management")
    
    MainGui.Add("Text", "x30 y" . (stepMgmtY + 25) . " w700", "This is Click Step " . stepIndex . " of " . AppState.clickSteps.Length)
    MainGui.Add("Text", "x30 y" . (stepMgmtY + 50) . " w700 c888888", "Steps execute sequentially: Step 1 (all intervals) → Step 2 (all intervals) → ... → Loop")
    
    ; Delete step button (if more than 1 step)
    if (AppState.clickSteps.Length > 1) {
        deleteStepBtn := MainGui.Add("Button", "x30 y" . (stepMgmtY + 80) . " w200 h40 cRed", "Delete This Step")
        deleteStepBtn.OnEvent("Click", (*) => DeleteStep(stepIndex))
    }
    
    ; Move step buttons
    if (stepIndex > 1) {
        moveUpBtn := MainGui.Add("Button", "x240 y" . (stepMgmtY + 80) . " w100 h40", "Move ↑")
        moveUpBtn.OnEvent("Click", (*) => MoveStep(stepIndex, -1))
    }
    
    if (stepIndex < AppState.clickSteps.Length) {
        moveDownBtn := MainGui.Add("Button", "x350 y" . (stepMgmtY + 80) . " w100 h40", "Move ↓")
        moveDownBtn.OnEvent("Click", (*) => MoveStep(stepIndex, 1))
    }
    
    ; Store controls for this step
    StepTabs[stepIndex] := stepControls
}

;==============================================================================
; Tab Change Event Handler
;==============================================================================
OnTabChange() {
    global TabControl
    selectedTab := TabControl.Value
    
    ; Check if the "+" tab was clicked
    if (selectedTab = AppState.clickSteps.Length + 1) {
        ; Auto-create new step
        AddNewStep()
    } else {
        ; Update active tab index
        AppState.activeTabIndex := selectedTab
    }
}

;==============================================================================
; Create Content for Add Step Tab (just visual hint)
;==============================================================================
CreateAddStepTabContent() {
    MainGui.Add("Text", "x250 y200 w300 h80 Center", "Click this tab to automatically`nadd a new Click Step")
    MainGui.Add("Text", "x250 y300 w300 Center c888888", "A new step will be created instantly")
}

;==============================================================================
; Step Management Functions
;==============================================================================
AddNewStep() {
    ; Add new step with defaults
    AppState.clickSteps.Push({
        targetX: 0,
        targetY: 0,
        modifierKey: "None",
        intervals: [1000]
    })
    
    ; Switch to new step
    AppState.activeTabIndex := AppState.clickSteps.Length
    
    ; Rebuild GUI
    RebuildAllTabs()
    UpdateStatus("New step added! Configure coordinates and intervals.")
}

DeleteStep(stepIndex) {
    if (AppState.clickSteps.Length <= 1) {
        MsgBox("Cannot delete the last step!", "Error", 48)
        return
    }
    
    result := MsgBox("Delete Step " . stepIndex . "?", "Confirm Delete", 4)
    if (result != "Yes")
        return
    
    ; Remove step
    AppState.clickSteps.RemoveAt(stepIndex)
    
    ; Adjust active tab if needed
    if (AppState.activeTabIndex > AppState.clickSteps.Length)
        AppState.activeTabIndex := AppState.clickSteps.Length
    
    ; Rebuild GUI
    RebuildAllTabs()
    UpdateStatus("Step deleted")
}

MoveStep(stepIndex, direction) {
    newIndex := stepIndex + direction
    
    if (newIndex < 1 || newIndex > AppState.clickSteps.Length)
        return
    
    ; Swap steps
    temp := AppState.clickSteps[stepIndex]
    AppState.clickSteps[stepIndex] := AppState.clickSteps[newIndex]
    AppState.clickSteps[newIndex] := temp
    
    ; Update active tab
    AppState.activeTabIndex := newIndex
    
    ; Rebuild GUI
    RebuildAllTabs()
    UpdateStatus("Step moved")
}

;==============================================================================
; Interval Management Functions
;==============================================================================
AddInterval(stepIndex) {
    step := AppState.clickSteps[stepIndex]
    step.intervals.Push(1000)  ; Add default 1000ms interval
    
    AppState.activeTabIndex := stepIndex
    RebuildAllTabs()
    UpdateStatus("Interval added to Step " . stepIndex)
}

RemoveInterval(stepIndex, intervalIndex) {
    step := AppState.clickSteps[stepIndex]
    
    if (step.intervals.Length <= 1) {
        MsgBox("Cannot remove the last interval!", "Error", 48)
        return
    }
    
    step.intervals.RemoveAt(intervalIndex)
    
    AppState.activeTabIndex := stepIndex
    RebuildAllTabs()
    UpdateStatus("Interval removed from Step " . stepIndex)
}

;==============================================================================
; Per-Step Actions
;==============================================================================
CaptureCoordinateForStep(stepIndex) {
    if (AppState.isRunning) {
        MsgBox("Cannot capture while automation is running", "Error", 48)
        return
    }
    
    AppState.isCapturing := true
    AppState.activeTabIndex := stepIndex
    UpdateStatus("Step " . stepIndex . ": Click anywhere to capture coordinate")
    
    ; Show visual feedback
    ToolTip("Click anywhere to capture coordinate for Step " . stepIndex, 10, 10)
    
    ; Wait for mouse click
    KeyWait("LButton", "D")
    
    ; Capture the position
    MouseGetPos(&x, &y)
    
    ; Update step data
    AppState.clickSteps[stepIndex].targetX := x
    AppState.clickSteps[stepIndex].targetY := y
    
    ; Update GUI
    if (StepTabs.Has(stepIndex)) {
        controls := StepTabs[stepIndex]
        controls["xCoord"].Value := x
        controls["yCoord"].Value := y
    }
    
    AppState.isCapturing := false
    ToolTip()
    
    UpdateStatus("Step " . stepIndex . ": Coordinate captured (" . x . ", " . y . ")", 3000)
    
    ; Flash the captured location
    FlashLocation(x, y)
}

TestClickForStep(stepIndex) {
    step := AppState.clickSteps[stepIndex]
    controls := StepTabs[stepIndex]
    
    ; Read current values from GUI
    x := Number(controls["xCoord"].Value)
    y := Number(controls["yCoord"].Value)
    modifier := controls["modifier"].Text
    
    if (x = 0 && y = 0) {
        MsgBox("Please set coordinates first", "Invalid Coordinates", 48)
        return
    }
    
    modifierText := modifier != "None" ? " with " . modifier : ""
    UpdateStatus("Step " . stepIndex . ": Test clicking at (" . x . ", " . y . ")" . modifierText, 3000)
    
    ; Save current position
    MouseGetPos(&currentX, &currentY)
    
    ; Perform test click with modifier
    PerformModifierClick(x, y, modifier)
    
    ; Return to original position
    MouseMove(currentX, currentY)
}

;==============================================================================
; Save All Settings from GUI
;==============================================================================
SaveAllSettings() {
    ; Update all steps from GUI controls
    for stepIndex, controls in StepTabs {
        step := AppState.clickSteps[stepIndex]
        
        step.targetX := Number(controls["xCoord"].Value)
        step.targetY := Number(controls["yCoord"].Value)
        step.modifierKey := controls["modifier"].Text
        
        ; Update intervals
        step.intervals := []
        for intervalEdit in controls["intervals"] {
            intervalVal := Number(intervalEdit.Value)
            if (intervalVal < 100) {
                MsgBox("All intervals must be at least 100ms! (Step " . stepIndex . ")", "Invalid Input", 48)
                return
            }
            step.intervals.Push(intervalVal)
        }
    }
    
    ; Save to file
    SaveSettings()
    UpdateStatus("All settings saved successfully!", 3000)
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
    global startBtn, stopBtn, saveBtn
    
    if (running) {
        startBtn.Enabled := false
        stopBtn.Enabled := true
        saveBtn.Enabled := false
        TabControl.Enabled := false
    } else {
        startBtn.Enabled := true
        stopBtn.Enabled := false
        saveBtn.Enabled := true
        TabControl.Enabled := true
    }
}

;==============================================================================
; Visual Feedback for Coordinate Capture
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
