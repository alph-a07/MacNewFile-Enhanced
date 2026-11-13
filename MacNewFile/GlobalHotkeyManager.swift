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

        // In Cocoa, GetEventDispatcherTarget() receives carbon hotkeys reliably
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
        // Query Finder for currently selected file
        if let selectedPath = getFinderSelectedFilePath() {
            QuickEditorWindowController.shared.openFile(atPath: selectedPath)
        } else {
            // Open editor with new draft buffer if no specific file selected
            QuickEditorWindowController.shared.openNewDraft()
        }
    }

    @objc private func handleQuickEditDistributedNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let path = userInfo["path"] as? String else {
            return
        }
        QuickEditorWindowController.shared.openFile(atPath: path)
    }

    public func getFinderSelectedFilePath() -> String? {
        let scriptSource = """
        tell application "Finder"
            set sel to selection as alias list
            if (count of sel) > 0 then
                return POSIX path of (item 1 of sel)
            end if
        end tell
        """

        var errorDict: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            let result = script.executeAndReturnError(&errorDict)
            if let stringValue = result.stringValue, !stringValue.isEmpty {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: stringValue, isDirectory: &isDir) {
                    if !isDir.boolValue {
                        return stringValue
                    }
                }
            }
        }
        return nil
    }
}
