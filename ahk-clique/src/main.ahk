;==============================================================================
; Desktop Automation Tool - Main Entry Point
; AutoHotkey v2.0
; 
; A simple tool for automating mouse clicks at specified coordinates with
; configurable intervals.
;==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; Set coordinate mode to screen for absolute positioning
CoordMode("Mouse", "Screen")
CoordMode("ToolTip", "Screen")

; Include dependencies
#Include gui.ahk
#Include automation.ahk
#Include utils.ahk

;==============================================================================
; Global State
;==============================================================================
global AppState := {
    clickSteps: [
        {
            targetX: 0,
            targetY: 0,
            clickType: "Left",
            modifierKey: "None",
            intervals: [1000, 2000]
        }
    ],
    currentStepIndex: 1,  ; Which step is currently being executed
    currentIntervalIndex: 1,  ; Which interval within the current step
    isRunning: false,
    isCapturing: false
}

; Global arrays to store control references per step
global stepControls := []  ; Array of objects, each containing controls for one step

;==============================================================================
; Initialization
;==============================================================================
Main()

Main() {
    ; Load saved settings
    LoadSettings()
    
    ; Create the GUI
    CreateMainGUI()
    
    ; Register global hotkeys
    RegisterHotkeys()
    
    ; Show welcome tooltip
    ShowWelcome()
}

;==============================================================================
; Hotkey Registrations
;==============================================================================
RegisterHotkeys() {
    ; ESC - Emergency stop
    Hotkey("Esc", (*) => EmergencyStop())
    
    ; F1 - Start automation
    Hotkey("F1", (*) => StartAutomation())
    
    ; F2 - Stop automation
    Hotkey("F2", (*) => StopAutomation())
    
    ; F3 - Capture coordinate for currently active tab
    Hotkey("F3", (*) => CaptureCurrentTab())
}

;==============================================================================
; Capture Coordinate for Currently Active Tab
;==============================================================================
CaptureCurrentTab() {
    global stepTabControl
    
    try {
        currentTab := stepTabControl.Value
        StartCoordinateCapture(currentTab)
    } catch {
        ; Fallback to step 1 if tab control not initialized
        StartCoordinateCapture(1)
    }
}

;==============================================================================
; Welcome Message
;==============================================================================
ShowWelcome() {
    ToolTip("Desktop Automation Tool Started`n"
          . "F3 - Capture coordinate`n"
          . "F1 - Start automation`n"
          . "F2 - Stop automation`n"
          . "ESC - Emergency stop", 10, 10)
    SetTimer(() => ToolTip(), -5000)  ; Hide after 5 seconds
}

;==============================================================================
; Settings Management
;==============================================================================
LoadSettings() {
    configFile := A_ScriptDir . "\..\config\settings.ini"
    
    if FileExist(configFile) {
        ; Load number of click steps
        stepCount := IniRead(configFile, "General", "StepCount", 1)
        
        ; Validate step count
        if (stepCount < 1) {
            stepCount := 1
        }
        if (stepCount > 10) {
            stepCount := 10
        }
        
        AppState.clickSteps := []
        
        ; Load each click step
        Loop stepCount {
            stepNum := A_Index
            step := {}
            
            ; Load coordinates with validation
            step.targetX := Number(IniRead(configFile, "Step" . stepNum, "X", 0))
            step.targetY := Number(IniRead(configFile, "Step" . stepNum, "Y", 0))
            step.modifierKey := IniRead(configFile, "Step" . stepNum, "ModifierKey", "None")
            step.clickType := IniRead(configFile, "Step" . stepNum, "ClickType", "Left")
            
            ; Validate modifier key
            if (step.modifierKey != "None" && step.modifierKey != "Shift" 
                && step.modifierKey != "Ctrl" && step.modifierKey != "Alt") {
                step.modifierKey := "None"
            }
            
            ; Validate click type
            if (step.clickType != "Left" && step.clickType != "Right") {
                step.clickType := "Left"
            }
            
            ; Load intervals for this step with validation
            intervalCount := IniRead(configFile, "Step" . stepNum, "IntervalCount", 2)
            if (intervalCount < 1) {
                intervalCount := 1
            }
            if (intervalCount > 3) {
                intervalCount := 3
            }
            
            step.intervals := []
            
            Loop intervalCount {
                value := Number(IniRead(configFile, "Step" . stepNum, "Interval" . A_Index, A_Index * 1000))
                ; Validate interval (minimum 100ms, maximum 3600000ms = 1 hour)
                if (value < 100) {
                    value := 100
                }
                if (value > 3600000) {
                    value := 3600000
                }
                step.intervals.Push(value)
            }
            
            ; Ensure at least 1 interval
            if (step.intervals.Length = 0) {
                step.intervals.Push(1000)
            }
            
            AppState.clickSteps.Push(step)
        }
        
        ; Ensure at least 1 step exists
        if (AppState.clickSteps.Length = 0) {
            AppState.clickSteps.Push({
                targetX: 0,
                targetY: 0,
                clickType: "Left",
                modifierKey: "None",
                intervals: [1000, 2000]
            })
        }
    }
}

SaveSettings() {
    configFile := A_ScriptDir . "\..\config\settings.ini"
    
    ; Ensure config directory exists
    configDir := A_ScriptDir . "\..\config"
    if !DirExist(configDir)
        DirCreate(configDir)
    
    ; Save number of steps
    IniWrite(AppState.clickSteps.Length, configFile, "General", "StepCount")
    
    ; Save each click step
    Loop AppState.clickSteps.Length {
        stepNum := A_Index
        step := AppState.clickSteps[stepNum]
        
        IniWrite(step.targetX, configFile, "Step" . stepNum, "X")
        IniWrite(step.targetY, configFile, "Step" . stepNum, "Y")
        IniWrite(step.modifierKey, configFile, "Step" . stepNum, "ModifierKey")
        IniWrite(step.clickType, configFile, "Step" . stepNum, "ClickType")
        
        ; Save intervals for this step
        IniWrite(step.intervals.Length, configFile, "Step" . stepNum, "IntervalCount")
        
        Loop step.intervals.Length {
            IniWrite(step.intervals[A_Index], configFile, "Step" . stepNum, "Interval" . A_Index)
        }
    }
}
