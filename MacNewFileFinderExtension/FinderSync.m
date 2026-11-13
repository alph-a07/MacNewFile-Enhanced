//
//  FinderSync.m
//  MacNewFileFinderExtension
//
//  Created by Louie Yin on 2026-01-25.
//

#import "FinderSync.h"

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
    NSString *appSupport = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
    return [appSupport stringByAppendingPathComponent:@"MacNewFile/settings.json"];
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
        @{@"id": @"docx", @"name": @"Microsoft Word Document", @"ext": @"docx", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"docx"},
        @{@"id": @"xlsx", @"name": @"Microsoft Excel Spreadsheet", @"ext": @"xlsx", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"xlsx"},
        @{@"id": @"pptx", @"name": @"Microsoft PowerPoint Presentation", @"ext": @"pptx", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"pptx"},
        @{@"id": @"pages", @"name": @"Apple Pages Document", @"ext": @"pages", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"pages"},
        @{@"id": @"numbers", @"name": @"Apple Numbers Spreadsheet", @"ext": @"numbers", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"numbers"},
        @{@"id": @"key", @"name": @"Apple Keynote Presentation", @"ext": @"key", @"category": @"Documents & Notes", @"enabledForNewFile": @YES, @"enabledForQuickEditor": @NO, @"creatorType": @"key"}
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
                quickEditItem.image = [NSImage imageWithSystemSymbolName:@"eye" accessibilityDescription:@"Quick Edit"];
            } else {
                quickEditItem.image = [NSImage imageNamed:@"edit"];
            }
            [menu addItem:quickEditItem];
            [menu addItem:[NSMenuItem separatorItem]];
        }
    }

    // 2. "New File" Menu (placed prominently)
    NSMenuItem *mainItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"New File", nil) action:nil keyEquivalent:@""];
    if (@available(macOS 11.0, *)) {
        mainItem.image = [NSImage imageWithSystemSymbolName:@"plus.circle" accessibilityDescription:@"New File"];
    } else {
        mainItem.image = [NSImage imageNamed:@"add"];
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
            openTerminalItem.image = [NSImage imageWithSystemSymbolName:@"terminal" accessibilityDescription:@"Terminal"];
        } else {
            openTerminalItem.image = [NSImage imageNamed:@"terminal"];
        }
        [menu addItem:openTerminalItem];
    }

    // 4. "Copy Path" menu item
    if (includeCopyPath) {
        NSMenuItem *copyPathItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Path", nil)
                                                              action:@selector(copyPathToClipboard:)
                                                       keyEquivalent:@""];
        if (@available(macOS 11.0, *)) {
            copyPathItem.image = [NSImage imageWithSystemSymbolName:@"doc.on.clipboard" accessibilityDescription:@"Copy Path"];
        } else {
            copyPathItem.image = [NSImage imageNamed:@"copy"];
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType:ext];
#pragma clang diagnostic pop
    if (icon) {
        icon.size = NSMakeSize(16, 16);
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
    NSURL *targetURL = nil;
    NSArray<NSURL *> *selectedItems = [[FIFinderSyncController defaultController] selectedItemURLs];
    if (selectedItems.count == 1) {
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:selectedItems.firstObject.path isDirectory:&isDir] && isDir) {
            targetURL = selectedItems.firstObject;
        }
    }
    if (!targetURL) {
        targetURL = [[FIFinderSyncController defaultController] targetedURL];
    }
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

#pragma mark - Document Generators

- (void)createFileWithExtension:(NSString *)extension templateContent:(NSString *)templateContent {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
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

    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];

    NSString *scriptSource;
    if (templateContent.length > 0) {
        // Base64 encode template to safely pass through shell and preserve special characters/newlines
        NSData *templateData = [templateContent dataUsingEncoding:NSUTF8StringEncoding];
        NSString *base64Template = [templateData base64EncodedStringWithOptions:0];
        scriptSource = [NSString stringWithFormat:@"do shell script \"echo '%@' | base64 -d > '%@'\"", base64Template, escapedPath];
    } else {
        scriptSource = [NSString stringWithFormat:@"do shell script \"touch '%@'\"", escapedPath];
    }

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (!errorDict) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    }
}

- (void)createNewWordDocument {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;

    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *extension = @"docx";
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseName, extension]];

    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        NSString *fileName = [NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension];
        filePath = [targetURL.path stringByAppendingPathComponent:fileName];
        counter++;
    }

    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:
        @"do shell script \""
        "TMPDIR=$(mktemp -d) && "
        "mkdir -p \\\"$TMPDIR/_rels\\\" \\\"$TMPDIR/word/_rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Types xmlns=\\\"http://schemas.openxmlformats.org/package/2006/content-types\\\"><Default Extension=\\\"rels\\\" ContentType=\\\"application/vnd.openxmlformats-package.relationships+xml\\\"/><Default Extension=\\\"xml\\\" ContentType=\\\"application/xml\\\"/><Override PartName=\\\"/word/document.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\\\"/><Override PartName=\\\"/word/styles.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml\\\"/></Types>' > \\\"$TMPDIR/[Content_Types].xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\\\" Target=\\\"word/document.xml\\\"/></Relationships>' > \\\"$TMPDIR/_rels/.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\\\" Target=\\\"styles.xml\\\"/></Relationships>' > \\\"$TMPDIR/word/_rels/document.xml.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><w:styles xmlns:w=\\\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\\\"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii=\\\"Calibri\\\" w:hAnsi=\\\"Calibri\\\" w:cs=\\\"Calibri\\\"/><w:sz w:val=\\\"22\\\"/><w:szCs w:val=\\\"22\\\"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after=\\\"0\\\" w:line=\\\"276\\\" w:lineRule=\\\"auto\\\"/></w:pPr></w:pPrDefault></w:docDefaults><w:style w:type=\\\"paragraph\\\" w:default=\\\"1\\\" w:styleId=\\\"Normal\\\"><w:name w:val=\\\"Normal\\\"/><w:rPr><w:rFonts w:ascii=\\\"Calibri\\\" w:hAnsi=\\\"Calibri\\\" w:cs=\\\"Calibri\\\"/><w:sz w:val=\\\"22\\\"/><w:szCs w:val=\\\"22\\\"/></w:rPr></w:style></w:styles>' > \\\"$TMPDIR/word/styles.xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><w:document xmlns:w=\\\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\\\"><w:body><w:p><w:r><w:t></w:t></w:r></w:p></w:body></w:document>' > \\\"$TMPDIR/word/document.xml\\\" && "
        "cd \\\"$TMPDIR\\\" && zip -r '%@' . && "
        "rm -rf \\\"$TMPDIR\\\""
        "\"", escapedPath];

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (!errorDict) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    }
}

- (void)createNewExcelDocument {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;

    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *extension = @"xlsx";
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseName, extension]];

    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        NSString *fileName = [NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension];
        filePath = [targetURL.path stringByAppendingPathComponent:fileName];
        counter++;
    }

    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:
        @"do shell script \""
        "TMPDIR=$(mktemp -d) && "
        "mkdir -p \\\"$TMPDIR/_rels\\\" \\\"$TMPDIR/xl/_rels\\\" \\\"$TMPDIR/xl/worksheets\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Types xmlns=\\\"http://schemas.openxmlformats.org/package/2006/content-types\\\"><Default Extension=\\\"rels\\\" ContentType=\\\"application/vnd.openxmlformats-package.relationships+xml\\\"/><Default Extension=\\\"xml\\\" ContentType=\\\"application/xml\\\"/><Override PartName=\\\"/xl/workbook.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\\\"/><Override PartName=\\\"/xl/worksheets/sheet1.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\\\"/><Override PartName=\\\"/xl/styles.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\\\"/></Types>' > \\\"$TMPDIR/[Content_Types].xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\\\" Target=\\\"xl/workbook.xml\\\"/></Relationships>' > \\\"$TMPDIR/_rels/.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><workbook xmlns=\\\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\\\" xmlns:r=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\\\"><sheets><sheet name=\\\"Sheet1\\\" sheetId=\\\"1\\\" r:id=\\\"rId1\\\"/></sheets></workbook>' > \\\"$TMPDIR/xl/workbook.xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\\\" Target=\\\"worksheets/sheet1.xml\\\"/><Relationship Id=\\\"rId2\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\\\" Target=\\\"styles.xml\\\"/></Relationships>' > \\\"$TMPDIR/xl/_rels/workbook.xml.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><styleSheet xmlns=\\\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\\\"><fonts count=\\\"1\\\"><font><sz val=\\\"11\\\"/><name val=\\\"Calibri\\\"/><family val=\\\"2\\\"/></font></fonts><fills count=\\\"2\\\"><fill><patternFill patternType=\\\"none\\\"/></fill><fill><patternFill patternType=\\\"gray125\\\"/></fill></fills><borders count=\\\"1\\\"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count=\\\"1\\\"><xf numFmtId=\\\"0\\\" fontId=\\\"0\\\" fillId=\\\"0\\\" borderId=\\\"0\\\"/></cellStyleXfs><cellXfs count=\\\"1\\\"><xf numFmtId=\\\"0\\\" fontId=\\\"0\\\" fillId=\\\"0\\\" borderId=\\\"0\\\"/></cellXfs></styleSheet>' > \\\"$TMPDIR/xl/styles.xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><worksheet xmlns=\\\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\\\"><sheetData/></worksheet>' > \\\"$TMPDIR/xl/worksheets/sheet1.xml\\\" && "
        "cd \\\"$TMPDIR\\\" && zip -r '%@' . && "
        "rm -rf \\\"$TMPDIR\\\""
        "\"", escapedPath];

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (!errorDict) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    }
}

- (void)createNewPowerPointDocument {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;

    NSString *baseName = NSLocalizedString(@"Untitled", nil);
    NSString *extension = @"pptx";
    NSString *filePath = [targetURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", baseName, extension]];

    NSFileManager *fm = [NSFileManager defaultManager];
    int counter = 1;
    while ([fm fileExistsAtPath:filePath]) {
        NSString *fileName = [NSString stringWithFormat:@"%@ (%d).%@", baseName, counter, extension];
        filePath = [targetURL.path stringByAppendingPathComponent:fileName];
        counter++;
    }

    NSString *escapedPath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:
        @"do shell script \""
        "TMPDIR=$(mktemp -d) && "
        "mkdir -p \\\"$TMPDIR/_rels\\\" \\\"$TMPDIR/ppt/_rels\\\" \\\"$TMPDIR/ppt/slides\\\" \\\"$TMPDIR/ppt/slideLayouts\\\" \\\"$TMPDIR/ppt/slideMasters\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Types xmlns=\\\"http://schemas.openxmlformats.org/package/2006/content-types\\\"><Default Extension=\\\"rels\\\" ContentType=\\\"application/vnd.openxmlformats-package.relationships+xml\\\"/><Default Extension=\\\"xml\\\" ContentType=\\\"application/xml\\\"/><Override PartName=\\\"/ppt/presentation.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml\\\"/><Override PartName=\\\"/ppt/slides/slide1.xml\\\" ContentType=\\\"application/vnd.openxmlformats-officedocument.presentationml.slide+xml\\\"/></Types>' > \\\"$TMPDIR/[Content_Types].xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\\\" Target=\\\"ppt/presentation.xml\\\"/></Relationships>' > \\\"$TMPDIR/_rels/.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><p:presentation xmlns:p=\\\"http://schemas.openxmlformats.org/presentationml/2006/main\\\" xmlns:r=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\\\"><p:sldIdLst><p:sldId id=\\\"256\\\" r:id=\\\"rId1\\\"/></p:sldIdLst></p:presentation>' > \\\"$TMPDIR/ppt/presentation.xml\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><Relationships xmlns=\\\"http://schemas.openxmlformats.org/package/2006/relationships\\\"><Relationship Id=\\\"rId1\\\" Type=\\\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\\\" Target=\\\"slides/slide1.xml\\\"/></Relationships>' > \\\"$TMPDIR/ppt/_rels/presentation.xml.rels\\\" && "
        "echo '<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><p:sld xmlns:p=\\\"http://schemas.openxmlformats.org/presentationml/2006/main\\\"><p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id=\\\"1\\\" name=\\\"\\\"/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld></p:sld>' > \\\"$TMPDIR/ppt/slides/slide1.xml\\\" && "
        "cd \\\"$TMPDIR\\\" && zip -r '%@' . && "
        "rm -rf \\\"$TMPDIR\\\""
        "\"", escapedPath];

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (!errorDict) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    }
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
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
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

    NSString *escapedTemplate = [templatePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *escapedDest = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];

    NSString *scriptSource = [NSString stringWithFormat:@"do shell script \"cp -R '%@' '%@'\"", escapedTemplate, escapedDest];
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errorDict = nil;
    [script executeAndReturnError:&errorDict];

    if (!errorDict) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    }
}

@end
