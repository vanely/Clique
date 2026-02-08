;==============================================================================
; Automation Logic Module (Rebuilt for Multi-Step Sequential Execution)
; Handles coordinate capture and automated clicking through multiple steps
;==============================================================================

;==============================================================================
; Start Coordinate Capture Mode (called by hotkey F3)
;==============================================================================
StartCoordinateCapture() {
    ; Capture for the currently active tab/step
    activeStep := AppState.activeTabIndex
    
    if (activeStep > AppState.clickSteps.Length) {
        MsgBox("Please select a step tab first", "No Step Selected", 48)
        return
    }
    
    CaptureCoordinateForStep(activeStep)
}

;==============================================================================
; Start Automation (Sequential Execution)
;==============================================================================
StartAutomation() {
    if (AppState.isRunning) {
        return
    }
    
    ; Update all steps from GUI controls BEFORE validating/starting
    for stepIndex, controls in StepTabs {
        step := AppState.clickSteps[stepIndex]
        step.targetX := Number(controls["xCoord"].Value)
        step.targetY := Number(controls["yCoord"].Value)
        step.modifierKey := controls["modifier"].Text
        
        ; Update intervals
        step.intervals := []
        for intervalEdit in controls["intervals"] {
            step.intervals.Push(Number(intervalEdit.Value))
        }
    }
    
    ; Validate all steps have coordinates
    for index, step in AppState.clickSteps {
        if (step.targetX = 0 && step.targetY = 0) {
            MsgBox("Step " . index . " has no coordinates set!`nPlease configure all steps.", "Invalid Configuration", 48)
            return
        }
        
        ; Validate all intervals
        for interval in step.intervals {
            if (interval < 100) {
                MsgBox("Step " . index . " has intervals less than 100ms!`nPlease fix before starting.", "Invalid Intervals", 48)
                return
            }
        }
    }
    
    ; Initialize execution state
    AppState.isRunning := true
    AppState.currentStepIndex := 1
    AppState.currentIntervalIndex := 1
    
    UpdateGUIState(true)
    UpdateStatus("RUNNING - Step 1 of " . AppState.clickSteps.Length)
    
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
    AppState.currentStepIndex := 1
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
; Perform Click Action (Sequential Step & Interval Execution)
;==============================================================================
PerformClick() {
    if (!AppState.isRunning) {
        return
    }
    
    ; Get current step
    currentStep := AppState.clickSteps[AppState.currentStepIndex]
    
    ; Perform the click with modifier key
    PerformModifierClick(currentStep.targetX, currentStep.targetY, currentStep.modifierKey)
    
    ; Show brief visual feedback
    ShowClickFeedback(currentStep.targetX, currentStep.targetY)
    
    ; Get current interval
    currentInterval := currentStep.intervals[AppState.currentIntervalIndex]
    
    ; Update status
    statusMsg := "RUNNING - Step " . AppState.currentStepIndex . "/" . AppState.clickSteps.Length
    statusMsg .= " | Interval " . AppState.currentIntervalIndex . "/" . currentStep.intervals.Length
    statusMsg .= " | Next: " . currentInterval . "ms"
    UpdateStatus(statusMsg)
    
    ; Advance to next interval
    AppState.currentIntervalIndex++
    
    ; Check if we've completed all intervals in this step
    if (AppState.currentIntervalIndex > currentStep.intervals.Length) {
        ; Move to next step
        AppState.currentIntervalIndex := 1
        AppState.currentStepIndex++
        
        ; Check if we've completed all steps
        if (AppState.currentStepIndex > AppState.clickSteps.Length) {
            ; Loop back to first step
            AppState.currentStepIndex := 1
        }
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
PerformModifierClick(x, y, modifier) {
    ; Keep modifier pressed DURING the entire click operation
    switch modifier {
        case "Shift":
            Send("{Shift down}")
            ; Sleep(800)         ; Pre-click delay
            Click(x, y)       ; Click while Shift is still down
            ; Sleep(100)        ; Keep Shift held after click
            Send("{Shift up}")
        case "Ctrl":
            Send("{Ctrl down}")
            ; Sleep(50)
            Click(x, y)       ; Click while Ctrl is still down
            ; Sleep(150)
            Send("{Ctrl up}")
        case "Alt":
            Send("{Alt down}")
            ; Sleep(50)
            Click(x, y)       ; Click while Alt is still down
            ; Sleep(150)
            Send("{Alt up}")
        default:  ; "None"
            Click(x, y)
    }
}
