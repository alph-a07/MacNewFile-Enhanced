//
//  MacNewFile-Swift-Bridge.h
//  MacNewFile
//

#import <Cocoa/Cocoa.h>

@interface SettingsWindowController : NSWindowController
+ (SettingsWindowController * _Nonnull)sharedController;
- (void)showSettingsWindow;
@end

@interface QuickEditorWindowController : NSWindowController
+ (QuickEditorWindowController * _Nonnull)sharedController;
- (void)openFileAtPath:(NSString * _Nonnull)path;
- (void)openFileAtURL:(NSURL * _Nonnull)url;
@end

@interface GlobalHotkeyManager : NSObject
+ (GlobalHotkeyManager * _Nonnull)sharedManager;
- (void)startMonitoring;
- (void)handleHotKeyTriggered;
- (void)registerCurrentShortcut;
@end
