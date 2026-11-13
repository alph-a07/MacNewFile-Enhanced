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
    NSLog(@"[MacNewFile] applicationDidFinishLaunching started");

    // Enable the Finder extension asynchronously so it never blocks the main UI thread
    [self setExtensionEnabled:YES];

    // Create menu bar icon first so it appears immediately
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    NSImage *icon = [NSImage imageNamed:@"add"];
    if (!icon) {
        if (@available(macOS 11.0, *)) {
            icon = [NSImage imageWithSystemSymbolName:@"plus" accessibilityDescription:@"MacNewFile"];
        }
    }

    if (icon) {
        icon.size = NSMakeSize(18, 18);
        icon.template = YES;
        self.statusItem.button.image = icon;
    } else {
        self.statusItem.button.title = NSLocalizedString(@"NF", nil);
    }

    [self updateStatusMenu];
    NSLog(@"[MacNewFile] Status item created successfully");

    // Initialize global hotkey and event monitoring
    @try {
        [[GlobalHotkeyManager sharedManager] startMonitoring];
        NSLog(@"[MacNewFile] Global hotkey monitoring started");
    } @catch (NSException *e) {
        NSLog(@"[MacNewFile] Error starting hotkey monitoring: %@", e);
    }

    // Register URL scheme handler for macnewfile://
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];

    // Register distributed notification for file creation helper from sandboxed extension
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(handleCreateFileRequest:)
                                                            name:@"com.louieyin.MacNewFile.CreateFileRequest"
                                                          object:nil
                                              suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    // Register application in Login Items as a background app
    if (@available(macOS 13.0, *)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            SMAppService *service = [SMAppService mainAppService];
            if (service.status != SMAppServiceStatusEnabled) {
                NSError *error = nil;
                [service registerAndReturnError:&error];
                if (error) {
                    NSLog(@"[MacNewFile] Notice: Login item register: %@", error.localizedDescription);
                }
            }
        });
    }
}

- (void)updateStatusMenu {
    NSMenu *menu = [[NSMenu alloc] init];

    // Quick Edit selection
    NSMenuItem *quickEditItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Edit Selection", nil)
                                                           action:@selector(triggerQuickEdit:)
                                                    keyEquivalent:@" "];
    quickEditItem.keyEquivalentModifierMask = NSEventModifierFlagOption;
    if (@available(macOS 11.0, *)) {
        quickEditItem.image = [NSImage imageWithSystemSymbolName:@"eye" accessibilityDescription:nil];
    }
    [menu addItem:quickEditItem];

    // Open file in editor
    NSMenuItem *openFileItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open in Quick Editor...", nil)
                                                          action:@selector(openFileInEditor:)
                                                   keyEquivalent:@"o"];
    openFileItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    if (@available(macOS 11.0, *)) {
        openFileItem.image = [NSImage imageWithSystemSymbolName:@"doc.text" accessibilityDescription:nil];
    }
    [menu addItem:openFileItem];

    [menu addItem:[NSMenuItem separatorItem]];

    // Settings
    NSMenuItem *settingsItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Settings...", nil)
                                                          action:@selector(openSettings:)
                                                   keyEquivalent:@","];
    settingsItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    if (@available(macOS 11.0, *)) {
        settingsItem.image = [NSImage imageWithSystemSymbolName:@"gearshape" accessibilityDescription:nil];
    }
    [menu addItem:settingsItem];

    // Restart extension
    NSMenuItem *restartExtItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Restart Finder Extension", nil)
                                                            action:@selector(restartFinderExtension:)
                                                     keyEquivalent:@""];
    if (@available(macOS 11.0, *)) {
        restartExtItem.image = [NSImage imageWithSystemSymbolName:@"arrow.clockwise" accessibilityDescription:nil];
    }
    [menu addItem:restartExtItem];

    [menu addItem:[NSMenuItem separatorItem]];

    // Quit
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quit MacNewFile", nil)
                                                      action:@selector(terminate:)
                                               keyEquivalent:@"q"];
    quitItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    if (@available(macOS 11.0, *)) {
        quitItem.image = [NSImage imageWithSystemSymbolName:@"power" accessibilityDescription:nil];
    }
    [menu addItem:quitItem];

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

    if ([url.host isEqualToString:@"settings"] || [url.path isEqualToString:@"/settings"]) {
        [self openSettings:nil];
        return;
    }

    // Handles macnewfile://open?path=/path/to/file or macnewfile://edit?path=/path/to/file
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"path"] && item.value) {
            [[QuickEditorWindowController sharedController] openFileAtPath:item.value];
            break;
        }
    }
}

- (void)handleCreateFileRequest:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *filePath = userInfo[@"filePath"];
    NSString *content = userInfo[@"content"] ?: @"";
    NSString *templatePath = userInfo[@"templatePath"];

    if (!filePath) return;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;

    if (templatePath.length > 0 && [fm fileExistsAtPath:templatePath]) {
        [fm copyItemAtPath:templatePath toPath:filePath error:&error];
    } else {
        NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding] ?: [NSData data];
        [data writeToFile:filePath options:NSDataWritingAtomic error:&error];
    }

    if (!error) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    } else {
        NSLog(@"[MacNewFile] Main app createFile error: %@", error);
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Disable the Finder extension when app quits
    [self setExtensionEnabled:NO];
}

- (void)setExtensionEnabled:(BOOL)enabled {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
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
            NSLog(@"[MacNewFile] pluginkit setExtensionEnabled:%@ finished with code %d", enabled ? @"YES" : @"NO", task.terminationStatus);
        } @catch (NSException *e) {
            NSLog(@"[MacNewFile] pluginkit error: %@", e);
        }
    });
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
