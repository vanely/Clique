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
    interval1: 1000,  ; milliseconds
    interval2: 2000,  ; milliseconds
    isRunning: false,
    isCapturing: false,
    currentTimer: 1,
    modifierKey: "None"  ; Shift, Ctrl, Alt, or None
}

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
        AppState.interval1 := IniRead(configFile, "Intervals", "Interval1", 1000)
        AppState.interval2 := IniRead(configFile, "Intervals", "Interval2", 2000)
        AppState.modifierKey := IniRead(configFile, "Click", "ModifierKey", "None")
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
    IniWrite(AppState.interval1, configFile, "Intervals", "Interval1")
    IniWrite(AppState.interval2, configFile, "Intervals", "Interval2")
    IniWrite(AppState.modifierKey, configFile, "Click", "ModifierKey")
}
