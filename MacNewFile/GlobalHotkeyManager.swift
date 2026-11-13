import Cocoa
import Carbon

@objc(GlobalHotkeyManager)
public class GlobalHotkeyManager: NSObject {
    @objc(sharedManager)
    public static let shared = GlobalHotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var globalMonitor: Any?

    private override init() {
        super.init()
    }

    @objc public func startMonitoring() {
        registerCurrentShortcut()

        // Also listen for distributed notifications from Finder Extension
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleQuickEditDistributedNotification(_:)),
            name: NSNotification.Name("com.louieyin.MacNewFile.QuickEditFile"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )

        // Secondary fallback monitor for keydown events
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.checkKeyEvent(event)
        }
    }

    private func checkKeyEvent(_ event: NSEvent) {
        let shortcut = SettingsManager.shared.settings.quickEditorShortcut
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if shortcut == "Option+Space" && flags == .option && event.keyCode == 49 {
            DispatchQueue.main.async { [weak self] in
                self?.handleHotKeyTriggered()
            }
        } else if shortcut == "Cmd+Shift+E" && flags == [.command, .shift] && event.keyCode == 14 {
            DispatchQueue.main.async { [weak self] in
                self?.handleHotKeyTriggered()
            }
        } else if shortcut == "Ctrl+Opt+N" && flags == [.control, .option] && event.keyCode == 45 {
            DispatchQueue.main.async { [weak self] in
                self?.handleHotKeyTriggered()
            }
        } else if shortcut == "Cmd+Opt+E" && flags == [.command, .option] && event.keyCode == 14 {
            DispatchQueue.main.async { [weak self] in
                self?.handleHotKeyTriggered()
            }
        }
    }

    @objc public func registerCurrentShortcut() {
        unregisterHotKey()

        let shortcut = SettingsManager.shared.settings.quickEditorShortcut
        var keyCode: UInt32 = 49 // Space by default
        var modifiers: UInt32 = UInt32(optionKey) // Option by default

        switch shortcut {
        case "Cmd+Shift+E":
            keyCode = 14 // 'E' key
            modifiers = UInt32(cmdKey | shiftKey)
        case "Ctrl+Opt+N":
            keyCode = 45 // 'N' key
            modifiers = UInt32(controlKey | optionKey)
        case "Cmd+Opt+E":
            keyCode = 14 // 'E' key
            modifiers = UInt32(cmdKey | optionKey)
        case "Option+Space":
            fallthrough
        default:
            keyCode = 49 // Space
            modifiers = UInt32(optionKey)
        }

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4D4E4645) // 'MNFE'
        hotKeyID.id = 1

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let target = GetEventDispatcherTarget()

        InstallEventHandler(target, { (nextHandler, event, userData) -> OSStatus in
            DispatchQueue.main.async {
                GlobalHotkeyManager.shared.handleHotKeyTriggered()
            }
            return noErr
        }, 1, &eventType, nil, &eventHandler)

        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, target, 0, &hotKeyRef)
        if status != noErr {
            NSLog("[MacNewFile] Notice: Carbon RegisterEventHotKey status %d for %@", status, shortcut)
        } else {
            NSLog("[MacNewFile] Successfully registered global hotkey: %@", shortcut)
        }
    }

    @objc public func unregisterHotKey() {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    @objc public func handleHotKeyTriggered() {
        let editor = QuickEditorWindowController.shared
        let isVisible = editor.window?.isVisible ?? false
        let eligiblePaths = getEligibleFinderSelectedPaths()

        if isVisible {
            // 1. If currently open: repeating shortcut on the same selection closes it!
            let currentPaths = editor.documents.map { $0.fileURL.path }
            if eligiblePaths.isEmpty || eligiblePaths == currentPaths {
                editor.closeWindow()
                return
            }

            // 2. Different selection: open the new items in multi-tab
            editor.openFiles(at: eligiblePaths)
            return
        }

        // 3. Not open: only open if there are eligible, supported & enabled items selected
        if !eligiblePaths.isEmpty {
            editor.openFiles(at: eligiblePaths)
        } else {
            NSSound.beep()
        }
    }

    @objc private func handleQuickEditDistributedNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let path = userInfo["path"] as? String else {
            return
        }
        QuickEditorWindowController.shared.openFile(atPath: path)
    }

    public func getFinderSelectedFilePaths() -> [String] {
        let scriptSource = """
        tell application "Finder"
            set sel to selection as alias list
            set outList to {}
            repeat with itemRef in sel
                set end of outList to POSIX path of itemRef
            end repeat
            set AppleScript's text item delimiters to linefeed
            return outList as text
        end tell
        """

        var errorDict: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            let result = script.executeAndReturnError(&errorDict)
            if let stringValue = result.stringValue, !stringValue.isEmpty {
                let lines = stringValue.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                return lines
            }
        }
        return []
    }

    public func getEligibleFinderSelectedPaths() -> [String] {
        let paths = getFinderSelectedFilePaths()
        return paths.filter { path in
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue else {
                return false
            }

            let url = URL(fileURLWithPath: path)
            var ext = url.pathExtension.lowercased()

            if ext.isEmpty {
                let name = url.lastPathComponent.lowercased()
                if name.hasPrefix(".") {
                    let sub = String(name.dropFirst())
                    if sub == "env" || sub.hasPrefix("env.") {
                        ext = "env"
                    } else if sub.contains("zsh") || sub.contains("bash") || sub == "profile" {
                        ext = "sh"
                    } else {
                        ext = "txt"
                    }
                } else if name == "license" || name == "readme" || name == "makefile" || name == "dockerfile" {
                    ext = "txt"
                }
            } else {
                if ext == "tsx" { ext = "ts" }
                else if ext == "jsx" { ext = "js" }
                else if ext == "zsh" || ext == "bash" { ext = "sh" }
                else if ext == "conf" { ext = "ini" }
            }

            return SettingsManager.shared.isExtensionEnabledForQuickEditor(ext: ext)
        }
    }
}
