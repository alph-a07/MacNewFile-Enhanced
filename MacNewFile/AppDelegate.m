//
//  AppDelegate.m
//  MacNewFile
//
//  Created by Louie Yin on 2026-01-25.
//

#import "AppDelegate.h"
#import "MacNewFile-Swift-Bridge.h"
#import <ServiceManagement/ServiceManagement.h>

@interface AppDelegate ()
@property (strong) NSStatusItem *statusItem;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Enable the Finder extension
    [self setExtensionEnabled:YES];

    // Initialize global hotkey and event monitoring
    [[GlobalHotkeyManager sharedManager] startMonitoring];

    // Register URL scheme handler for macnewfile://
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];

    // Create menu bar icon
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

    NSImage *icon = [NSImage imageNamed:@"add"];
    if (icon) {
        icon.size = NSMakeSize(18, 18);
        icon.template = YES;
        self.statusItem.button.image = icon;
    } else {
        self.statusItem.button.title = NSLocalizedString(@"NF", nil);  // Fallback to text
    }

    [self updateStatusMenu];

    // Register application in Login Items as a background app
    if (@available(macOS 13.0, *)) {
        SMAppService *service = [SMAppService mainAppService];
        if (service.status != SMAppServiceStatusEnabled) {
            NSError *error = nil;
            [service registerAndReturnError:&error];
            if (error) {
                NSLog(@"Failed to add to login items: %@", error);
            }
        }
    }
}

- (void)updateStatusMenu {
    NSMenu *menu = [[NSMenu alloc] init];

    // Header title
    NSMenuItem *statusHeader = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"MacNewFile Enhanced", nil) action:nil keyEquivalent:@""];
    [menu addItem:statusHeader];

    [menu addItem:[NSMenuItem separatorItem]];

    // Quick Edit selection
    NSMenuItem *quickEditItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Edit Selection (⌥Space)", nil)
                                                           action:@selector(triggerQuickEdit:)
                                                    keyEquivalent:@""];
    [menu addItem:quickEditItem];

    // Open file in editor
    NSMenuItem *openFileItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open File in Quick Editor...", nil)
                                                          action:@selector(openFileInEditor:)
                                                   keyEquivalent:@"o"];
    openFileItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [menu addItem:openFileItem];

    [menu addItem:[NSMenuItem separatorItem]];

    // Settings
    NSMenuItem *settingsItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Settings...", nil)
                                                          action:@selector(openSettings:)
                                                   keyEquivalent:@","];
    settingsItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [menu addItem:settingsItem];

    // Restart extension
    NSMenuItem *restartExtItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Restart Finder Extension", nil)
                                                            action:@selector(restartFinderExtension:)
                                                     keyEquivalent:@""];
    [menu addItem:restartExtItem];

    [menu addItem:[NSMenuItem separatorItem]];

    // Quit
    [menu addItemWithTitle:NSLocalizedString(@"Quit MacNewFile", nil) action:@selector(terminate:) keyEquivalent:@"q"];

    self.statusItem.menu = menu;
}

- (void)triggerQuickEdit:(id)sender {
    [[GlobalHotkeyManager sharedManager] handleHotKeyTriggered];
}

- (void)openFileInEditor:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;

    [NSApp activateIgnoringOtherApps:YES];
    if ([panel runModal] == NSModalResponseOK) {
        NSURL *url = panel.URL;
        if (url) {
            [[QuickEditorWindowController sharedController] openFileAtPath:url.path];
        }
    }
}

- (void)openSettings:(id)sender {
    [[SettingsWindowController sharedController] showSettingsWindow];
}

- (void)restartFinderExtension:(id)sender {
    [self setExtensionEnabled:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setExtensionEnabled:YES];
    });
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    if (!urlString) return;

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;

    // Handles macnewfile://open?path=/path/to/file or macnewfile://edit?path=/path/to/file
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"path"] && item.value) {
            [[QuickEditorWindowController sharedController] openFileAtPath:item.value];
            break;
        }
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Disable the Finder extension when app quits
    [self setExtensionEnabled:NO];
}

- (void)setExtensionEnabled:(BOOL)enabled {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/pluginkit";
    task.arguments = @[
        @"-e",
        enabled ? @"use" : @"ignore",
        @"-i",
        @"com.louieyin.MacNewFile.MacNewFileFinderExtension"
    ];
    [task launch];
    [task waitUntilExit];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
