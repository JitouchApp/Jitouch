//
//  TrackpadTab.m
//  Jitouch
//
//  Copyright 2021 Supasorn Suwajanakorn and Sukolsak Sakshuwong. All rights reserved.
//

#import "TrackpadTab.h"
#import "Settings.h"
#import "GesturePreviewView.h"
#import "GestureTableView.h"
#import "KeyTextField.h"
#import "ImageAndTextCell.h"
#import "MAAttachedWindow.h"
#import "ApplicationButton.h"

@implementation TrackpadTab

- (void)enUpdated {
    if (enAll) {
        [cbAll setEnabled:YES];
    } else {
        [cbAll setEnabled:NO];
    }
    if (enAll && enTPAll) {
        [commandOutlineView setEnabled:YES];
        [addButton setEnabled:YES];
        if ([commandOutlineView selectedRow] != -1) {
            [removeButton setEnabled:YES];
        } else {
            [removeButton setEnabled:NO];
        }
        [rdHanded setEnabled:YES];
        [restoreDefaultsButton setEnabled:YES];
    } else {
        [commandOutlineView setEnabled:NO];
        [addButton setEnabled:NO];
        [removeButton setEnabled:NO];
        [rdHanded setEnabled:NO];
        [restoreDefaultsButton setEnabled:NO];
    }
}

- (void)awakeFromNib {
    trackpadTab = self;
    isPrefPane = YES;
    [Settings loadSettings:self];

    allGestures = [[NSMutableArray alloc] initWithObjects:
                   @"One-Fix Left-Tap",
                   @"One-Fix Right-Tap",
                   @"One-Fix One-Slide",
                   @"One-Fix Two-Slide-Up",
                   @"One-Fix Two-Slide-Down",
                   @"One-Fix-Press Two-Slide-Up",
                   @"One-Fix-Press Two-Slide-Down",
                   //@"One-Fix Three-Slide",
                   @"Two-Fix Index-Double-Tap",
                   @"Two-Fix Middle-Double-Tap",
                   @"Two-Fix Ring-Double-Tap",
                   @"Two-Fix One-Slide-Up",
                   @"Two-Fix One-Slide-Down",
                   @"Two-Fix One-Slide-Left",
                   @"Two-Fix One-Slide-Right",
                   @"Three-Finger Tap",
                   @"Three-Finger Click",
                   @"Three-Finger Pinch-In",
                   @"Three-Finger Pinch-Out",
                   @"Three-Swipe-Up",
                   @"Three-Swipe-Down",
                   @"Three-Swipe-Left", //TODO: should tell the user that it may intefere with the OS's gestures
                   @"Three-Swipe-Right",
                   @"Four-Finger Tap",
                   @"Four-Finger Click",
                   @"Four-Swipe-Up",
                   @"Four-Swipe-Down",
                   @"Four-Swipe-Left",
                   @"Four-Swipe-Right",
                   @"Pinky-To-Index",
                   @"Index-To-Pinky",
                      @"Left-Side Scroll",
                      @"Right-Side Scroll",
                   @"All Unassigned Gestures",
                   nil];

    [rdHanded selectCellAtRow:0 column:enHanded];
    [cbAll setState:enTPAll];
    [self enUpdated];

    [commandOutlineView reloadData];
    [commandOutlineView tableColumnWithIdentifier:@"Enable"].minWidth = 20.0;
    [commandOutlineView tableColumnWithIdentifier:@"Enable"].width = 20.0;
    [commandOutlineView expandItem:nil expandChildren:YES];


    saveRowIndex = -1;
    realView = [commandOutlineView enclosingScrollView];

    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:realView.bounds
                                                                options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways)
                                                                  owner:self userInfo:nil];
    [realView addTrackingArea:trackingArea];
    [trackingArea release];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector: @selector(outlineViewScrolled:)
                                                 name: NSViewBoundsDidChangeNotification
                                               object: [[commandOutlineView enclosingScrollView] contentView]];
}

#pragma mark - Gesture animations

- (void)hidePreview {
    window = [mainView window];
    if (attachedWindow) {
        [gesturePreviewView stopTimer];
        gesturePreviewView = nil;
        [attachedWindow orderOut:self];
        [window removeChildWindow:attachedWindow];
        attachedWindow = nil;
    }
    saveRowIndex = -1;
}

- (void)showPreview:(BOOL)scroll {
    window = [mainView window];
    NSInteger rowIndex;

    NSPoint point = [commandOutlineView convertPoint:[window mouseLocationOutsideOfEventStream] fromView:[window contentView]];

    if ([commandOutlineView columnAtPoint:point] != 1) {
        [self hidePreview];
        return;
    }

    rowIndex = [commandOutlineView rowAtPoint:point];
    if (rowIndex == -1 || [commandOutlineView levelForRow:rowIndex] == 0) {
        [self hidePreview];
        return;
    }


    NSRect frame = [commandOutlineView frameOfCellAtColumn:1 row:rowIndex];
    frame.origin.y--;
    frame.size.height+=2;
    if (!NSPointInRect(point, frame)) {
        [self hidePreview];
        return;
    }



    if (saveRowIndex != rowIndex) {
        saveRowIndex = rowIndex;


        id item = [commandOutlineView itemAtRow:rowIndex];
        NSString *gesture = [item objectForKey:@"Gesture"];

        if ([gesture isEqualToString:@"All Unassigned Gestures"]) {
            [self hidePreview];
            return;
        }

        [gesturePreviewView stopTimer];
        gesturePreviewView = [[GesturePreviewView alloc] initWithDevice:0];
        [gesturePreviewView setHanded:enHanded];
        [gesturePreviewView startTimer];

        NSPoint attachedPoint = [[window contentView] convertPoint:frame.origin fromView:commandOutlineView];
        attachedPoint.y -= frame.size.height/2;
        MAAttachedWindow *tmp = [[MAAttachedWindow alloc] initWithView:gesturePreviewView
                                                       attachedToPoint:attachedPoint
                                                              inWindow:window
                                                                onSide:0
                                                            atDistance:2.0];
        [tmp setBackgroundColor:[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:0.8]];
        [tmp setBorderWidth:0];
        [tmp setArrowBaseWidth:3*5];
        [tmp setArrowHeight:2*5];


        [window addChildWindow:tmp ordered:NSWindowAbove];


        [gesturePreviewView create:gesture forDevice:0];
        [gesturePreviewView release];


        if (attachedWindow) {
            [window removeChildWindow:attachedWindow];
            [attachedWindow orderOut:self];
            [attachedWindow release];
        }
        attachedWindow = tmp;
    } else if (scroll) {
        if (attachedWindow) {
            NSPoint attachedPoint = [[window contentView] convertPoint:frame.origin fromView:commandOutlineView];
            attachedPoint.y -= frame.size.height/2;
            [attachedWindow setPoint:attachedPoint side:0];
        }
    }
}

#pragma mark - Mouse events

- (void)mouseEntered:(NSEvent *)theEvent {
    [self showPreview:NO];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [self hidePreview];
}

- (void)mouseMoved:(NSEvent *)theEvent {
    [self showPreview:NO];
}

- (void)outlineViewScrolled:(NSNotification*)notification {
    [self showPreview:YES];
}

#pragma mark - Outline view

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return (item == nil) ? [trackpadCommands count] : [[item objectForKey:@"Gestures"] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [outlineView levelForItem:item] == 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return (item == nil) ? [trackpadCommands objectAtIndex:index] : [[item objectForKey:@"Gestures"] objectAtIndex:index];
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([outlineView levelForItem:item] == 0) {
        if ([[tableColumn identifier] isEqualToString:@"Gesture"]) {
            return [item objectForKey:@"Application"];
        } else if ([[tableColumn identifier] isEqualToString:@"Enable"]) {
            BOOL foundEnable=NO, foundDisable=NO;
            for (NSDictionary *command in [item objectForKey:@"Gestures"]) {
                if ([[command objectForKey:@"Enable"] intValue]) {
                    foundEnable = YES;
                } else {
                    foundDisable = YES;
                }
                if (foundEnable && foundDisable) break;
            }
            if (foundEnable) {
                if (foundDisable)
                    return [NSNumber numberWithInt:NSMixedState];
                return [NSNumber numberWithInt:NSOnState];
            }
            return [NSNumber numberWithInt:NSOffState];

        }
    } else {
        if ([[tableColumn identifier] isEqualToString:@"Gesture"]) {
            return [item objectForKey:@"Gesture"];
        } else if ([[tableColumn identifier] isEqualToString:@"Command"]) {
            return [item objectForKey:@"Command"];
        } else if ([[tableColumn identifier] isEqualToString:@"Enable"]) {
            return [item objectForKey:@"Enable"];
        }

    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([[tableColumn identifier] isEqualToString:@"Enable"]) {
        if ([outlineView levelForItem:item] == 1) {
            [item setValue:object forKey:@"Enable"];
            [commandOutlineView reloadItem:nil reloadChildren:YES];

        } else {
            BOOL foundDisable=NO;
            for (NSDictionary *command in [item objectForKey:@"Gestures"]) {
                if (![[command objectForKey:@"Enable"] intValue]) {
                    foundDisable = YES;
                    break;
                }
            }
            if (foundDisable) {
                for (NSDictionary *gesture in [item objectForKey:@"Gestures"])
                    [gesture setValue:[NSNumber numberWithInteger:NSOnState] forKey:@"Enable"];
            } else {
                for (NSDictionary *gesture in [item objectForKey:@"Gestures"])
                    [gesture setValue:[NSNumber numberWithInteger:NSOffState] forKey:@"Enable"];
            }
            [outlineView reloadItem:nil reloadChildren:YES];
        }
        [Settings setKey:@"TrackpadCommands" with:trackpadCommands];
        [Settings noteSettingsUpdated];
    }
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([outlineView levelForItem:item] == 0) {
        if ([[tableColumn identifier] isEqualToString:@"Gesture"]) {
            NSString *application = [item objectForKey:@"Application"];
            NSImage *icon = [iconDict objectForKey:application];
            [(ImageAndTextCell *)cell setImage:icon];
        } else if ([[tableColumn identifier] isEqualToString:@"Enable"]) {
            [cell setAllowsMixedState:YES];

            BOOL foundEnable=NO, foundDisable=NO;
            for (NSDictionary *command in [item objectForKey:@"Gestures"]) {
                if ([[command objectForKey:@"Enable"] intValue]) {
                    foundEnable = YES;
                } else {
                    foundDisable = YES;
                }
                if (foundEnable && foundDisable) break;
            }
            //return;
            if (foundEnable) {
                if (foundDisable)
                    [cell setState:NSMixedState];
                else
                    [cell setState:NSOnState];
                return;
            }
            [cell setState:NSOffState];

        }
    } else {
        if ([[tableColumn identifier] isEqualToString:@"Gesture"]) {
            [(ImageAndTextCell *)cell setImage:nil];
        } else if ([[tableColumn identifier] isEqualToString:@"Enable"]) {
            [cell setAllowsMixedState:NO];
        }
    }
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([[tableColumn identifier] isEqualToString:@"Enable"])
        return YES;
    if ([outlineView levelForItem:item] == 1) {
        addsCommand = NO;
        oldItem = item;
        oldItemIndex = [allGestures indexOfObject:[item objectForKey:@"Gesture"]];
        [self showCommandSheet];
    }
    return NO;
}

/*
 - (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
 if ([outlineView levelForItem:item] == 0) {
 return 20;
 }
 return [outlineView rowHeight];
 }
 */

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [outlineView levelForItem:item] == 0;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([commandOutlineView selectedRow] != -1) {
        [removeButton setEnabled:YES];
    } else {
        [removeButton setEnabled:NO];
    }
}

#pragma mark - Actions

- (void)loadActionButton {

    NSString *saveTitle = [actionButton titleOfSelectedItem];
    [actionButton removeAllItems];

    NSString *gesture = [gestureTableView titleOfSelectedItem];

    if (!gesture) {
        [shortcutTextField setStringValue:@""];
        [shortcutTextField setEnabled:NO];
        return;
    }

    if ([gesture isEqualToString:@"One-Fix One-Slide"]) {
        [actionButton addItemWithTitle:@"Move / Resize"];
        [shortcutTextField setStringValue:@""];
        [shortcutTextField setEnabled:NO];

    } else if ([gesture isEqualToString:@"All Unassigned Gestures"]) {
        [shortcutTextField setStringValue:@""];
        [shortcutTextField setEnabled:NO];
    } else if ([gesture isEqualToString:@"Left-Side Scroll"] || [gesture isEqualToString:@"Right-Side Scroll"]) {
        [actionButton addItemWithTitle:@"Auto Scroll"];
        [shortcutTextField setStringValue:@""];
        [shortcutTextField setEnabled:NO];
    } else {
        NSMutableArray *builtinCommands = [NSMutableArray arrayWithObjects:
                                           @"Previous Tab",
                                           @"Next Tab",
                                           @"Open Link in New Tab",
                                           @"Close / Close Tab",
                                           @"Open Recently Closed Tab",
                                           @"Select Tab Above Cursor",
                                           @"Refresh",
                                           @"Quit",
                                           @"Hide",
                                           @"---",
                                           @"Full Screen",
                                           @"Minimize",
                                           @"Zoom",
                                           @"Maximize",
                                           @"Maximize Left",
                                           @"Maximize Right",
                                           @"Un-Maximize",
                                           @"---",
                                           @"Show Desktop",
                                           @"Dashboard",
                                           @"Mission Control",
                                           @"Launchpad",
                                           @"Application Windows",
                                           @"Application Switcher",
                                           @"---",
                                           @"Scroll to Top",
                                           @"Scroll to Bottom",
                                           @"---",
                                           @"Left Click",
                                           @"Middle Click",
                                           @"Right Click",
                                           @"---",
                                           @"Play / Pause",
                                           @"Next",
                                           @"Previous",
                                           @"Volume Up",
                                           @"Volume Down",
                                           @"---",
                                           @"Launch Browser",
                                             @"Launch Finder",
                                           @"Open File...",
                                           @"Open Website...",
                                           nil];
        if (![[applicationButton titleOfSelectedItem] isEqualToString:@"Safari"]) {
            [builtinCommands removeObject:@"Select Tab Above Cursor"];
        }

        if (openFilePath) {
            NSString *fileName = [openFilePath lastPathComponent];
            [builtinCommands insertObject:[NSString stringWithFormat:@"Open \"%@\"", fileName] atIndex:[builtinCommands count]];
        }
        if (openURL) {
            [builtinCommands insertObject:[NSString stringWithFormat:@"Open \"%@\"", openURL] atIndex:[builtinCommands count]];
        }

        for (NSString *element in builtinCommands) {
            if ([element isEqualToString:@"---"])
                [[actionButton menu] addItem:[NSMenuItem separatorItem]];
            else
                [actionButton addItemWithTitle:element];
        }

        [shortcutTextField setEnabled:YES];
    }



    [[actionButton menu] addItem:[NSMenuItem separatorItem]];
    [actionButton addItemWithTitle:@"-"];

    if (gesture == nil || saveTitle == nil || [saveTitle isEqualToString:@""]) {
        [actionButton selectItemWithTitle:@"-"];
    } else {
        NSInteger index = [actionButton indexOfItemWithTitle:saveTitle];
        if (index == -1)
            [actionButton selectItemWithTitle:@"-"];
        else
            [actionButton selectItemAtIndex:index];
    }


}

- (void)loadGestureTableView {
    [gestureTableView setDevice:0];
    [gestureTableView setGestures:allGestures];
    [gestureTableView reloadData];

    if (addsCommand) {

        BOOL found=NO;
        for (NSString *gesture in allGestures) {
            if ([[trackpadMap objectForKey:[applicationButton titleOfSelectedItem]] objectForKey:gesture] == nil) {
                [gestureTableView selectItemWithObjectValue:gesture];
                [gestureTableView scrollRowToVisible:[gestureTableView selectedRow]];
                found = YES;
                break;
            }
        }

        if (!found) {
            [gestureTableView deselectAll:self];
        }

    } else {
        [gestureTableView selectItemWithObjectValue:[oldItem objectForKey:@"Gesture"]];
        [gestureTableView scrollRowToVisible:[gestureTableView selectedRow]];
    }
}


- (void)showCommandSheet {
    window = [mainView window];
    if (eventKeyboard) CGEventTapEnable(eventKeyboard, true);

    openFilePath = nil;
    openURL = nil;
    if (addsCommand) {

        if ([commandOutlineView selectedRow] != -1) {
            id item = [commandOutlineView itemAtRow:[commandOutlineView selectedRow]];
            if ([commandOutlineView levelForRow:[commandOutlineView selectedRow]] == 0) {
                [applicationButton selectItemWithTitle:[item objectForKey:@"Application"]];
            } else {
                [applicationButton selectItemWithTitle:[[commandOutlineView parentForItem:item] objectForKey:@"Application"]];
            }
        } else {
            if (saveApplication != nil)
                [applicationButton selectItemWithTitle:saveApplication];
        }
        [applicationButton setEnabled:YES];

        [self loadGestureTableView];

        [self loadActionButton];
        [actionButton selectItemWithTitle:@"-"];
        [shortcutTextField setStringValue:@""];

        [commitButton setTitle:@"Add"];
    } else {
        [applicationButton selectItemWithTitle: [[commandOutlineView parentForItem:oldItem] objectForKey:@"Application"]  ];
        [applicationButton setEnabled:NO];

        [self loadGestureTableView];

        if ([[oldItem objectForKey:@"IsAction"] boolValue] && [oldItem objectForKey:@"OpenFilePath"]) {
            openFilePath = [oldItem objectForKey:@"OpenFilePath"];
        }
        if ([[oldItem objectForKey:@"IsAction"] boolValue] && [oldItem objectForKey:@"OpenURL"]) {
            openURL = [oldItem objectForKey:@"OpenURL"];
        }

        [self loadActionButton];

        if ([[oldItem objectForKey:@"IsAction"] boolValue]) {
            [actionButton selectItemWithTitle:[oldItem objectForKey:@"Command"]];
            [shortcutTextField setStringValue:@""];
        } else {
            [actionButton setTitle:@""];
            [shortcutTextField setStringValue:[oldItem objectForKey:@"Command"]];
            shortcutTextField.modifierFlags = [[oldItem objectForKey:@"ModifierFlags"] unsignedIntegerValue];
            shortcutTextField.keyCode = [[oldItem objectForKey:@"KeyCode"] unsignedShortValue];
            [shortcutTextField selectText:nil];
        }

        [commitButton setTitle:@"Save"];
    }

    if ([gestureTableView selectedRow] == -1) {
        [shortcutTextField setStringValue:@""];
        [shortcutTextField setEnabled:NO];
    }

    if ([gestureTableView selectedRow] == -1) {
        [commitButton setEnabled:NO];
    }else{
        [commitButton setEnabled:YES];
    }

    [NSApp beginSheet: commandSheet
       modalForWindow: window
        modalDelegate: self
       didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
          contextInfo: nil];
}

- (IBAction)okUrlWindow:(id)sender {
    [NSApp endSheet:urlWindow];
    openFilePath = nil;
    openURL = [urlWindowUrl stringValue];
    openURL = [openURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![[NSURL URLWithString:openURL] scheme]) {
        openURL = [NSString stringWithFormat:@"http://%@", openURL];
    }
    [openURL retain];
    [self loadActionButton];
    [actionButton selectItemWithTitle:[NSString stringWithFormat:@"Open \"%@\"", openURL]];
}

- (IBAction)cancelUrlWindow:(id)sender {
    [NSApp endSheet:urlWindow];
    [actionButton selectItemWithTitle:@"-"];
}

- (IBAction)cancelCommandSheet:(id)sender {
    [gestureTableView hidePreview];
    if (eventKeyboard) CGEventTapEnable(eventKeyboard, false);
    [NSApp endSheet:commandSheet];
}

- (IBAction)commitCommandSheet:(id)sender {
    [gestureTableView hidePreview];
    if (eventKeyboard) CGEventTapEnable(eventKeyboard, false);
    [NSApp endSheet:commandSheet];
    NSString *newApplication = [applicationButton titleOfSelectedItem];
    NSString *newApplicationPath = [applicationButton pathOfSelectedItem];
    NSString *newGesture = [gestureTableView titleOfSelectedItem];
    NSMutableDictionary *newCommand;

    saveApplication = newApplication;

    if ([[shortcutTextField stringValue] isEqualToString:@""]) {
        //action
        newCommand = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                      newGesture, @"Gesture",
                      [actionButton titleOfSelectedItem], @"Command",
                      [NSNumber numberWithBool:YES], @"IsAction",
                      [NSNumber numberWithUnsignedInteger:0], @"ModifierFlags",
                      [NSNumber numberWithUnsignedShort:0], @"KeyCode",
                      [NSNumber numberWithInt:NSOnState], @"Enable",
                      nil];
        if (openFilePath) {
            [newCommand setObject:openFilePath forKey:@"OpenFilePath"];
        }
        if (openURL) {
            [newCommand setObject:openURL forKey:@"OpenURL"];
        }
    } else {

        //shortcut
        newCommand = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                      newGesture, @"Gesture",
                      [shortcutTextField stringValue], @"Command",
                      [NSNumber numberWithBool:NO], @"IsAction",
                      [NSNumber numberWithUnsignedInteger:shortcutTextField.modifierFlags], @"ModifierFlags",
                      [NSNumber numberWithUnsignedShort:shortcutTextField.keyCode], @"KeyCode",
                      [NSNumber numberWithInt:NSOnState], @"Enable",
                      nil];
    }


    if (!addsCommand) {
        NSString *oldApp = [[commandOutlineView parentForItem:oldItem] objectForKey:@"Application"];
        [[trackpadMap objectForKey:oldApp] removeObjectForKey:[oldItem objectForKey:@"Gesture"]];
        [[[commandOutlineView parentForItem:oldItem] objectForKey:@"Gestures"] removeObject:oldItem];
    }

    {
        //user adds a command
        NSUInteger i, count = [trackpadCommands count];
        for (i = 0; i < count; i++) {
            if ([[[trackpadCommands objectAtIndex:i] objectForKey:@"Application"] isEqualToString:newApplication]) {
                NSMutableArray *tmp = [[trackpadCommands objectAtIndex:i] objectForKey:@"Gestures"];
                NSUInteger j, count2 = [tmp count];
                NSUInteger newGestureIndex = [allGestures indexOfObject:newGesture];
                for (j = 0; j < count2; j++) {
                    NSUInteger currentGestureIndex = [allGestures indexOfObject: [[tmp objectAtIndex:j] objectForKey:@"Gesture"  ]];
                    if (currentGestureIndex > newGestureIndex) break;
                }
                [[[trackpadCommands objectAtIndex:i] objectForKey:@"Gestures"] insertObject:newCommand atIndex:j];


                [[trackpadMap objectForKey:newApplication] setObject:newCommand forKey:newGesture];
                break;
            }
        }
        if (i == count) {
            NSMutableArray *gestures = [[NSMutableArray alloc] init];
            [gestures addObject:newCommand];
            NSMutableDictionary *app = [[NSMutableDictionary alloc] initWithObjectsAndKeys:newApplication, @"Application", newApplicationPath, @"Path", gestures, @"Gestures", nil];
            [gestures release];
            [trackpadCommands addObject:app];
            [app release];


            NSMutableDictionary *tmp = [[NSMutableDictionary alloc] initWithObjectsAndKeys:newCommand, newGesture, nil];
            [trackpadMap setObject:tmp forKey:newApplication];
            [tmp release];
        }

        [commandOutlineView reloadItem:nil reloadChildren:YES];
        [commandOutlineView expandItem:[trackpadCommands objectAtIndex:i] expandChildren:YES];

    }

    NSInteger newIndex = [commandOutlineView rowForItem:newCommand];
    [commandOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:newIndex] byExtendingSelection:NO];
    [commandOutlineView scrollRowToVisible:newIndex];

    [newCommand release];

    [Settings setKey:@"TrackpadCommands" with:trackpadCommands];
    [Settings noteSettingsUpdated];

    if ([newGesture isEqualToString:@"Four-Swipe-Left"] || [newGesture isEqualToString:@"Four-Swipe-Right"]) {
        CFMutableDictionaryRef matchingDict = IOServiceNameMatching("AppleUSBMultitouchDriver");
        io_registry_entry_t service = (io_registry_entry_t)IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict);
        if (service) {
            CFDictionaryRef dict = IORegistryEntryCreateCFProperty(service, CFSTR("TrackpadUserPreferences"), kCFAllocatorDefault, 0);
            if (dict) {
                CFBooleanRef tmp = CFDictionaryGetValue(dict, CFSTR("TrackpadFourFingerHorizSwipeGesture"));
                if (CFBooleanGetValue(tmp)) {
                    NSDictionary *errorInfo;
                    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:
                                                  [NSString stringWithFormat:
                                                   @"tell application \"System Preferences\"\n"
                                                   "    set current pane to pane id \"com.apple.preference.trackpad\"\n"
                                                   "    display dialog \"For the %@ gesture to work, you must unselect \\\"Swipe between full-screen apps\\\" in the \\\"More Gestures\\\" tab.\" with icon 1 buttons {\"OK\"} default button 1\n"
                                                   "end tell\n"
                                                   ,newGesture
                                                   ]];
                    [appleScript executeAndReturnError:&errorInfo];
                    [appleScript release];
                }
                CFRelease(dict);
            }
        }
    }
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
    [sheet orderOut:self];
}

- (IBAction)addCommand:(id)sender {
    addsCommand = YES;
    [self showCommandSheet];
}

- (IBAction)removeCommand:(id)sender {
    id item = [commandOutlineView itemAtRow:[commandOutlineView selectedRow]];
    if ([commandOutlineView levelForItem:item] == 0) {
        [trackpadMap removeObjectForKey:[item objectForKey:@"Application"]];

        [trackpadCommands removeObject:item];
    } else {
        NSString *app = [[commandOutlineView parentForItem:item] objectForKey:@"Application"];
        [[trackpadMap objectForKey:app] removeObjectForKey:[item objectForKey:@"Gesture"]];

        [[[commandOutlineView parentForItem:item] objectForKey:@"Gestures"] removeObject:item];
    }
    [commandOutlineView reloadData];
    [Settings setKey:@"TrackpadCommands" with:trackpadCommands];
    [Settings noteSettingsUpdated];
}

- (IBAction)change:(id)sender {
    if (sender == actionButton) {
        [shortcutTextField setStringValue:@""];
        //[gestureTableView becomeFirstResponder]; DOESN"T WORK
        //[commitButton becomeFirstResponder];


        if ([[actionButton titleOfSelectedItem] isEqualToString:@"Open File..."]) {
            NSOpenPanel *oPanel = [NSOpenPanel openPanel];
            [oPanel setCanChooseDirectories:YES];
            NSModalResponse result = [oPanel runModal];

            if (result == NSOKButton) {
                openFilePath = [[[oPanel URL] path] copy]; //TODO: mem leak
                openURL = nil;
                [self loadActionButton];
                [actionButton selectItemWithTitle:[NSString stringWithFormat:@"Open \"%@\"", [openFilePath lastPathComponent]]];
            } else {
                [actionButton selectItemWithTitle:@"-"];
            }
        } else if ([[actionButton titleOfSelectedItem] isEqualToString:@"Open Website..."]) {
            if (openURL)
                [urlWindowUrl setStringValue:openURL];
            else
                [urlWindowUrl setStringValue:@""];
            [urlWindowOk setTarget:self];
            [urlWindowOk setAction:@selector(okUrlWindow:)];
            [urlWindowCancel setTarget:self];
            [urlWindowCancel setAction:@selector(cancelUrlWindow:)];
            [NSApp beginSheet: urlWindow
               modalForWindow: commandSheet
                modalDelegate: self
               didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
                  contextInfo: nil];
        }
    } else if (sender == shortcutTextField && ![[shortcutTextField stringValue] isEqualToString:@""]) {
        //[actionButton selectItemWithTitle:@"-"];
        [actionButton setTitle:@""];
    } else if (sender == applicationButton) {
        if ([[applicationButton titleOfSelectedItem] isEqualToString:@"Other..."]) {
            NSOpenPanel *oPanel = [NSOpenPanel openPanel];
            [oPanel setDirectoryURL:[NSURL fileURLWithPath:@"/Applications"]];
            [oPanel setAllowedFileTypes:@[@"app"]];
            NSModalResponse result = [oPanel runModal];

            if (result == NSOKButton) {
                NSString* path = [[oPanel URL] path];
                [applicationButton addApplication:path];
            } else {
                [applicationButton selectItemAtIndex:0];
            }
        }

        [self loadGestureTableView];
        [self loadActionButton];
    } else if (sender == rdHanded) {
        enHanded = (int)[sender selectedColumn];
        [Settings setKey:@"Handed" withInt:(int)[sender selectedColumn]];
    } else if (sender == cbAll) {
        enTPAll = [sender state] == NSOnState ? 1: 0;
        [Settings setKey:@"enTPAll" withInt:enTPAll];
        [self enUpdated];
    }

    if ([gestureTableView selectedRow] == -1) {
        [shortcutTextField setStringValue:@""];
        [shortcutTextField setEnabled:NO];
    }

    if ([gestureTableView selectedRow] == -1) {
        [commitButton setEnabled:NO];
    } else {
        [commitButton setEnabled:YES];
    }

    [Settings noteSettingsUpdated];
}

- (IBAction)restoreDefaults:(id)sender {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Restore default settings?"];
    [alert setInformativeText:@"Your current trackpad settings will be deleted."];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        [Settings trackpadDefault];
        isPrefPane = YES;
        //[Settings loadSettings];
        [Settings readSettings];
        [commandOutlineView reloadData];
        [commandOutlineView expandItem:nil expandChildren:YES];
        [Settings noteSettingsUpdated];
    }
}

#pragma mark - Table view

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self loadActionButton];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
    if (addsCommand) {
        return [[trackpadMap objectForKey:[applicationButton titleOfSelectedItem]] objectForKey:[allGestures objectAtIndex:rowIndex]] == nil;
    } else {
        NSDictionary *tmp = [trackpadMap objectForKey:[applicationButton titleOfSelectedItem]];
        return rowIndex == oldItemIndex || [tmp objectForKey:[allGestures objectAtIndex:rowIndex]] == nil;
    }
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if (addsCommand) {
        if ([[trackpadMap objectForKey:[applicationButton titleOfSelectedItem]] objectForKey:[allGestures objectAtIndex:rowIndex]] == nil)
            [aCell setTextColor:[NSColor textColor]];
        else
            [aCell setTextColor:[NSColor colorWithDeviceRed:0.6 green:0.6 blue:0.6 alpha:1.0]];
    } else {
        NSDictionary *tmp = [trackpadMap objectForKey:[applicationButton titleOfSelectedItem]];
        if (rowIndex == oldItemIndex || [tmp objectForKey:[allGestures objectAtIndex:rowIndex]] == nil)
            [aCell setTextColor:[NSColor textColor]];
        else
            [aCell setTextColor:[NSColor colorWithDeviceRed:0.6 green:0.6 blue:0.6 alpha:1.0]];
    }
}

#pragma mark -

- (void)willUnselect {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
    [self hidePreview];
    [gestureTableView willUnselect];
}

- (void)dealloc{;
    [allGestures release];
    [iconDict release];
    [super dealloc];
}

@end
