import Cocoa
import SwiftUI

@objc(SettingsWindowController)
public class SettingsWindowController: NSWindowController {
    @objc(sharedController)
    public static let shared = SettingsWindowController()

    private init() {
        let hostingView = NSHostingView(rootView: SettingsView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "MacNewFile Settings"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc public func showSettingsWindow() {
        if window == nil {
            let hostingView = NSHostingView(rootView: SettingsView())
            let newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 680, height: 520),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            newWindow.center()
            newWindow.title = "MacNewFile Settings"
            newWindow.contentView = hostingView
            newWindow.isReleasedWhenClosed = false
            self.window = newWindow
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
