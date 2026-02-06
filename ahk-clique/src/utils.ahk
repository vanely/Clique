;==============================================================================
; Utility Functions Module
; Helper functions and utilities
;==============================================================================

;==============================================================================
; Integer Conversion Helper
; Note: Using built-in Number() function instead of custom Integer()
; to avoid conflict with AutoHotkey v2's Integer class
;==============================================================================

;==============================================================================
; Format Time Helper
;==============================================================================
FormatMilliseconds(ms) {
    if (ms < 1000) {
        return ms . "ms"
    }
    seconds := ms / 1000
    return Round(seconds, 2) . "s"
}

;==============================================================================
; Safe File Operations
;==============================================================================
SafeFileRead(filePath, defaultValue := "") {
    try {
        return FileRead(filePath)
    } catch {
        return defaultValue
    }
}

SafeFileWrite(filePath, content) {
    try {
        FileAppend(content, filePath)
        return true
    } catch {
        return false
    }
}

;==============================================================================
; Logging Functionality
;==============================================================================
LogMessage(message, level := "INFO") {
    logFile := A_ScriptDir . "\..\logs\automation.log"
    logDir := A_ScriptDir . "\..\logs"
    
    ; Create logs directory if it doesn't exist
    if !DirExist(logDir)
        DirCreate(logDir)
    
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    logEntry := "[" . timestamp . "] [" . level . "] " . message . "`n"
    
    try {
        FileAppend(logEntry, logFile)
    } catch {
        ; Silent fail for logging
    }
}

;==============================================================================
; Debug Output
;==============================================================================
DebugOutput(message) {
    if (A_IsCompiled = 0) {  ; Only in development
        OutputDebug(message)
    }
}

;==============================================================================
; Screen Bounds Validation
;==============================================================================
IsValidScreenCoordinate(x, y) {
    ; Get virtual screen dimensions
    vScreenX := SysGet(76)       ; SM_XVIRTUALSCREEN
    vScreenY := SysGet(77)       ; SM_YVIRTUALSCREEN
    vScreenWidth := SysGet(78)   ; SM_CXVIRTUALSCREEN
    vScreenHeight := SysGet(79)  ; SM_CYVIRTUALSCREEN
    
    if (x < vScreenX || x > (vScreenX + vScreenWidth))
        return false
    if (y < vScreenY || y > (vScreenY + vScreenHeight))
        return false
    
    return true
}

;==============================================================================
; Get Monitor Info for Coordinate
;==============================================================================
GetMonitorFromCoordinate(x, y) {
    MonitorCount := MonitorGetCount()
    
    Loop MonitorCount {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
        
        if (x >= mLeft && x <= mRight && y >= mTop && y <= mBottom) {
            return {
                index: A_Index,
                left: mLeft,
                top: mTop,
                right: mRight,
                bottom: mBottom,
                width: mRight - mLeft,
                height: mBottom - mTop
            }
        }
    }
    
    return ""
}

;==============================================================================
; Color Helpers
;==============================================================================
RGBToHex(r, g, b) {
    return Format("0x{:02X}{:02X}{:02X}", r, g, b)
}

HexToRGB(hexColor) {
    r := (hexColor >> 16) & 0xFF
    g := (hexColor >> 8) & 0xFF
    b := hexColor & 0xFF
    return {r: r, g: g, b: b}
}

;==============================================================================
; Validation Helpers
;==============================================================================
IsPositiveInteger(value) {
    try {
        num := Number(value)
        return (num > 0 && num = Floor(num))
    } catch {
        return false
    }
}

ValidateInterval(interval, minValue := 100) {
    if (!IsPositiveInteger(interval))
        return false
    
    return (Number(interval) >= minValue)
}

;==============================================================================
; System Information
;==============================================================================
GetSystemInfo() {
    return {
        os: A_OSVersion,
        is64Bit: A_Is64bitOS,
        screenWidth: A_ScreenWidth,
        screenHeight: A_ScreenHeight,
        monitors: MonitorGetCount(),
        ahkVersion: A_AhkVersion
    }
}
