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
    targetX: 0,
    targetY: 0,
    intervals: [1000, 2000],  ; Array of intervals in milliseconds (1-3 allowed)
    isRunning: false,
    isCapturing: false,
    currentIntervalIndex: 1,  ; Track which interval we're on
    modifierKey: "None",  ; Shift, Ctrl, Alt, or None
    clickType: "Left"  ; Left or Right
}

; Global array to store interval control references
global intervalControls := []

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
    
    if FileExist(configFile) {
        AppState.targetX := IniRead(configFile, "Coordinate", "X", 0)
        AppState.targetY := IniRead(configFile, "Coordinate", "Y", 0)
        AppState.modifierKey := IniRead(configFile, "Click", "ModifierKey", "None")
        AppState.clickType := IniRead(configFile, "Click", "ClickType", "Left")
        
        ; Load intervals dynamically
        intervalCount := IniRead(configFile, "Intervals", "Count", 2)
        AppState.intervals := []
        
        Loop intervalCount {
            value := IniRead(configFile, "Intervals", "Interval" . A_Index, A_Index * 1000)
            AppState.intervals.Push(Number(value))
        }
        
        ; Ensure at least 1 interval exists
        if (AppState.intervals.Length = 0) {
            AppState.intervals.Push(1000)
        }
    }
}

SaveSettings() {
    configFile := A_ScriptDir . "\..\config\settings.ini"
    
    ; Ensure config directory exists
    configDir := A_ScriptDir . "\..\config"
    if !DirExist(configDir)
        DirCreate(configDir)
    
    IniWrite(AppState.targetX, configFile, "Coordinate", "X")
    IniWrite(AppState.targetY, configFile, "Coordinate", "Y")
    IniWrite(AppState.modifierKey, configFile, "Click", "ModifierKey")
    IniWrite(AppState.clickType, configFile, "Click", "ClickType")
    
    ; Save intervals dynamically
    IniWrite(AppState.intervals.Length, configFile, "Intervals", "Count")
    
    Loop AppState.intervals.Length {
        IniWrite(AppState.intervals[A_Index], configFile, "Intervals", "Interval" . A_Index)
    }
}
