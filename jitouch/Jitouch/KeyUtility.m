//
//  KeyUtility.m
//  Jitouch
//
//  Copyright 2021 Supasorn Suwajanakorn and Sukolsak Sakshuwong. All rights reserved.
//

#import "KeyUtility.h"
#import <Carbon/Carbon.h>

// to suppress "'CGPostKeyboardEvent' is deprecated" warnings
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@implementation KeyUtility

static CGKeyCode a[128];

static void languageChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    for (int i = 0; i < 128; i++)
        a[i] = (CGKeyCode)i;

    NSString *inputSource = (NSString*)TISGetInputSourceProperty(TISCopyCurrentKeyboardInputSource(), kTISPropertyLocalizedName);
    if ([inputSource isEqualToString:@"Dvorak"] || [inputSource isEqualToString:@"Svorak"]) {
        a[13] = 43; //w -> ,
        a[12] = 7;  //q -> x
        a[17] = 40; //t -> k
        a[4] = 38;  //h -> j
        a[15] = 31; //r -> o
        a[45] = 37; //n -> l
        a[8] = 34; //c -> i
        a[9] = 47; //v -> >
        a[31] = 1; //o ->
        a[37] = 45; //l -> n
        a[3] = 32; // f -> u
        a[40] = 17;
    } else if ([inputSource isEqualToString:@"French"]) {
        a[13] = 6;  //w -> z
        a[12] = 0;  //q -> a
    }
}

- (id)init {
    self = [super init];
    if (self) {
        languageChanged(NULL, NULL, NULL, NULL, NULL);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), self, languageChanged, kTISNotifySelectedKeyboardInputSourceChanged, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        keyMap = [[NSMutableDictionary alloc] init];
        for (CGKeyCode i = 0; i < 128; i++) {
            [keyMap setObject:[NSNumber numberWithUnsignedInt:i] forKey:[KeyUtility codeToChar:i]];
        }
    }
    return self;
}

- (void)simulateKeyCode:(CGKeyCode)code ShftDown:(BOOL)shft CtrlDown:(BOOL)ctrl AltDown:(BOOL)alt CmdDown:(BOOL)cmd FnDown:(BOOL)fn {

     if (shft)
     CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)56, true);
     if (ctrl)
     CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)59, true);
     if (alt)
     CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)58, true);
     if (cmd)
     CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)55, true);
     if(fn)
     CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)63, true);
    
     CGPostKeyboardEvent((CGCharCode)0, a[code], true);
     CGPostKeyboardEvent((CGCharCode)0, a[code], false);

     if (shft)
     CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)56, false);
     if (ctrl)
     CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)59, false);
     if (alt)
     CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)58, false);
     if (cmd)
     CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)55, false);
     if(fn)
     CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)63, false);
   
}

- (void) simulateKey:(NSString *)key ShftDown:(BOOL)shft CtrlDown:(BOOL)ctrl AltDown:(BOOL)alt CmdDown:(BOOL)cmd FnDown:(BOOL)fn {
    CGKeyCode km = [(NSNumber *)[keyMap objectForKey:key] unsignedIntValue];
    [self simulateKeyCode:km ShftDown:shft CtrlDown:ctrl AltDown:alt CmdDown:cmd FnDown:fn];
}

- (void)simulateSpecialKey:(int)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSEvent *event = [NSEvent otherEventWithType:NSSystemDefined location:NSZeroPoint modifierFlags:0xa00 timestamp:0 windowNumber:0 context:NULL subtype:8 data1:(key << 16) | (0xa00) data2:-1];
    CGEventPost(kCGSessionEventTap, [event CGEvent]);

    NSEvent *event2 = [NSEvent otherEventWithType:NSSystemDefined location:NSZeroPoint modifierFlags:0xb00 timestamp:0 windowNumber:0 context:NULL subtype:8 data1:(key << 16) | (0xb00) data2:-1];
    CGEventPost(kCGSessionEventTap, [event2 CGEvent]);

    [pool release];
}

- (CGKeyCode)charToCode:(NSString*) chr {
    return [[keyMap objectForKey:chr] unsignedIntValue];
}

+ (NSString *)codeToChar:(CGKeyCode)keyCode {
    NSString *chr;
    if (keyCode == 123) { //left
        chr = @"←";
    } else if (keyCode == 124) { //right
        chr = @"→";
    } else if (keyCode == 125) { //down
        chr = @"↓";
    } else if (keyCode == 126) { //up
        chr = @"↑";
    } else if (keyCode == 36) { //return
        chr = @"↩";
    } else if (keyCode == 48) { //tab
        chr = @"Tab";
    } else if (keyCode == 49) { //space
        chr = @"Space";
    } else if (keyCode == 51) { //delete
        chr = @"⌫";
    } else if (keyCode == 53) { //escape
        chr = @"⎋";
    } else if (keyCode == 117) { //forward delete
        chr = @"⌦";
    } else if (keyCode == 76) { //enter
        chr = @"⌅";
    } else if (keyCode == 116) { //page up
        chr = @"Page Up";
    } else if (keyCode == 121) { //page down
        chr = @"Page Down";
    } else if (keyCode == 115) { //home
        chr = @"Home";
    } else if (keyCode == 119) { //end
        chr = @"End";
    } else if (keyCode == 122) { //
        chr = @"F1";
    } else if (keyCode == 120) { //
        chr = @"F2";
    } else if (keyCode == 99) { //
        chr = @"F3";
    } else if (keyCode == 118) { //
        chr = @"F4";
    } else if (keyCode == 96) { //
        chr = @"F5";
    } else if (keyCode == 97) { //
        chr = @"F6";
    } else if (keyCode == 98) { //
        chr = @"F7";
    } else if (keyCode == 100) { //
        chr = @"F8";
    } else if (keyCode == 101) { //
        chr = @"F9";
    } else if (keyCode == 109) { //
        chr = @"F10";
    } else if (keyCode == 103) { //
        chr = @"F11";
    } else if (keyCode == 111) { //
        chr = @"F12";
    } else if (keyCode == 33) { //
        chr = @"[";
    } else if (keyCode == 30) { //
        chr = @"]";

    } else {
        switch (keyCode) {
            case 0:
                chr = @"A"; break;
            case 11:
                chr = @"B"; break;
            case 8:
                chr = @"C"; break;
            case 2:
                chr = @"D"; break;
            case 14:
                chr = @"E"; break;
            case 3:
                chr = @"F"; break;
            case 5:
                chr = @"G"; break;
            case 4:
                chr = @"H"; break;
            case 34:
                chr = @"I"; break;
            case 38:
                chr = @"J"; break;
            case 40:
                chr = @"K"; break;
            case 37:
                chr = @"L"; break;
            case 46:
                chr = @"M"; break;
            case 45:
                chr = @"N"; break;
            case 31:
                chr = @"O"; break;
            case 35:
                chr = @"P"; break;
            case 12:
                chr = @"Q"; break;
            case 15:
                chr = @"R"; break;
            case 1:
                chr = @"S"; break;
            case 17:
                chr = @"T"; break;
            case 32:
                chr = @"U"; break;
            case 9:
                chr = @"V"; break;
            case 13:
                chr = @"W"; break;
            case 7:
                chr = @"X"; break;
            case 16:
                chr = @"Y"; break;
            case 6:
                chr = @"Z"; break;
            default:
                chr = [NSString stringWithFormat:@"%d", keyCode];
                break;
        }
    }
    return chr;
}

@end
