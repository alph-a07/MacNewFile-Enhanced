//
//  FinderSync.m
//  MacNewFileFinderExtension
//
//  Created by Louie Yin on 2026-01-25.
//

#import "FinderSync.h"
#import <pwd.h>

static NSMutableDictionary<NSString *, NSImage *> *sIconCache = nil;

@interface FinderSync ()
@property (nonatomic, strong) NSDictionary *cachedSettings;
@property (nonatomic, strong) NSDate *settingsLastModified;
@end

@implementation FinderSync

- (instancetype)init {
    self = [super init];
    if (self) {
        // Monitor root filesystem and all mounted volumes
        [self updateDirectoryURLs];

        // Poll for volume changes every 3 seconds
        _volumeTimerSource = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());

        if (_volumeTimerSource) {
            dispatch_source_set_timer(_volumeTimerSource,
                dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                3 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);

            __weak typeof(self) weakSelf = self;
            dispatch_source_set_event_handler(_volumeTimerSource, ^{
                [weakSelf updateDirectoryURLs];
            });
            dispatch_resume(_volumeTimerSource);
        }

        // Listen for settings change notification from main app
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(onSettingsChanged:)
                                                                name:@"com.louieyin.MacNewFile.SettingsChanged"
                                                              object:nil
                                                  suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
    }
    return self;
}

- (void)dealloc {
    if (_volumeTimerSource) {
        dispatch_source_cancel(_volumeTimerSource);
        _volumeTimerSource = nil;
    }
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onSettingsChanged:(NSNotification *)notification {
    self.cachedSettings = nil;
    self.settingsLastModified = nil;
}

- (void)updateDirectoryURLs {
    NSMutableSet *urls = [NSMutableSet setWithObject:[NSURL fileURLWithPath:@"/"]];

    NSArray *volumeURLs = [[NSFileManager defaultManager]
        mountedVolumeURLsIncludingResourceValuesForKeys:nil
                                                options:NSVolumeEnumerationSkipHiddenVolumes];
    for (NSURL *volumeURL in volumeURLs) {
        [urls addObject:volumeURL];
    }

    [FIFinderSyncController defaultController].directoryURLs = urls;
}

#pragma mark - Settings Loader

- (NSString *)settingsFilePath {
    // 1. Try real user home directory (breaks out of sandbox container)
    struct passwd *pw = getpwuid(getuid());
    if (pw && pw->pw_dir) {
        NSString *realHome = [NSString stringWithUTF8String:pw->pw_dir];
        NSString *realPath = [realHome stringByAppendingPathComponent:@"Library/Application Support/MacNewFile/settings.json"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:realPath]) {
            return realPath;
        }
    }

    // 2. Try sandboxed container Application Support directory
    NSString *appSupport = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
    NSString *containerPath = [appSupport stringByAppendingPathComponent:@"MacNewFile/settings.json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:containerPath]) {
        return containerPath;
    }

    // 3. Fallback to real path
    if (pw && pw->pw_dir) {
        NSString *realHome = [NSString stringWithUTF8String:pw->pw_dir];
        return [realHome stringByAppendingPathComponent:@"Library/Application Support/MacNewFile/settings.json"];
    }

    return containerPath;
}

- (NSDictionary *)loadCurrentSettings {
    NSString *filePath = [self settingsFilePath];
    NSFileManager *fm = [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:filePath]) {
        return nil;
    }

    NSDictionary *attrs = [fm attributesOfItemAtPath:filePath error:nil];
    NSDate *modDate = attrs[NSFileModificationDate];

    if (self.cachedSettings && self.settingsLastModified && [self.settingsLastModified isEqualToDate:modDate]) {
        return self.cachedSettings;
    }

    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) return nil;

    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || ![json isKindOfClass:[NSDictionary class]]) {
        NSLog(@"[FinderSync] Error parsing settings: %@", error);
        return nil;
    }

    self.cachedSettings = json;
    self.settingsLastModified = modDate;
    return json;
}

- (NSArray<NSDictionary *> *)defaultFallbackItems {
    return @[
        @{@"id": @"txt", @"name": @"Text File", @"ext": @"txt", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"},
        @{@"id": @"md", @"name": @"Markdown Document", @"ext": @"md", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard", @"template": @"# Title\n\n"},
        @{@"id": @"py", @"name": @"Python Script", @"ext": @"py", @"category": @"Code & Web", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard", @"template": @"#!/usr/bin/env python3\n"},
        @{@"id": @"js", @"name": @"JavaScript File", @"ext": @"js", @"category": @"Code & Web", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"},
        @{@"id": @"ts", @"name": @"TypeScript File", @"ext": @"ts", @"category": @"Code & Web", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"},
        @{@"id": @"html", @"name": @"HTML Document", @"ext": @"html", @"category": @"Code & Web", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"},
        @{@"id": @"css", @"name": @"CSS Stylesheet", @"ext": @"css", @"category": @"Code & Web", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"},
        @{@"id": @"json", @"name": @"JSON File", @"ext": @"json", @"category": @"Code & Web", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"},
        @{@"id": @"yaml", @"name": @"YAML File", @"ext": @"yaml", @"category": @"Code & Web", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"},
        @{@"id": @"sh", @"name": @"Shell Script", @"ext": @"sh", @"category": @"Code & Web", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"},
        @{@"id": @"swift", @"name": @"Swift Source", @"ext": @"swift", @"category": @"Code & Web", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"},
        @{@"id": @"docx", @"name": @"Microsoft Word Document", @"ext": @"docx", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"docx"},
        @{@"id": @"xlsx", @"name": @"Microsoft Excel Spreadsheet", @"ext": @"xlsx", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"xlsx"},
        @{@"id": @"pptx", @"name": @"Microsoft PowerPoint Presentation", @"ext": @"pptx", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"pptx"},
        @{@"id": @"pages", @"name": @"Apple Pages Document", @"ext": @"pages", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"pages"},
        @{@"id": @"numbers", @"name": @"Apple Numbers Spreadsheet", @"ext": @"numbers", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"numbers"},
        @{@"id": @"key", @"name": @"Apple Keynote Presentation", @"ext": @"key", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"key"},
        @{@"id": @"csv", @"name": @"CSV Spreadsheet", @"ext": @"csv", @"category": @"Data & Config", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"},
        @{@"id": @"env", @"name": @"Environment File", @"ext": @"env", @"category": @"Data & Config", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @YES, @"creatorType": @"standard"}
    ];
}

#pragma mark - Primary Finder Sync protocol methods

- (void)beginObservingDirectoryAtURL:(NSURL *)url {}
- (void)endObservingDirectoryAtURL:(NSURL *)url {}
- (void)requestBadgeIdentifierForURL:(NSURL *)url {}

#pragma mark - Menu and toolbar item support

- (NSString *)toolbarItemName {
    return NSLocalizedString(@"New File", nil);
}

- (NSString *)toolbarItemToolTip {
    return NSLocalizedString(@"MacNewFile: Create new file or quick edit", nil);
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameAddTemplate];
}

- (BOOL)isExtensionEnabledForQuickEdit:(NSString *)ext fromSettings:(NSDictionary *)settings {
    if (!ext || ext.length == 0) return NO;
    NSArray *fileItems = settings[@"fileItems"];
    if (!fileItems) return YES;
    for (NSDictionary *item in fileItems) {
        NSString *itemExt = [item[@"ext"] lowercaseString];
        if ([itemExt isEqualToString:ext]) {
            if (item[@"enabledForQuickEditor"] != nil) {
                return [item[@"enabledForQuickEditor"] boolValue];
            }
            return YES;
        }
    }
    return NO;
}

- (NSURL *)effectiveTargetURL {
    NSArray<NSURL *> *selectedItems = [[FIFinderSyncController defaultController] selectedItemURLs];
    if (selectedItems.count == 1) {
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:selectedItems.firstObject.path isDirectory:&isDir] && isDir) {
            return selectedItems.firstObject;
        }
    }
    return [[FIFinderSyncController defaultController] targetedURL];
}

#pragma mark - High-Performance Cached SF Symbol Icons

- (NSImage *)cachedIconForExtension:(NSString *)ext creatorType:(NSString *)creatorType {
    if (!sIconCache) {
        sIconCache = [NSMutableDictionary dictionary];
    }
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", ext ?: @"", creatorType ?: @""];
    NSImage *cached = sIconCache[cacheKey];
    if (cached) return cached;

    NSImage *icon = nil;
    if (@available(macOS 11.0, *)) {
        NSString *symbol = nil;
        if ([ext isEqualToString:@"py"]) symbol = @"chevron.left.forwardslash.chevron.right";
        else if ([ext isEqualToString:@"js"] || [ext isEqualToString:@"ts"]) symbol = @"curlybraces";
        else if ([ext isEqualToString:@"html"] || [ext isEqualToString:@"css"]) symbol = @"globe";
        else if ([ext isEqualToString:@"json"] || [ext isEqualToString:@"yaml"]) symbol = @"list.bullet.rectangle";
        else if ([ext isEqualToString:@"sh"]) symbol = @"terminal";
        else if ([ext isEqualToString:@"swift"]) symbol = @"swift";
        else if ([ext isEqualToString:@"c"] || [ext isEqualToString:@"cpp"] || [ext isEqualToString:@"h"]) symbol = @"c.circle";
        else if ([ext isEqualToString:@"go"] || [ext isEqualToString:@"rs"]) symbol = @"chevron.left.forwardslash.chevron.right";
        else if ([ext isEqualToString:@"md"]) symbol = @"text.badge.star";
        else if ([ext isEqualToString:@"txt"] || [ext isEqualToString:@"rtf"]) symbol = @"doc.plaintext";
        else if ([ext isEqualToString:@"csv"] || [ext isEqualToString:@"tsv"]) symbol = @"tablecells";
        else if ([ext isEqualToString:@"env"] || [ext isEqualToString:@"ini"] || [ext isEqualToString:@"toml"]) symbol = @"slider.horizontal.3";
        else if ([ext isEqualToString:@"log"]) symbol = @"scroll";
        else if ([creatorType isEqualToString:@"docx"] || [creatorType isEqualToString:@"pages"]) symbol = @"doc.richtext";
        else if ([creatorType isEqualToString:@"xlsx"] || [creatorType isEqualToString:@"numbers"]) symbol = @"chart.bar.doc.horizontal";
        else if ([creatorType isEqualToString:@"pptx"] || [creatorType isEqualToString:@"key"]) symbol = @"play.rectangle.on.rectangle";

        if (symbol) {
            icon = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:ext];
        }
    }

    if (!icon) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        icon = [[NSWorkspace sharedWorkspace] iconForFileType:ext ?: @"txt"];
#pragma clang diagnostic pop
    }

    if (icon) {
        icon = [icon copy];
        icon.size = NSMakeSize(16, 16);
        icon.template = YES;
        sIconCache[cacheKey] = icon;
    }
    return icon;
}

- (NSMenu *)menuForMenuKind:(FIMenuKind)whichMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    NSDictionary *settings = [self loadCurrentSettings];

    BOOL includeCopyPath = YES;
    BOOL includeOpenTerminal = YES;
    BOOL showQuickEdit = YES;
    BOOL groupByCategory = NO;
    NSArray *fileItems = nil;

    if (settings) {
        if (settings[@"includeCopyPath"] != nil) includeCopyPath = [settings[@"includeCopyPath"] boolValue];
        if (settings[@"includeOpenTerminal"] != nil) includeOpenTerminal = [settings[@"includeOpenTerminal"] boolValue];
        if (settings[@"showQuickEditInMenu"] != nil) showQuickEdit = [settings[@"showQuickEditInMenu"] boolValue];
        if (settings[@"groupByCategory"] != nil) groupByCategory = [settings[@"groupByCategory"] boolValue];
        fileItems = settings[@"fileItems"];
    }

    if (!fileItems) {
        fileItems = [self defaultFallbackItems];
    }

    // Filter enabled items for New File action
    NSMutableArray<NSDictionary *> *enabledItems = [NSMutableArray array];
    for (NSDictionary *item in fileItems) {
        BOOL isEnabled = NO;
        if (item[@"enabledForNewFile"] != nil) {
            isEnabled = [item[@"enabledForNewFile"] boolValue];
        } else if (item[@"isEnabled"] != nil) {
            isEnabled = [item[@"isEnabled"] boolValue];
        }
        if (isEnabled) {
            [enabledItems addObject:item];
        }
    }

    // Check selected items in Finder
    NSArray<NSURL *> *selectedItems = [[FIFinderSyncController defaultController] selectedItemURLs];
    BOOL isSingleFileSelected = NO;
    if (selectedItems.count == 1) {
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:selectedItems.firstObject.path isDirectory:&isDir]) {
            isSingleFileSelected = !isDir;
        }
    }

    // 1. If right-clicked directly on a single file, show "Quick Edit File" if enabled
    if (whichMenu == FIMenuKindContextualMenuForItems && isSingleFileSelected && showQuickEdit) {
        NSString *ext = [selectedItems.firstObject.pathExtension lowercaseString];
        if ([self isExtensionEnabledForQuickEdit:ext fromSettings:settings]) {
            NSMenuItem *quickEditItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Edit File", nil)
                                                                   action:@selector(quickEditSelectedFile:)
                                                            keyEquivalent:@""];
            if (@available(macOS 11.0, *)) {
                NSImage *eyeImg = [NSImage imageWithSystemSymbolName:@"eye" accessibilityDescription:@"Quick Edit"];
                eyeImg.size = NSMakeSize(16, 16);
                eyeImg.template = YES;
                quickEditItem.image = eyeImg;
            }
            [menu addItem:quickEditItem];
            [menu addItem:[NSMenuItem separatorItem]];
        }
    }

    // 2. "New File" Menu (placed prominently)
    NSMenuItem *mainItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"New File", nil) action:nil keyEquivalent:@""];
    if (@available(macOS 11.0, *)) {
        NSImage *addImg = [NSImage imageWithSystemSymbolName:@"plus.circle" accessibilityDescription:@"New File"];
        addImg.size = NSMakeSize(16, 16);
        addImg.template = YES;
        mainItem.image = addImg;
    }

    NSMenu *submenu = [[NSMenu alloc] initWithTitle:@""];

    if (enabledItems.count == 0) {
        NSMenuItem *emptyItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"No file types enabled (Open Settings)", nil) action:nil keyEquivalent:@""];
        emptyItem.enabled = NO;
        [submenu addItem:emptyItem];
    } else if (groupByCategory) {
        // Group items by category into submenus
        NSMutableDictionary<NSString *, NSMutableArray<NSDictionary *> *> *categorized = [NSMutableDictionary dictionary];
        for (NSDictionary *item in enabledItems) {
            NSString *cat = item[@"category"] ?: @"General";
            if (!categorized[cat]) {
                categorized[cat] = [NSMutableArray array];
            }
            [categorized[cat] addObject:item];
        }

        NSArray *sortedCategories = [categorized.allKeys sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *cat in sortedCategories) {
            NSMenu *catSubmenu = [[NSMenu alloc] initWithTitle:@""];
            for (NSDictionary *item in categorized[cat]) {
                NSMenuItem *subItem = [self menuItemForFileItem:item];
                [catSubmenu addItem:subItem];
            }

            NSMenuItem *catMenuItem = [[NSMenuItem alloc] initWithTitle:cat action:nil keyEquivalent:@""];
            catMenuItem.submenu = catSubmenu;
            [submenu addItem:catMenuItem];
        }
    } else {
        // Flat list of enabled items
        for (NSDictionary *item in enabledItems) {
            NSMenuItem *subItem = [self menuItemForFileItem:item];
            [submenu addItem:subItem];
        }
    }

    mainItem.submenu = submenu;
    [menu addItem:mainItem];

    if (includeOpenTerminal || includeCopyPath) {
        [menu addItem:[NSMenuItem separatorItem]];
    }

    // 3. "Open Terminal" menu item
    if (includeOpenTerminal) {
        NSString *termApp = settings[@"terminalApp"] ?: @"Terminal";
        NSString *termTitle = [NSString stringWithFormat:NSLocalizedString(@"Open in %@", nil), termApp];
        NSMenuItem *openTerminalItem = [[NSMenuItem alloc] initWithTitle:termTitle
                                                                  action:@selector(openTerminalAtPath:)
                                                           keyEquivalent:@""];
        if (@available(macOS 11.0, *)) {
            NSImage *termImg = [NSImage imageWithSystemSymbolName:@"terminal" accessibilityDescription:@"Terminal"];
            termImg.size = NSMakeSize(16, 16);
            termImg.template = YES;
            openTerminalItem.image = termImg;
        }
        [menu addItem:openTerminalItem];
    }

    // 4. "Copy Path" menu item
    if (includeCopyPath) {
        NSMenuItem *copyPathItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Path", nil)
                                                              action:@selector(copyPathToClipboard:)
                                                       keyEquivalent:@""];
        if (@available(macOS 11.0, *)) {
            NSImage *copyImg = [NSImage imageWithSystemSymbolName:@"doc.on.clipboard" accessibilityDescription:@"Copy Path"];
            copyImg.size = NSMakeSize(16, 16);
            copyImg.template = YES;
            copyPathItem.image = copyImg;
        }
        [menu addItem:copyPathItem];
    }

    return menu;
}

- (NSMenuItem *)menuItemForFileItem:(NSDictionary *)item {
    NSString *name = item[@"name"] ?: [NSString stringWithFormat:@".%@ File", item[@"ext"]];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(handleCreateFileItem:) keyEquivalent:@""];
    menuItem.representedObject = item;

    NSString *ext = [item[@"ext"] lowercaseString] ?: @"txt";
    NSString *creatorType = item[@"creatorType"] ?: @"standard";
    NSImage *icon = [self cachedIconForExtension:ext creatorType:creatorType];
    if (icon) {
        menuItem.image = icon;
    }

    return menuItem;
}

#pragma mark - Actions

- (void)quickEditSelectedFile:(id)sender {
    NSArray<NSURL *> *items = [[FIFinderSyncController defaultController] selectedItemURLs];
    NSURL *targetURL = items.firstObject ?: [[FIFinderSyncController defaultController] targetedURL];

    if (!targetURL) return;

    NSString *filePath = targetURL.path;

    // 1. Post distributed notification to MacNewFile
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.louieyin.MacNewFile.QuickEditFile"
                                                                  object:nil
                                                                userInfo:@{@"path": filePath}
                                                      deliverImmediately:YES];

    // 2. Open via URL scheme fallback
    NSString *escapedPath = [filePath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:@"macnewfile://edit?path=%@", escapedPath];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (void)copyPathToClipboard:(id)sender {
    NSArray<NSURL *> *selectedItems = [[FIFinderSyncController defaultController] selectedItemURLs];
    NSURL *targetURL = (selectedItems.count > 0) ? selectedItems.firstObject : [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;

    NSString *path = targetURL.path;
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:path forType:NSPasteboardTypeString];
}

- (void)openTerminalAtPath:(id)sender {
    NSURL *targetURL = [self effectiveTargetURL];
    if (!targetURL) return;

    NSDictionary *settings = [self loadCurrentSettings];
    NSString *termApp = settings[@"terminalApp"] ?: @"Terminal";
    NSString *customPath = settings[@"terminalAppCustomPath"];

    NSString *path = targetURL.path;
    NSString *escapedPath = [path stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];

    NSString *scriptSource;
    if ([termApp isEqualToString:@"Custom"] && customPath.length > 0) {
        NSString *escapedApp = [customPath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
        scriptSource = [NSString stringWithFormat:@"do shell script \"open -a '%@' '%@'\"", escapedApp, escapedPath];
    } else {
        scriptSource = [NSString stringWithFormat:@"do shell script \"open -a '%@' '%@'\"", termApp, escapedPath];
    }

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    [script executeAndReturnError:nil];
}

- (void)handleCreateFileItem:(NSMenuItem *)sender {
    NSDictionary *item = (NSDictionary *)sender.representedObject;
    if (!item) return;

    NSString *creatorType = item[@"creatorType"] ?: @"standard";

    if ([creatorType isEqualToString:@"docx"]) {
        [self createNewWordDocument];
    } else if ([creatorType isEqualToString:@"xlsx"]) {
        [self createNewExcelDocument];
    } else if ([creatorType isEqualToString:@"pptx"]) {
        [self createNewPowerPointDocument];
    } else if ([creatorType isEqualToString:@"pages"]) {
        [self createNewPagesDocument];
    } else if ([creatorType isEqualToString:@"numbers"]) {
        [self createNewNumbersDocument];
    } else if ([creatorType isEqualToString:@"key"]) {
        [self createNewKeynoteDocument];
    } else {
        NSString *ext = item[@"ext"] ?: @"txt";
        NSString *template = item[@"template"] ?: @"";
        [self createFileWithExtension:ext templateContent:template];
    }
}

#pragma mark - Fast Native Document Creation (Zero AppleScript Overhead)

- (void)createFileWithExtension:(NSString *)extension templateContent:(NSString *)templateContent {
    NSURL *targetURL = [self effectiveTargetURL];
    if (!targetURL) {
        NSLog(@"[FinderSync] Cannot create file: effectiveTargetURL is nil");
        return;
    }

    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseName, extension]];

    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        NSString *fileName = [NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension];
        filePath = [targetURL.path stringByAppendingPathComponent:fileName];
        counter++;
    }

    NSData *data = [templateContent dataUsingEncoding:NSUTF8StringEncoding] ?: [NSData data];
    NSError *error = nil;
    BOOL success = [data writeToFile:filePath options:NSDataWritingAtomic error:&error];

    if (!success) {
        NSLog(@"[FinderSync] Direct write failed: %@, requesting main app helper", error);
        [self requestMainAppToCreateFileAtPath:filePath content:templateContent templatePath:nil];
        return;
    }

    // Reveal and select new file in Finder
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
}

- (void)createNewWordDocument {
    [self copyBundleTemplateNamed:@"Blank.docx" extension:@"docx"];
}

- (void)createNewExcelDocument {
    [self copyBundleTemplateNamed:@"Blank.xlsx" extension:@"xlsx"];
}

- (void)createNewPowerPointDocument {
    [self copyBundleTemplateNamed:@"Blank.pptx" extension:@"pptx"];
}

- (void)createNewPagesDocument {
    [self copyBundleTemplateNamed:@"Blank.pages" extension:@"pages"];
}

- (void)createNewNumbersDocument {
    [self copyBundleTemplateNamed:@"Blank.numbers" extension:@"numbers"];
}

- (void)createNewKeynoteDocument {
    [self copyBundleTemplateNamed:@"Blank.key" extension:@"key"];
}

- (void)copyBundleTemplateNamed:(NSString *)templateName extension:(NSString *)extension {
    NSURL *targetURL = [self effectiveTargetURL];
    if (!targetURL) return;

    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseName, extension]];

    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        NSString *fileName = [NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension];
        filePath = [targetURL.path stringByAppendingPathComponent:fileName];
        counter++;
    }

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *templatePath = [bundle pathForResource:[templateName stringByDeletingPathExtension] ofType:[templateName pathExtension]];

    if (!templatePath) {
        NSLog(@"[FinderSync] Failed to find %@ template in bundle", templateName);
        return;
    }

    NSError *error = nil;
    BOOL success = [fm copyItemAtPath:templatePath toPath:filePath error:&error];
    if (!success) {
        NSLog(@"[FinderSync] Copy template failed: %@, requesting main app helper", error);
        [self requestMainAppToCreateFileAtPath:filePath content:nil templatePath:templatePath];
        return;
    }

    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
}

- (void)requestMainAppToCreateFileAtPath:(NSString *)filePath content:(NSString *)content templatePath:(NSString *)templatePath {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (filePath) userInfo[@"filePath"] = filePath;
    if (content) userInfo[@"content"] = content;
    if (templatePath) userInfo[@"templatePath"] = templatePath;

    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.louieyin.MacNewFile.CreateFileRequest"
                                                                  object:nil
                                                                userInfo:userInfo
                                                      deliverImmediately:YES];
}

@end
