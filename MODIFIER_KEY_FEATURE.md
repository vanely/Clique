# Modifier Key Feature - Update

## ✨ New Feature Added: Modifier Key Support

### What's New?

You can now press a keyboard modifier key (Shift, Ctrl, or Alt) simultaneously with each click!

### How to Use

1. **Launch the tool** - Use `./run.sh` or `DesktopAutomationTool.bat`

2. **Select Modifier Key** - In the GUI, you'll see a new dropdown labeled "Modifier Key"
   - Options: **None**, **Shift**, **Ctrl**, **Alt**
   - Default: **None** (regular click)

3. **Set your other options** as usual:
   - Capture coordinate (F3)
   - Set intervals
   - Select modifier key from dropdown

4. **Test it** - Use the "Test Click" button to verify the modifier key works

5. **Start automation** (F1) - Each click will now include the selected modifier key

6. **Save Settings** - Your modifier key preference will be saved between sessions

---

## 🎯 Use Cases

### Shift + Click
- Select multiple items in file explorers
- Extend selections in text editors
- Multi-select in applications

### Ctrl + Click
- Open links in new tabs
- Add to selection without clearing previous
- Context-specific actions in apps

### Alt + Click
- Grab and move windows (some window managers)
- Alternative click actions
- Application-specific shortcuts

---

## 🔧 Technical Changes

### Modified Files:

1. **main.ahk**
   - Added `modifierKey` to AppState
   - Added modifier key to LoadSettings()
   - Added modifier key to SaveSettings()

2. **gui.ahk**
   - Added Modifier Key dropdown in Click Settings section
   - Updated GUI layout (slightly taller window)
   - Added modifier to SaveCurrentSettings()
   - Added modifier to TestClick()
   - Added modifier dropdown to UpdateGUIState()

3. **automation.ahk**
   - Added `PerformModifierClick(x, y, modifier)` function
   - Updated PerformClick() to use modifier key
   - Updated StartAutomation() to read modifier from GUI
   - Modifier keys properly pressed/released with each click

4. **config/settings.ini**
   - Added new `[Click]` section with `ModifierKey` setting

---

## 📝 Settings File Format

```ini
[Click]
ModifierKey=None    ; Options: None, Shift, Ctrl, Alt
```

Your settings are automatically saved and loaded between sessions.

---

## 🎮 Controls (Unchanged)

- **F3** - Capture coordinate
- **F1** - Start automation
- **F2** - Stop automation  
- **ESC** - Emergency stop

---

## ✅ Testing Checklist

- [x] Dropdown appears in GUI
- [x] All 4 options work (None, Shift, Ctrl, Alt)
- [x] Test Click uses modifier key
- [x] Automation uses modifier key
- [x] Modifier key saves to config
- [x] Modifier key loads from config
- [x] No linting errors
- [x] GUI properly sized

---

## 🚀 Try It Now!

1. Run the app: `./run.sh`
2. Select "Shift" from the Modifier Key dropdown
3. Capture a coordinate
4. Click "Test Click" - you'll see Shift+Click happen!
5. Start automation - every click will include Shift

---

**Last Updated**: February 6, 2026  
**Version**: 1.3 (Modifier Key Support)
