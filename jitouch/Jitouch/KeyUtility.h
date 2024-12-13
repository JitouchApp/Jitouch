//
//  KeyUtility.h
//  Jitouch
//
//  Copyright 2021 Supasorn Suwajanakorn and Sukolsak Sakshuwong. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/hidsystem/ev_keymap.h>

@interface KeyUtility : NSObject {
    NSMutableDictionary *keyMap;
}

- (void)simulateKeyCode:(CGKeyCode)code ShftDown:(BOOL)shft CtrlDown:(BOOL)ctrl AltDown:(BOOL)alt CmdDown:(BOOL)cmd FnDown:(BOOL)fn;
- (void)simulateKey:(NSString *)key ShftDown:(BOOL)shft CtrlDown:(BOOL)ctrl AltDown:(BOOL)alt CmdDown:(BOOL)cmd FnDown:(BOOL)fn;
- (void)simulateSpecialKey:(int)key;
- (CGKeyCode)charToCode:(NSString*) chr;
+ (NSString *)codeToChar:(CGKeyCode)keyCode;

@end
