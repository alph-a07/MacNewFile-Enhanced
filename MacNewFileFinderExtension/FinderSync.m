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
        @{@"id": @"txt", @"name": @"Text File", @"ext": @"txt", @"category": @"Documents & Notes", @"isEnabled": @YES, @"creatorType": @"standard"},
        @{@"id": @"md", @"name": @"Markdown Document", @"ext": @"md", @"category": @"Documents & Notes", @"isEnabled": @YES, @"creatorType": @"standard", @"template": @"# Title\n\n"},
        @{@"id": @"py", @"name": @"Python Script", @"ext": @"py", @"category": @"Code & Web", @"isEnabled": @YES, @"creatorType": @"standard", @"template": @"#!/usr/bin/env python3\n"},
        @{@"id": @"docx", @"name": @"Microsoft Word Document", @"ext": @"docx", @"category": @"Documents & Notes", @"isEnabled": @YES, @"creatorType": @"docx"},
        @{@"id": @"xlsx", @"name": @"Microsoft Excel Spreadsheet", @"ext": @"xlsx", @"category": @"Documents & Notes", @"isEnabled": @YES, @"creatorType": @"xlsx"},
        @{@"id": @"pptx", @"name": @"Microsoft PowerPoint Presentation", @"ext": @"pptx", @"category": @"Documents & Notes", @"isEnabled": @YES, @"creatorType": @"pptx"},
        @{@"id": @"pages", @"name": @"Apple Pages Document", @"ext": @"pages", @"category": @"Documents & Notes", @"isEnabled": @YES, @"creatorType": @"pages"},
        @{@"id": @"numbers", @"name": @"Apple Numbers Spreadsheet", @"ext": @"numbers", @"category": @"Documents & Notes", @"isEnabled": @YES, @"creatorType": @"numbers"},
        @{@"id": @"key", @"name": @"Apple Keynote Presentation", @"ext": @"key", @"category": @"Documents & Notes", @"isEnabled": @YES, @"creatorType": @"key"}
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

    // Filter enabled items
    NSMutableArray<NSDictionary *> *enabledItems = [NSMutableArray array];
    for (NSDictionary *item in fileItems) {
        if ([item[@"isEnabled"] boolValue]) {
            [enabledItems addObject:item];
        }
    }

    // 1. If right-clicked directly on a file/item, show "Quick Edit"
    if (whichMenu == FIMenuKindContextualMenuForItems) {
        if (showQuickEdit) {
            NSMenuItem *quickEditItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Edit File", nil)
                                                                   action:@selector(quickEditSelectedFile:)
                                                            keyEquivalent:@""];
            NSImage *editIcon = [NSImage imageNamed:@"edit"];
            editIcon.template = YES;
            quickEditItem.image = editIcon;
            [menu addItem:quickEditItem];
            [menu addItem:[NSMenuItem separatorItem]];
        }
    }

    // 2. "Copy Path" menu item
    if (includeCopyPath) {
        NSMenuItem *copyPathItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Path", nil)
                                                              action:@selector(copyPathToClipboard:)
                                                       keyEquivalent:@""];
        NSImage *copyIcon = [NSImage imageNamed:@"copy"];
        copyIcon.template = YES;
        copyPathItem.image = copyIcon;
        [menu addItem:copyPathItem];
    }

    // 3. "Open Terminal" menu item
    if (includeOpenTerminal) {
        NSMenuItem *openTerminalItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open New Terminal", nil)
                                                                  action:@selector(openTerminalAtPath:)
                                                           keyEquivalent:@""];
        NSImage *terminalIcon = [NSImage imageNamed:@"terminal"];
        terminalIcon.template = YES;
        openTerminalItem.image = terminalIcon;
        [menu addItem:openTerminalItem];
    }

    // 4. "New File" Submenu
    NSMenuItem *mainItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"New File", nil) action:nil keyEquivalent:@""];
    NSImage *mainIcon = [NSImage imageNamed:@"add"];
    mainIcon.template = YES;
    mainItem.image = mainIcon;

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

    return menu;
}

- (NSMenuItem *)menuItemForFileItem:(NSDictionary *)item {
    NSString *name = item[@"name"] ?: [NSString stringWithFormat:@".%@ File", item[@"ext"]];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(handleCreateFileItem:) keyEquivalent:@""];
    menuItem.representedObject = item;

    // Set appropriate icon
    NSString *creatorType = item[@"creatorType"] ?: @"standard";
    NSString *iconName = @"document";

    if ([creatorType isEqualToString:@"docx"]) iconName = @"word";
    else if ([creatorType isEqualToString:@"xlsx"]) iconName = @"excel";
    else if ([creatorType isEqualToString:@"pptx"]) iconName = @"powerpoint";
    else if ([creatorType isEqualToString:@"pages"]) iconName = @"pages";
    else if ([creatorType isEqualToString:@"numbers"]) iconName = @"numbers";
    else if ([creatorType isEqualToString:@"key"]) iconName = @"keynote";
    else {
        NSString *ext = [item[@"ext"] lowercaseString];
        if ([ext isEqualToString:@"txt"] || [ext isEqualToString:@"rtf"]) iconName = @"edit";
        else if ([ext isEqualToString:@"sh"]) iconName = @"terminal";
    }

    NSImage *icon = [NSImage imageNamed:iconName];
    if (icon) {
        icon.template = YES;
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
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;

    NSString *path = targetURL.path;
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:path forType:NSPasteboardTypeString];
}

- (void)openTerminalAtPath:(id)sender {
    NSURL *targetURL = [[FIFinderSyncController defaultController] targetedURL];
    if (!targetURL) return;

    NSString *path = targetURL.path;
    NSString *escapedPath = [path stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    NSString *scriptSource = [NSString stringWithFormat:@"do shell script \"open -a Terminal '%@'\"", escapedPath];

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
