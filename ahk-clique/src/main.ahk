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
    clickSteps: [],           ; Array of ClickStep objects
    currentStepIndex: 1,      ; Which step is currently executing (1-based)
    currentIntervalIndex: 1,  ; Which interval in current step (1-based)
    isRunning: false,
    isCapturing: false,
    activeTabIndex: 1         ; Which tab is currently visible (1-based)
}

;==============================================================================
; Initialize with one default ClickStep
;==============================================================================
InitializeDefaultStep() {
    AppState.clickSteps := []
    AppState.clickSteps.Push({
        targetX: 0,
        targetY: 0,
        modifierKey: "None",
        intervals: [1000, 2000]  ; Default two intervals
    })
}

;==============================================================================
; Initialization
;==============================================================================
Main()

Main() {
    ; Initialize default click step
    InitializeDefaultStep()
    
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
    
    ; F3 - Capture coordinate
    Hotkey("F3", (*) => StartCoordinateCapture())
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
    
    if !FileExist(configFile) {
        return
    }
    
    ; Read number of steps
    stepCount := IniRead(configFile, "General", "StepCount", 1)
    
    ; Clear and reload steps
    AppState.clickSteps := []
    
    Loop stepCount {
        stepNum := A_Index
        sectionName := "ClickStep" . stepNum
        
        ; Read step data
        x := IniRead(configFile, sectionName, "X", 0)
        y := IniRead(configFile, sectionName, "Y", 0)
        modifier := IniRead(configFile, sectionName, "ModifierKey", "None")
        intervalsStr := IniRead(configFile, sectionName, "Intervals", "1000,2000")
        
        ; Parse intervals (comma-separated)
        intervals := []
        Loop Parse, intervalsStr, ","
        {
            if (A_LoopField != "" && Number(A_LoopField) > 0)
                intervals.Push(Number(A_LoopField))
        }
        
        ; Ensure at least one interval
        if (intervals.Length = 0)
            intervals.Push(1000)
        
        ; Add step to state
        AppState.clickSteps.Push({
            targetX: Number(x),
            targetY: Number(y),
            modifierKey: modifier,
            intervals: intervals
        })
    }
}

SaveSettings() {
    configFile := A_ScriptDir . "\..\config\settings.ini"
    
    ; Ensure config directory exists
    configDir := A_ScriptDir . "\..\config"
    if !DirExist(configDir)
        DirCreate(configDir)
    
    ; Delete old file and start fresh
    if FileExist(configFile)
        FileDelete(configFile)
    
    ; Write step count
    IniWrite(AppState.clickSteps.Length, configFile, "General", "StepCount")
    
    ; Write each step
    for index, step in AppState.clickSteps {
        sectionName := "ClickStep" . index
        
        IniWrite(step.targetX, configFile, sectionName, "X")
        IniWrite(step.targetY, configFile, sectionName, "Y")
        IniWrite(step.modifierKey, configFile, sectionName, "ModifierKey")
        
        ; Convert intervals array to comma-separated string
        intervalsStr := ""
        for idx, interval in step.intervals {
            intervalsStr .= interval
            if (idx < step.intervals.Length)
                intervalsStr .= ","
        }
        IniWrite(intervalsStr, configFile, sectionName, "Intervals")
    }
}
