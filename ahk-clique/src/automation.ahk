;==============================================================================
; Automation Logic Module
; Handles multi-step automated clicking sequences
;==============================================================================

;==============================================================================
; Execution Queue - Stores flattened action sequence
;==============================================================================
global ExecutionQueue := []
global ExecutionQueueIndex := 1

;==============================================================================
; Build Execution Queue (Like Promise.all())
;==============================================================================
BuildExecutionQueue() {
    global ExecutionQueue := []
    
    ; Debug: Show what we're building from
    debugMsg := "Building Queue from AppState:`n"
    Loop AppState.clickSteps.Length {
        step := AppState.clickSteps[A_Index]
        debugMsg .= "Step " . A_Index . ": "
        Loop step.intervals.Length {
            debugMsg .= step.intervals[A_Index] . "ms "
        }
        debugMsg .= "`n"
    }
    ToolTip(debugMsg, 10, 50)
    SetTimer(() => ToolTip(), -3000)
    
    ; Flatten all steps and intervals into a sequential queue
    Loop AppState.clickSteps.Length {
        stepNum := A_Index
        step := AppState.clickSteps[stepNum]
        
        ; For each interval in this step, create an action
        Loop step.intervals.Length {
            intervalNum := A_Index
            
            ; Create an action object
            action := {
                stepNum: stepNum,
                stepTotal: AppState.clickSteps.Length,
                intervalNum: intervalNum,
                intervalTotal: step.intervals.Length,
                targetX: step.targetX,
                targetY: step.targetY,
                clickType: step.clickType,
                modifierKey: step.modifierKey,
                waitMs: step.intervals[intervalNum]
            }
            
            ExecutionQueue.Push(action)
        }
    }
    
    return ExecutionQueue.Length
}

;==============================================================================
; Start Automation Sequence
;==============================================================================
StartAutomation() {
    if (AppState.isRunning) {
        return
    }
    
    ; Save all current GUI values
    SaveAllStepValues()
    
    ; Validate all steps have coordinates
    Loop AppState.clickSteps.Length {
        step := AppState.clickSteps[A_Index]
        
        if (step.targetX = 0 && step.targetY = 0) {
            MsgBox("Please set target coordinates for Step " . A_Index, "No Coordinates", 48)
            return
        }
        
        ; Validate intervals
        Loop step.intervals.Length {
            if (step.intervals[A_Index] < 100) {
                MsgBox("Step " . A_Index . " Interval " . A_Index . " must be at least 100ms", "Invalid Intervals", 48)
                return
            }
        }
    }
    
    ; Build the execution queue - guarantees sequential order
    totalActions := BuildExecutionQueue()
    
    if (totalActions = 0) {
        MsgBox("No actions to execute", "Empty Queue", 48)
        return
    }
    
    ; Update state
    AppState.isRunning := true
    global ExecutionQueueIndex := 1
    UpdateGUIState(true)
    
    ; Show what we're actually running with
    firstAction := ExecutionQueue[1]
    debugInfo := "RUNNING - " . totalActions . " total actions | Step 1: " 
                . firstAction.clickType . " click, " 
                . firstAction.modifierKey . " modifier"
    UpdateStatus(debugInfo)
    
    ; Start the execution queue
    ExecuteNextAction()
}

;==============================================================================
; Stop Automation
;==============================================================================
StopAutomation() {
    if (!AppState.isRunning) {
        return
    }
    
    ; Stop the execution timer
    SetTimer(ExecuteNextAction, 0)
    
    ; Update state
    AppState.isRunning := false
    global ExecutionQueueIndex := 1
    global ExecutionQueue := []
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
; Execute Next Action in Queue (Sequential Guarantee)
;==============================================================================
ExecuteNextAction() {
    global ExecutionQueue, ExecutionQueueIndex
    
    if (!AppState.isRunning) {
        return
    }
    
    ; Check if we've exhausted the queue - loop back to start
    if (ExecutionQueueIndex > ExecutionQueue.Length) {
        ExecutionQueueIndex := 1
    }
    
    ; Get the current action from queue (sequential, deterministic)
    action := ExecutionQueue[ExecutionQueueIndex]
    
    ; Perform the click - this is synchronous and atomic
    PerformModifierClick(action.targetX, action.targetY, action.modifierKey, action.clickType)
    
    ; Show visual feedback
    ShowClickFeedback(action.targetX, action.targetY)
    
    ; Update status with queue position
    UpdateStatus("RUNNING - Action " . ExecutionQueueIndex . "/" . ExecutionQueue.Length 
                . " | Step " . action.stepNum . "/" . action.stepTotal
                . " | Interval " . action.intervalNum . "/" . action.intervalTotal
                . " | Next in " . action.waitMs . "ms")
    
    ; Move to next action in queue (increment happens BEFORE scheduling)
    ExecutionQueueIndex++
    
    ; Schedule next action with ONE-SHOT timer (negative value)
    ; This guarantees no overlapping executions
    SetTimer(ExecuteNextAction, -action.waitMs)
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
    ; Move mouse to position first (hover before click)
    MouseMove(x, y, 0)  ; 0 = instant move, can change to 2-5 for visible movement
    
    ; Small delay to ensure hover states trigger
    Sleep(200)
    
    ; Determine click button
    clickButton := (clickType = "Right") ? "Right" : "Left"
    
    ; Press modifier key if specified with guaranteed hold
    switch modifier {
        case "Shift":
            Send("{LShift down}")
            Sleep(100)  ; Ensure key down is registered
            Click(x, y, clickButton)
            Sleep(100)  ; Ensure click completes before releasing
            Send("{LShift up}")
            
        case "Ctrl":
            Send("{Ctrl down}")
            Sleep(100)  ; Ensure key down is registered
            Click(x, y, clickButton)
            Sleep(100)  ; Ensure click completes before releasing
            Send("{Ctrl up}")
            
        case "Alt":
            Send("{Alt down}")
            Sleep(100)  ; Ensure key down is registered
            Click(x, y, clickButton)
            Sleep(100)  ; Ensure click completes before releasing
            Send("{Alt up}")
            
        default:  ; "None"
            Click(x, y, clickButton)
    }
}
