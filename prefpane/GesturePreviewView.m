//
//  GesturePreviewView.m
//  Jitouch
//
//  Copyright 2021 Supasorn Suwajanakorn and Sukolsak Sakshuwong. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GesturePreviewView.h"

@implementation GesturePreviewView

@synthesize handed, ges;

- (id)initWithDevice:(int)aDevice {
    device = aDevice;
    NSRect frameRect;
    if (device == 0)
        frameRect = NSMakeRect(0, 0, 4*50*0.9, 3*50*0.9);
    else
        frameRect = NSMakeRect(0, 0, 2.3*50*0.9, 4*50*0.9);
    if (self = [super initWithFrame:frameRect]) {
    }
    return self;
}

static inline float mylen(float dx, float dy) {
    return sqrtf(dx*dx + dy*dy);
}

- (void)drawRect:(NSRect)dirtyRect {
    CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];

    double time = counter*0.02;
    static double accumT;
    static double accumLen;
    static float lastX, lastY;
    float w = self.frame.size.width;
    float h = self.frame.size.height;
    float x, y;

    if (hg.type) {
        CGContextSetLineJoin(myContext, kCGLineJoinRound);
        CGContextSetLineCap(myContext, kCGLineCapRound);

        CGContextSetLineWidth(myContext, 7.0);
        CGContextSetRGBStrokeColor(myContext, 0.7, 0, 0, 0.6);

        CGContextMoveToPoint(myContext, hg.fg[0].x[0]*w, hg.fg[0].y[0]*h);
        for (int i = 0; i < hg.n; i++) {
            CGContextAddCurveToPoint(myContext,
                                     hg.fg[i].cpx[0]*w,
                                     hg.fg[i].cpy[0]*h,
                                     hg.fg[i].cpx[1]*w,
                                     hg.fg[i].cpy[1]*h,
                                     hg.fg[i].x[1]*w,
                                     hg.fg[i].y[1]*h);
        }
        CGContextSetRGBStrokeColor(myContext, 0, 0, 0, 0.5);
        CGContextStrokePath(myContext);
    }

    for (int i = 0; i < hg.n; i++) {
        BOOL shouldDraw = YES;
        if (hg.fg[i].t[2]!=-1 && time >= hg.fg[i].t[2] && time <= hg.fg[i].t[0]) {
            x = hg.fg[i].x[0];
            y = hg.fg[i].y[0];
        } else if (hg.fg[i].t[3]!=-1 && time >= hg.fg[i].t[1] && time <= hg.fg[i].t[3]) {
            x = hg.fg[i].x[1];
            y = hg.fg[i].y[1];
        } else if (hg.fg[i].t[0] <= time && hg.fg[i].t[1] >= time) {
            if (hg.fg[i].type == 0) {
                double t = (time - hg.fg[i].t[0]) / (hg.fg[i].t[1]-hg.fg[i].t[0]);
                // Ease function
                t = (1 - sin(3.14159/2 + t*3.14159)) / 2;
                x = hg.fg[i].x[1]*t + hg.fg[i].x[0]*(1-t);
                y = hg.fg[i].y[1]*t + hg.fg[i].y[0]*(1-t);
            } else if (hg.fg[i].type == 1) {
                double realT = (time - hg.fg[i].t[0]) / (hg.fg[i].t[1]-hg.fg[i].t[0]);

                if (i+1 != lastI) {
                    accumLen = 0;
                    accumT = 0;
                    x = hg.fg[i].x[0];
                    y = hg.fg[i].y[0];
                    lastX = x;
                    lastY = y;
                    lastI = i+1;
                }

                while (accumLen < realT * hg.fg[i].len) {
                    float t = accumT;
                    float tt = 1.0f-t;
                    x = tt*tt*tt*hg.fg[i].x[0] + 3*tt*tt*t*hg.fg[i].cpx[0] + 3*tt*t*t*hg.fg[i].cpx[1] + t*t*t*hg.fg[i].x[1];
                    y = tt*tt*tt*hg.fg[i].y[0] + 3*tt*tt*t*hg.fg[i].cpy[0] + 3*tt*t*t*hg.fg[i].cpy[1] + t*t*t*hg.fg[i].y[1];

                    float len = mylen(lastX-x, lastY-y);
                    accumLen += len;
                    lastX = x;
                    lastY = y;
                    accumT += 0.01;
                }
            }
        } else
            shouldDraw = NO;

        if (shouldDraw) {
            if (handed) x = 1.0 - x;

            x *= w;
            y *= h;
            CGFloat min = 16.0;

            x -= min / 2; // TODO: why don't we also do this with y?
            if (hg.type) y -= min / 2;

            if (hg.fg[i].pressed) {
                CGContextSetRGBFillColor(myContext, 0.6, 0, 0, 0.6);
                CGContextFillEllipseInRect(myContext, CGRectMake(x-4, y-4, min+8, min+8));

                CGContextSetBlendMode(myContext, kCGBlendModeSourceIn);
                CGContextSetRGBFillColor(myContext, 1.0, 1.0, 1.0, 0.8);
                CGContextFillEllipseInRect(myContext, CGRectMake(x-2, y-2, min+4, min+4));
                CGContextSetBlendMode(myContext, kCGBlendModeNormal);
            }
            CGContextSetRGBFillColor(myContext, 0.6, 0, 0, 0.6);
            CGContextSetLineWidth(myContext, 2.0);
            if (hg.fg[i].type == 0) {
                CGContextFillEllipseInRect(myContext, CGRectMake(x, y, min, min));
            } else {
                CGContextFillEllipseInRect(myContext, CGRectMake(x-25, y, min, min));
                CGContextFillEllipseInRect(myContext, CGRectMake(x+25, y, min, min));
                break;
            }
        }
    }

    counter++;
    if (time >= hg.t) {
        counter = 0;
        lastI = 0;
    }
}

static void setFG(FingerGesture *out, float x1, float y1, float x2, float y2, float t1, float t2) {
    out->x[0] = x1;
    out->y[0] = y1;
    out->x[1] = x2;
    out->y[1] = y2;
    out->t[0] = t1*2;
    out->t[1] = t2*2;

    out->t[2] = out->t[3] = -1;
    out->type = 0;
}
static void setFG2(FingerGesture *out, float x1, float y1, float x2, float y2, float t0, float t1, float t2, float t3) {
    setFG(out, x1, y1, x2, y2, t0, t1);
    out->t[2] = t2*2;
    out->t[3] = t3*2;
}

static void setFGx(FingerGesture *out, float x1, float y1, float x2, float y2, float t1, float t2) {
    setFG(out, x1, y1, x2, y2, t1, t2);
    out->pressed = 1;
}


- (void)createOneFixTwoTap:(int)type {
    hg.n = 3;
    hg.t = 1*2;
    float s[2] = {0, 0};
    if (type == 0) {
        setFG(&hg.fg[0], s[0]+0.36, s[1]+0.5,  s[0]+0.36, s[1]+0.5, 0, 1);
        setFG(&hg.fg[1], s[0]+0.50, s[1]+0.53, s[0]+0.50, s[1]+0.53, 0.4, 0.55);
        setFG(&hg.fg[2], s[0]+0.64, s[1]+0.51, s[0]+0.64, s[1]+0.51, 0.4, 0.55);
    } else if (type == 1) {
        setFG(&hg.fg[0], s[0]+0.36, s[1]+0.5,  s[0]+0.36, s[1]+0.5, 0.4, 0.55);
        setFG(&hg.fg[1], s[0]+0.50, s[1]+0.53, s[0]+0.50, s[1]+0.53, 0, 1);
        setFG(&hg.fg[2], s[0]+0.64, s[1]+0.51, s[0]+0.64, s[1]+0.51, 0.4, 0.55);
    } else if (type == 2) {
        setFG(&hg.fg[0], s[0]+0.36, s[1]+0.5,  s[0]+0.36, s[1]+0.5, 0.4, 0.55);
        setFG(&hg.fg[1], s[0]+0.50, s[1]+0.53, s[0]+0.50, s[1]+0.53, 0.4, 0.55);
        setFG(&hg.fg[2], s[0]+0.64, s[1]+0.51, s[0]+0.64, s[1]+0.51, 0, 1);
    }
}

- (void)createThreeFingerTap {
    hg.n = 9;
    hg.t = 3.8*2;
    float s[2] = {0, 0};
    setFG(&hg.fg[0], s[0]+0.36, s[1]+0.5, s[0]+0.36, s[1]+0.5, 0.25, 0.4);
    setFG(&hg.fg[1], s[0]+0.50, s[1]+0.53, s[0]+0.50, s[1]+0.53, 0.25, 0.4);
    setFG(&hg.fg[2], s[0]+0.64, s[1]+0.51, s[0]+0.64, s[1]+0.51, 0.25, 0.4);

    setFG(&hg.fg[3], s[0]+0.36, s[1]+0.5, s[0]+0.36, s[1]+0.5, 1, 1.9);
    setFG(&hg.fg[4], s[0]+0.50, s[1]+0.53, s[0]+0.50, s[1]+0.53, 1.5, 1.65);
    setFG(&hg.fg[5], s[0]+0.64, s[1]+0.51, s[0]+0.64, s[1]+0.51, 1.5, 1.65);

    setFG(&hg.fg[6], s[0]+0.36, s[1]+0.5, s[0]+0.36, s[1]+0.5, 3, 3.15);
    setFG(&hg.fg[7], s[0]+0.50, s[1]+0.53, s[0]+0.50, s[1]+0.53, 2.5, 3.5);
    setFG(&hg.fg[8], s[0]+0.64, s[1]+0.51, s[0]+0.64, s[1]+0.51, 3, 3.15);
}

- (void)createThreeFingerClick {
    hg.n = 6;
    hg.t = 0.7*2;
    float s[2] = {0, 0};
    setFG(&hg.fg[0], s[0]+0.36, s[1]+0.5, s[0]+0.36, s[1]+0.5, 0, 1);
    setFG(&hg.fg[1], s[0]+0.50, s[1]+0.53, s[0]+0.50, s[1]+0.53, 0, 1);
    setFG(&hg.fg[2], s[0]+0.64, s[1]+0.51, s[0]+0.64, s[1]+0.51, 0, 1);
    setFGx(&hg.fg[3], s[0]+0.36, s[1]+0.5, s[0]+0.36, s[1]+0.5, 0.25, 0.4);
    setFGx(&hg.fg[4], s[0]+0.50, s[1]+0.53, s[0]+0.50, s[1]+0.53, 0.25, 0.4);
    setFGx(&hg.fg[5], s[0]+0.64, s[1]+0.51, s[0]+0.64, s[1]+0.51, 0.25, 0.4);
}

- (void)createThreeFingerPinchIn {
    hg.n = 3;
    hg.t = 1*2;

    setFG(&hg.fg[0], 0.50, 0.51, 0.50, 0.5, 0, 0.37);

    setFG2(&hg.fg[1], 0.31, 0.48, 0.36, 0.48, 0.04, 0.29, 0.0, 0.37);
    setFG2(&hg.fg[2], 0.69, 0.48, 0.64, 0.48, 0.04, 0.29, 0.0, 0.37);
}

- (void)createThreeFingerPinchOut {
    hg.n = 3;
    hg.t = 1*2;

    setFG(&hg.fg[0], 0.50, 0.5, 0.50, 0.51, 0, 0.37);

    setFG2(&hg.fg[1], 0.36, 0.48, 0.31, 0.48, 0.04, 0.29, 0.0, 0.37);
    setFG2(&hg.fg[2], 0.64, 0.48, 0.69, 0.48, 0.04, 0.29, 0.0, 0.37);

}

- (void)createFourFingerTap {
    hg.n = 8;
    hg.t = 2.5*2;
    float s[2] = {0, 0};
    setFG(&hg.fg[0], s[0]+0.29, s[1]+0.5, s[0]+0.29, s[1]+0.5, 0.25, 0.4);
    setFG(&hg.fg[1], s[0]+0.43, s[1]+0.53, s[0]+0.43, s[1]+0.53, 0.25, 0.4);
    setFG(&hg.fg[2], s[0]+0.57, s[1]+0.51, s[0]+0.57, s[1]+0.51, 0.25, 0.4);
    setFG(&hg.fg[3], s[0]+0.71, s[1]+0.48, s[0]+0.71, s[1]+0.48, 0.25, 0.4);

    setFG(&hg.fg[4], s[0]+0.29, s[1]+0.5, s[0]+0.29, s[1]+0.5, 1, 1.9);
    setFG(&hg.fg[5], s[0]+0.43, s[1]+0.53, s[0]+0.43, s[1]+0.53, 1.5, 1.65);
    setFG(&hg.fg[6], s[0]+0.57, s[1]+0.51, s[0]+0.57, s[1]+0.51, 1.5, 1.65);
    setFG(&hg.fg[7], s[0]+0.71, s[1]+0.48, s[0]+0.71, s[1]+0.48, 1.5, 1.65);
}

- (void)createFourFingerClick {
    hg.n = 8;
    hg.t = 0.7*2;
    setFG(&hg.fg[0], 0.29, 0.5, 0.29, 0.5, 0, 1);
    setFG(&hg.fg[1], 0.43, 0.53, 0.43, 0.53, 0, 1);
    setFG(&hg.fg[2], 0.57, 0.51, 0.57, 0.51, 0, 1);
    setFG(&hg.fg[3], 0.71, 0.48, 0.71, 0.48, 0, 1);
    setFGx(&hg.fg[4], 0.29, 0.5, 0.29, 0.5, 0.25, 0.4);
    setFGx(&hg.fg[5], 0.43, 0.53, 0.43, 0.53, 0.25, 0.4);
    setFGx(&hg.fg[6], 0.57, 0.51, 0.57, 0.51, 0.25, 0.4);
    setFGx(&hg.fg[7], 0.71, 0.48, 0.71, 0.48, 0.25, 0.4);
}

- (void)createOneFixTwoSlideUp {
    hg.n = 3;
    hg.t = 1.1*2;
    float s[2] = {0, 0};
    setFG(&hg.fg[0], s[0]+0.36, s[1]+0.5, s[0]+0.36, s[1]+0.5, 0, 1.1);
    setFG2(&hg.fg[1], s[0]+0.50, s[1]+0.41,  s[0]+0.50, s[1]+0.62, 0.4, 0.8, 0.33, 1);
    setFG2(&hg.fg[2], s[0]+0.64, s[1]+0.38, s[0]+0.64, s[1]+0.6, 0.4, 0.8, 0.33, 1);
}

- (void)createOneFixTwoSlideDown {
    hg.n = 3;
    hg.t = 1.1*2;
    float s[2] = {0, 0};
    setFG(&hg.fg[0], s[0]+0.36, s[1]+0.5,  s[0]+0.36, s[1]+0.5, 0, 1.1);
    setFG2(&hg.fg[1], s[0]+0.50, s[1]+0.62,  s[0]+0.50, s[1]+0.41, 0.4, 0.8, 0.33, 1);
    setFG2(&hg.fg[2], s[0]+0.64, s[1]+0.60, s[0]+0.64, s[1]+0.38, 0.4, 0.8, 0.33, 1);
}

- (void)createOneFixPressTwoSlideUp {
    hg.n = 3;
    hg.t = 1.1*2;
    float s[2] = {0, 0};
    setFGx(&hg.fg[0], s[0]+0.36, s[1]+0.5, s[0]+0.36, s[1]+0.5, 0, 1.1);
    setFG2(&hg.fg[1], s[0]+0.50, s[1]+0.41,  s[0]+0.50, s[1]+0.62, 0.4, 0.8, 0.33, 1);
    setFG2(&hg.fg[2], s[0]+0.64, s[1]+0.38, s[0]+0.64, s[1]+0.6, 0.4, 0.8, 0.33, 1);
}

- (void)createOneFixPressTwoSlideDown {
    hg.n = 3;
    hg.t = 1.1*2;
    float s[2] = {0, 0};
    setFGx(&hg.fg[0], s[0]+0.36, s[1]+0.5,  s[0]+0.36, s[1]+0.5, 0, 1.1);
    setFG2(&hg.fg[1], s[0]+0.50, s[1]+0.62,  s[0]+0.50, s[1]+0.41, 0.4, 0.8, 0.33, 1);
    setFG2(&hg.fg[2], s[0]+0.64, s[1]+0.60, s[0]+0.64, s[1]+0.38, 0.4, 0.8, 0.33, 1);
}

/*
- (void)createOneFixThreeSlide {
    hg.n = 4;
    hg.t = 1.1*2;
    float s[2] = {0, 0};
    setFG(&hg.fg[0], s[0]+0.29, s[1]+0.5,  s[0]+0.29, s[1]+0.5, 0, 1.1);
    setFG2(&hg.fg[1], s[0]+0.43, s[1]+0.62,  s[0]+0.43, s[1]+0.41, 0.4, 0.8, 0.33, 1);
    setFG2(&hg.fg[2], s[0]+0.57, s[1]+0.60, s[0]+0.57, s[1]+0.38, 0.4, 0.8, 0.33, 1);
    setFG2(&hg.fg[3], s[0]+0.71, s[1]+0.55, s[0]+0.71, s[1]+0.38, 0.4, 0.8, 0.33, 1);
}
 */

- (void)createIndexToPinky {
    hg.n = 4;
    hg.t = 1*2;
    float s[2] = {0, 0.15};
    setFG(&hg.fg[0], s[0]+0.29, s[1]+0.3, s[0]+0.29, s[1]+0.3, 0, 0.4);
    setFG(&hg.fg[1], s[0]+0.43, s[1]+0.36, s[0]+0.43, s[1]+0.36, 0.1, 0.4);
    setFG(&hg.fg[2], s[0]+0.57, s[1]+0.335, s[0]+0.57, s[1]+0.335, 0.2, 0.4);
    setFG(&hg.fg[3], s[0]+0.71, s[1]+0.28, s[0]+0.71, s[1]+0.28, 0.3, 0.4);
}
- (void)createPinkyToIndex {
    hg.n = 4;
    hg.t = 1*2;
    float s[2] = {0, 0.15};
    setFG(&hg.fg[0], s[0]+0.29, s[1]+0.3, s[0]+0.29, s[1]+0.3, 0.3, 0.4);
    setFG(&hg.fg[1], s[0]+0.43, s[1]+0.36, s[0]+0.43, s[1]+0.36, 0.2, 0.4);
    setFG(&hg.fg[2], s[0]+0.57, s[1]+0.335, s[0]+0.57, s[1]+0.335, 0.1, 0.4);
    setFG(&hg.fg[3], s[0]+0.71, s[1]+0.28, s[0]+0.71, s[1]+0.28, 0, 0.4);
}


- (void)createOneFixLeftTap {
    hg.n = 2;
    hg.t = 0.6*2;
    float s[2] = {0, 0};
    setFG(&hg.fg[0], s[0]+0.36, s[1]+0.49, s[0]+0.36, s[1]+0.49, 0.3, 0.3+0.15);
    setFG(&hg.fg[1], s[0]+0.50, s[1]+0.5, s[0]+0.50, s[1]+0.5, 0, 1.0);
}
- (void)createOneFixRightTap {
    hg.n = 2;
    hg.t = 0.6*2;
    float s[2] = {0, 0};
    setFG(&hg.fg[0], s[0]+0.50, s[1]+0.5, s[0]+0.50, s[1]+0.5, 0, 1.0);
    setFG(&hg.fg[1], s[0]+0.64, s[1]+0.49, s[0]+0.64, s[1]+0.49, 0.3, 0.3+0.15);
}
- (void)createMoveResize {
    hg.n = 4;
    hg.t = 3*2;
    float s[2] = {0, 0};
    setFG(&hg.fg[0], s[0]+0.43, s[1]+0.5,  s[0]+0.43, s[1]+0.5, 0, 3);
    setFG2(&hg.fg[1], s[0]+0.57, s[1]+0.57,  s[0]+0.57, s[1]+0.43, 0.4, 0.8, 0.33, 1);
    setFG(&hg.fg[2], s[0]+0.57, s[1]+0.5,  s[0]+0.57, s[1]+0.5, 1.5, 1.65);
    setFG2(&hg.fg[3], s[0]+0.57, s[1]+0.43,  s[0]+0.57, s[1]+0.57, 2.15, 2.55, 2.08, 2.75 );
}


- (void)createTwoFixOneSlideUp {
    hg.n = 3;
    hg.t = 1*2;

    setFG(&hg.fg[0], 0.50, 0.5, 0.50, 0.5, 0, 4);
    setFG(&hg.fg[1], 0.64, 0.49, 0.64, 0.49, 0, 4);

    setFG2(&hg.fg[2], 0.36, 0.45, 0.36, 0.53, 0.5, 0.75, 0.46, 0.83);
}

- (void)createTwoFixOneSlideDown {
    hg.n = 3;
    hg.t = 1*2;

    setFG(&hg.fg[0], 0.50, 0.5, 0.50, 0.5, 0, 4);
    setFG(&hg.fg[1], 0.64, 0.49, 0.64, 0.49, 0, 4);

    setFG2(&hg.fg[2], 0.36, 0.53, 0.36, 0.45, 0.5, 0.75, 0.46, 0.83);
}

- (void)createTwoFixOneSlideLeft {
    hg.n = 3;
    hg.t = 1*2;

    setFG(&hg.fg[0], 0.50, 0.5, 0.50, 0.5, 0, 4);
    setFG(&hg.fg[1], 0.64, 0.49, 0.64, 0.49, 0, 4);

    setFG2(&hg.fg[2], 0.36, 0.48, 0.31, 0.48, 0.5, 0.75, 0.46, 0.83);
}

- (void)createTwoFixOneSlideRight {
    hg.n = 3;
    hg.t = 1*2;

    setFG(&hg.fg[0], 0.50, 0.5, 0.50, 0.5, 0, 4);
    setFG(&hg.fg[1], 0.64, 0.49, 0.64, 0.49, 0, 4);

    setFG2(&hg.fg[2], 0.31, 0.48, 0.36, 0.48, 0.5, 0.75, 0.46, 0.83);
}

- (void)createTwoFixOneDoubleTap:(int)type {
    hg.n = 4;
    hg.t = 1*2;
    if (type == 0) {
        setFG(&hg.fg[0], 0.50, 0.53, 0.50, 0.53, 0, 1);
        setFG(&hg.fg[1], 0.64, 0.51, 0.64, 0.51, 0, 1);

        setFG(&hg.fg[2], 0.36, 0.5,  0.36, 0.5, 0.5, 0.6);
        setFG(&hg.fg[3], 0.36, 0.5,  0.36, 0.5, 0.7, 0.8);
    } else if (type == 1) {
        setFG(&hg.fg[0], 0.36, 0.5,  0.36, 0.5, 0, 1);
        setFG(&hg.fg[1], 0.64, 0.51, 0.64, 0.51, 0, 1);

        setFG(&hg.fg[2], 0.50, 0.53, 0.50, 0.53, 0.5, 0.6);
        setFG(&hg.fg[3], 0.50, 0.53, 0.50, 0.53, 0.7, 0.8);
    } else {
        setFG(&hg.fg[0], 0.36, 0.5,  0.36, 0.5, 0, 1);
        setFG(&hg.fg[1], 0.50, 0.53, 0.50, 0.53, 0, 1);

        setFG(&hg.fg[2], 0.64, 0.51, 0.64, 0.51, 0.5, 0.6);
        setFG(&hg.fg[3], 0.64, 0.51, 0.64, 0.51, 0.7, 0.8);

    }

}
- (void)createRightSideScroll {
    hg.n = 6;
    hg.t = 2.1*2;
    setFG2(&hg.fg[0], 0.95, 0.5, 0.95, 0.6, 0.2, 0.8, 0.1, 0.8);
    setFG2(&hg.fg[1], 0.85, 0.5, 0.85, 0.6, 0.2, 0.8, 0.1, 0.8);
    setFG2(&hg.fg[2], 0.95, 0.6, 0.95, 0.4, 0.8, 1.4, 0.8, 1.4);
    setFG2(&hg.fg[3], 0.85, 0.6, 0.85, 0.4, 0.8, 1.4, 0.8, 1.4);
    setFG2(&hg.fg[4], 0.95, 0.4, 0.95, 0.5, 1.4, 2.0, 1.4, 2.1);
    setFG2(&hg.fg[5], 0.85, 0.4, 0.85, 0.5, 1.4, 2.0, 1.4, 2.1);
}
- (void)createLeftSideScroll {
    hg.n = 6;
    hg.t = 2.1*2;
    setFG2(&hg.fg[0], 0.05, 0.5, 0.05, 0.6, 0.2, 0.8, 0.1, 0.8);
    setFG2(&hg.fg[1], 0.15, 0.5, 0.15, 0.6, 0.2, 0.8, 0.1, 0.8);
    setFG2(&hg.fg[2], 0.05, 0.6, 0.05, 0.4, 0.8, 1.4, 0.8, 1.4);
    setFG2(&hg.fg[3], 0.15, 0.6, 0.15, 0.4, 0.8, 1.4, 0.8, 1.4);
    setFG2(&hg.fg[4], 0.05, 0.4, 0.05, 0.5, 1.4, 2.0, 1.4, 2.1);
    setFG2(&hg.fg[5], 0.15, 0.4, 0.15, 0.5, 1.4, 2.0, 1.4, 2.1);
}

- (void)createThreeSwipeUp {
    hg.n = 3;
    hg.t = 0.8*2;
    setFG2(&hg.fg[0], 0.36, 0.43, 0.36, 0.57, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[1], 0.50, 0.46, 0.50, 0.60, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[2], 0.64, 0.43, 0.64, 0.57, 0.3, 0.55, 0.0, 0.63);
}

- (void)createThreeSwipeDown {
    hg.n = 3;
    hg.t = 0.8*2;
    setFG2(&hg.fg[0], 0.36, 0.57, 0.36, 0.43, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[1], 0.50, 0.60, 0.50, 0.46, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[2], 0.64, 0.57, 0.64, 0.43, 0.3, 0.55, 0.0, 0.63);
}

- (void)createThreeSwipeLeft {
    hg.n = 3;
    hg.t = 0.8*2;
    setFG2(&hg.fg[0], 0.36+0.07, 0.50, 0.36-0.07, 0.50, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[1], 0.50+0.07, 0.53, 0.50-0.07, 0.53, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[2], 0.64+0.07, 0.50, 0.64-0.07, 0.50, 0.3, 0.55, 0.0, 0.63);
}

- (void)createThreeSwipeRight {
    hg.n = 3;
    hg.t = 0.8*2;
    setFG2(&hg.fg[0], 0.36-0.07, 0.50, 0.36+0.07, 0.50, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[1], 0.50-0.07, 0.53, 0.50+0.07, 0.53, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[2], 0.64-0.07, 0.50, 0.64+0.07, 0.50, 0.3, 0.55, 0.0, 0.63);
}

- (void)createFourSwipeUp {
    hg.n = 4;
    hg.t = 0.8*2;
    setFG2(&hg.fg[0], 0.29, 0.43, 0.29, 0.57, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[1], 0.43, 0.46, 0.43, 0.60, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[2], 0.57, 0.46, 0.57, 0.60, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[3], 0.71, 0.43, 0.71, 0.57, 0.3, 0.55, 0.0, 0.63);
}

- (void)createFourSwipeDown {
    hg.n = 4;
    hg.t = 0.8*2;
    setFG2(&hg.fg[0], 0.29, 0.57, 0.29, 0.43, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[1], 0.43, 0.60, 0.43, 0.46, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[2], 0.57, 0.60, 0.57, 0.46, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[3], 0.71, 0.57, 0.71, 0.43, 0.3, 0.55, 0.0, 0.63);
}

- (void)createFourSwipeLeft {
    hg.n = 4;
    hg.t = 0.8*2;
    setFG2(&hg.fg[0], 0.29+0.07, 0.50, 0.29-0.07, 0.50, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[1], 0.43+0.07, 0.53, 0.43-0.07, 0.53, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[2], 0.57+0.07, 0.53, 0.57-0.07, 0.53, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[3], 0.71+0.07, 0.50, 0.71-0.07, 0.50, 0.3, 0.55, 0.0, 0.63);
}

- (void)createFourSwipeRight {
    hg.n = 4;
    hg.t = 0.8*2;
    setFG2(&hg.fg[0], 0.29-0.07, 0.50, 0.29+0.07, 0.50, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[1], 0.43-0.07, 0.53, 0.43+0.07, 0.53, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[2], 0.57-0.07, 0.53, 0.57+0.07, 0.53, 0.3, 0.55, 0.0, 0.63);
    setFG2(&hg.fg[3], 0.71-0.07, 0.50, 0.71+0.07, 0.50, 0.3, 0.55, 0.0, 0.63);
}

- (void)createMiddleFixIndexNearTap {
    hg.n = 2;
    hg.t = 0.6*2;
    setFG(&hg.fg[0], 0.50, 0.75, 0.50, 0.75, 0.3, 0.3+0.15);
    setFG(&hg.fg[1], 0.75, 0.75, 0.75, 0.75, 0, 1.0);
}

- (void)createMiddleFixIndexFarTap {
    hg.n = 2;
    hg.t = 0.6*2;
    setFG(&hg.fg[0], 0.25, 0.75, 0.25, 0.75, 0.3, 0.3+0.15);
    setFG(&hg.fg[1], 0.75, 0.75, 0.75, 0.75, 0, 1.0);
}

- (void)createIndexFixMiddleNearTap {
    hg.n = 2;
    hg.t = 0.6*2;
    setFG(&hg.fg[0], 0.50, 0.75, 0.50, 0.75, 0.3, 0.3+0.15);
    setFG(&hg.fg[1], 0.25, 0.75, 0.25, 0.75, 0, 1.0);
}

- (void)createIndexFixMiddleFarTap {
    hg.n = 2;
    hg.t = 0.6*2;
    setFG(&hg.fg[0], 0.75, 0.75, 0.75, 0.75, 0.3, 0.3+0.15);
    setFG(&hg.fg[1], 0.25, 0.75, 0.25, 0.75, 0, 1.0);
}

- (void)bezier:(float*)a n:(int)n {
    hg.n = n;

    double accumT = 0;
    for (int i = 0; i < n; i++) {
        hg.fg[i].x[0] = a[i*8 + 0]*0.4 + 0.3;
        hg.fg[i].y[0] = a[i*8 + 1]*0.5 + 0.25;
        hg.fg[i].cpx[0] = a[i*8 + 2]*0.4 + 0.3;
        hg.fg[i].cpy[0] = a[i*8 + 3]*0.5 + 0.25;
        hg.fg[i].cpx[1] = a[i*8 + 4]*0.4 + 0.3;
        hg.fg[i].cpy[1] = a[i*8 + 5]*0.5 + 0.25;
        hg.fg[i].x[1] = a[i*8 + 6]*0.4 + 0.3;
        hg.fg[i].y[1] = a[i*8 + 7]*0.5 + 0.25;

        float len = 0;
        float t = 0;
        float x, y, lastX, lastY;
        while (t < 1) {
            x = (1-t)*(1-t)*(1-t)*hg.fg[i].x[0] + 3*(1-t)*(1-t)*t*hg.fg[i].cpx[0] + 3*(1-t)*t*t*hg.fg[i].cpx[1] + t*t*t*hg.fg[i].x[1];
            y = (1-t)*(1-t)*(1-t)*hg.fg[i].y[0] + 3*(1-t)*(1-t)*t*hg.fg[i].cpy[0] + 3*(1-t)*t*t*hg.fg[i].cpy[1] + t*t*t*hg.fg[i].y[1];
            if (t == 0) {
                lastX = x;
                lastY = y;
            }
            len += mylen(lastX-x, lastY-y);
            t += 0.01;
            lastX = x;
            lastY = y;
        }

        hg.fg[i].t[0] = accumT;
        hg.fg[i].t[1] = accumT + len*1.7;
        hg.fg[i].len = len;
        accumT += len*1.7;
        hg.fg[i].t[2] = hg.fg[i].t[3] = -1;
        hg.fg[i].type = 1;
    }
    hg.fg[n-1].t[2] = hg.fg[n-1].t[0];
    hg.fg[n-1].t[3] = hg.fg[n-1].t[1]+0.3;
    hg.t = accumT + 1.0;
    hg.type = 1;
}


- (void)createA {
    float a[] = {
        0.130, 0.010, 0.130, 0.010, 0.500, 1.000, 0.520, 1.000,
        0.520, 1.000, 0.520, 1.000, 0.870, 0.000, 0.870, 0.000
    };
    [self bezier:a n:2];
}

- (void)createB {
    float a[] = {
        0.230, 0.010, 0.230, 0.010, 0.240, 0.990, 0.230, 1.000,
        0.230, 1.000, 0.970, 1.000, 0.730, 0.520, 0.380, 0.510,
        0.380, 0.510, 1.170, 0.490, 0.740, 0.000, 0.370, 0.010
    };
    [self bezier:a n:3];
}

- (void)createC {
    float a[] = {
        0.850, 0.900, -0.130, 1.410, -0.110, -0.410, 0.830, 0.100
    };
    [self bezier:a n:1];
}

- (void)createD {
    float a[] = {
        0.160, 0.000, 0.160, 0.000, 0.160, 0.990, 0.170, 0.990,
        0.170, 0.990, 1.060, 0.980, 1.150, 0.000, 0.300, 0.000
    };
    [self bezier:a n:2];
}

- (void)createE {
    float a[] = {
        0.730, 0.980, 0.070, 1.100, 0.110, 0.490, 0.630, 0.500,
        0.630, 0.500, 0.040, 0.500, 0.110, -0.150, 0.710, 0.040
    };
    [self bezier:a n:2];
}

- (void)createF {
    float a[] = {
        0.820, 1.000, 0.820, 1.000, 0.210, 1.000, 0.210, 1.000,
        0.210, 1.000, 0.210, 1.000, 0.210, -0.010, 0.210, -0.010
    };
    [self bezier:a n:2];
}

- (void)createG {
    float a[] = {
        0.810, 0.860, 0.510, 1.150, 0.090, 0.910, 0.100, 0.450,
        0.100, 0.450, 0.090, -0.080, 0.870, -0.180, 0.870, 0.450,
        0.870, 0.450, 0.870, 0.440, 0.400, 0.450, 0.400, 0.450
    };
    [self bezier:a n:3];
}

- (void)createH {
    float a[] = {
        0.190, 0.990, 0.190, 0.990, 0.190, 0.000, 0.190, 0.000,
        0.190, 0.000, 0.220, 0.790, 0.830, 0.650, 0.820, 0.000
    };
    [self bezier:a n:2];
}

- (void)createI {
    float a[] = {
        0.480, 0.990, 0.480, 0.990, 0.480, 0.000, 0.480, 0.000
    };
    [self bezier:a n:1];
}

- (void)createJ {
    float a[] = {
        0.680, 0.990, 0.670, 0.990, 0.670, 0.330, 0.670, 0.330,
        0.670, 0.330, 0.660, -0.220, 0.310, 0.080, 0.260, 0.280
    };
    [self bezier:a n:2];
}

- (void)createK {
    float a[] = {
        0.820, 1.000, 0.820, 1.000, 0.170, 0.000, 0.170, 0.000,
        0.170, 0.000, 0.170, 0.000, 0.170, 1.000, 0.170, 1.000,
        0.170, 1.000, 0.170, 1.000, 0.860, 0.010, 0.860, 0.010
    };
    [self bezier:a n:3];
}

- (void)createL {
    float a[] = {
        0.200, 0.990, 0.200, 0.990, 0.200, 0.000, 0.200, 0.000,
        0.200, 0.000, 0.200, 0.000, 0.830, 0.000, 0.830, 0.000
    };
    [self bezier:a n:2];
}

- (void)createM {
    float a[] = {
        0.010, 0.010, 0.010, 0.010, 0.010, 0.990, 0.010, 0.990,
        0.010, 0.990, 0.010, 0.990, 0.510, 0.000, 0.510, 0.000,
        0.510, 0.000, 0.510, 0.000, 0.990, 1.000, 0.990, 1.000,
        0.990, 1.000, 0.990, 1.000, 0.990, 0.000, 0.990, 0.000
    };
    [self bezier:a n:4];
}

- (void)createN {
    float a[] = {
        0.160, 0.010, 0.160, 0.010, 0.170, 1.000, 0.170, 1.000,
        0.170, 1.000, 0.170, 1.000, 0.840, 0.020, 0.840, 0.020,
        0.840, 0.020, 0.840, 0.020, 0.840, 1.000, 0.840, 1.000
    };
    [self bezier:a n:3];
}

- (void)createO {
    float a[] = {
        0.440, 0.990, -0.080, 0.950, -0.010, 0.020, 0.500, 0.010,
        0.500, 0.010, 1.010, 0.030, 1.090, 0.990, 0.580, 0.990
    };
    [self bezier:a n:2];
}

- (void)createP {
    float a[] = {
        0.240, 0.010, 0.240, 0.010, 0.240, 0.990, 0.240, 0.990,
        0.240, 0.990, 1.120, 1.000, 0.810, 0.490, 0.370, 0.480
    };
    [self bezier:a n:2];
}

- (void)createQ {
    float a[] = {
        0.410, 0.990, -0.010, 0.980, 0.000, 0.010, 0.500, 0.020,
        0.500, 0.020, 0.990, 0.020, 1.030, 0.970, 0.580, 0.990,
        0.580, 0.990, 0.430, 0.980, 0.750, 0.100, 0.830, 0.060
    };
    [self bezier:a n:3];
}

- (void)createR {
    float a[] = {
        0.250, 0.000, 0.250, 0.000, 0.240, 1.000, 0.250, 1.000,
        0.250, 1.000, 0.980, 1.000, 0.930, 0.470, 0.380, 0.490,
        0.380, 0.490, 0.380, 0.480, 0.800, 0.010, 0.800, 0.010
    };
    [self bezier:a n:3];
}

- (void)createS {
    float a[] = {
        0.740, 0.920, 0.260, 1.200, -0.010, 0.570, 0.470, 0.510,
        0.470, 0.510, 1.050, 0.450, 0.740, -0.300, 0.210, 0.160
    };
    [self bezier:a n:2];
}

- (void)createT {
    float a[] = {
        0.170, 1.000, 0.170, 1.000, 0.810, 0.990, 0.810, 0.990,
        0.810, 0.990, 0.810, 0.990, 0.810, 0.000, 0.810, 0.000
    };
    [self bezier:a n:2];
}

- (void)createU {
    float a[] = {
        0.160, 1.000, 0.160, 1.000, 0.160, 0.400, 0.160, 0.410,
        0.160, 0.410, 0.160, -0.110, 0.830, -0.110, 0.830, 0.400,
        0.830, 0.400, 0.830, 0.390, 0.830, 1.000, 0.830, 1.000
    };
    [self bezier:a n:3];
}

- (void)createV {
    float a[] = {
        0.140, 1.000, 0.140, 1.000, 0.520, 0.010, 0.530, 0.010,
        0.530, 0.010, 0.520, 0.000, 0.850, 1.000, 0.850, 1.000
    };
    [self bezier:a n:2];
}

- (void)createW {
    float a[] = {
        0.010, 0.990, 0.010, 0.990, 0.220, 0.000, 0.220, 0.000,
        0.220, 0.000, 0.220, 0.000, 0.490, 1.000, 0.490, 1.000,
        0.490, 1.000, 0.490, 1.000, 0.770, 0.000, 0.770, 0.000,
        0.770, 0.000, 0.770, 0.000, 0.990, 1.000, 0.990, 1.000
    };
    [self bezier:a n:4];
}

- (void)createX {
    float a[] = {
        0.130, 0.010, 0.130, 0.010, 0.850, 1.000, 0.850, 1.000,
        0.850, 1.000, 0.850, 1.000, 0.130, 1.000, 0.130, 1.000,
        0.130, 1.000, 0.130, 1.000, 0.840, 0.010, 0.840, 0.010
    };
    [self bezier:a n:3];
}

- (void)createY {
    float a[] = {
        0.160, 1.000, 0.180, 0.340, 0.800, 0.330, 0.850, 1.000,
        0.850, 1.000, 0.850, 1.000, 0.780, 0.010, 0.330, 0.020
    };
    [self bezier:a n:2];
}

- (void)createZ {
    float a[] = {
        0.150, 0.990, 0.150, 0.990, 0.860, 0.990, 0.860, 0.990,
        0.860, 0.990, 0.860, 0.990, 0.160, 0.010, 0.160, 0.010,
        0.160, 0.010, 0.160, 0.010, 0.830, 0.010, 0.830, 0.010
    };
    [self bezier:a n:3];
}



- (void)createLeft {
    float a[] = {
        0.830, 0.500, 0.830, 0.500, 0.200, 0.500, 0.200, 0.500
    };
    [self bezier:a n:1];
}
- (void)createRight {
    float a[] = {
        0.200, 0.500, 0.200, 0.500, 0.830, 0.500, 0.830, 0.500
    };
    [self bezier:a n:1];
}
- (void)createUp {
    float a[] = {
        0.50, 0.200, 0.50, 0.200, 0.50, 0.830, 0.50, 0.830
    };
    [self bezier:a n:1];
}

- (void)createDown {
    float a[] = {
        0.50, 0.830, 0.50, 0.830, 0.50, 0.200, 0.50, 0.200
    };
    [self bezier:a n:1];}

- (void)createRightLeft {
    float a[] = {
        0.200, 0.500, 0.200, 0.500, 0.830, 0.500, 0.830, 0.500,
        0.830, 0.500, 0.830, 0.500, 0.200, 0.500, 0.200, 0.500
    };
    [self bezier:a n:2];
}
- (void)createLeftRight {
    float a[] = {
        0.830, 0.500, 0.830, 0.500, 0.200, 0.500, 0.200, 0.500,
        0.200, 0.500, 0.200, 0.500, 0.830, 0.500, 0.830, 0.500
    };
    [self bezier:a n:2];
}
- (void)createUpRight {
    float a[] = {
        0.210, -0.010, 0.210, -0.010, 0.210, 1.000, 0.210, 1.000,
        0.210, 1.000, 0.210, 1.000, 0.820, 1.000, 0.820, 1.000
    };
    [self bezier:a n:2];
}
- (void)createUpLeft {
    float a[] = {
        0.810, 0.000, 0.810, 0.000, 0.810, 0.990, 0.810, 0.990,
        0.810, 0.990, 0.810, 0.990, 0.170, 1.000, 0.170, 1.000
    };
    [self bezier:a n:2];
}
- (void)createRightUp {
    float a[] = {
        0.170, 0, 0.170, 0, 0.810, 0, 0.810, 0,
        0.810, 0.000, 0.810, 0.000, 0.810, 0.990, 0.810, 0.990
    };
    [self bezier:a n:2];
}
- (void)createLeftUp {
    float a[] = {
        0.830, 0.000, 0.830, 0.000, 0.200, 0.000, 0.200, 0.000,
        0.200, 0.000, 0.200, 0.000, 0.200, 0.990, 0.200, 0.990

    };
    [self bezier:a n:2];
}
- (void)createSUp {
    float a[] = {
        0.2, 0.2, 0.2, 0.2, 0.7, 0.7, 0.7, 0.7
    };
    [self bezier:a n:1];
}
- (void)createSDown {
    float a[] = {
        0.7, 0.7, 0.7, 0.7, 0.2, 0.2, 0.2, 0.2
    };
    [self bezier:a n:1];
}
- (void)createBSUp {
    float a[] = {
        0.7, 0.2, 0.7, 0.2, 0.2, 0.7, 0.2, 0.7
    };
    [self bezier:a n:1];
}
- (void)createBSDown {
    float a[] = {
        0.2, 0.7, 0.2, 0.7, 0.7, 0.2, 0.7, 0.2
    };
    [self bezier:a n:1];
}
- (void)createMMOneFixLeftTap { //TODO: fix
    hg.n = 2;
    hg.t = 0.6*2;
    setFG(&hg.fg[0], 0.30, 0.75, 0.30, 0.75, 0.3, 0.3+0.15);
    setFG(&hg.fg[1], 0.70, 0.75, 0.70, 0.75, 0, 1.0);
}
- (void)createMMOneFixRightTap { //TODO: fix
    hg.n = 2;
    hg.t = 0.6*2;
    setFG(&hg.fg[0], 0.30, 0.75, 0.30, 0.75, 0, 1.0);
    setFG(&hg.fg[1], 0.70, 0.75, 0.70, 0.75, 0.3, 0.3+0.15);
}

- (void)createMMMiddleFixIndexSlideLeft {

    hg.n = 2;
    hg.t = 1*2;
    setFG(&hg.fg[0], 0.75, 0.75, 0.75, 0.75, 0, 4);
    setFG2(&hg.fg[1], 0.45, 0.75, 0.25, 0.75, 0.5, 0.75, 0.46, 0.83);
}

- (void)createMMMiddleFixIndexSlideRight {
    hg.n = 2;
    hg.t = 1*2;
    setFG(&hg.fg[0], 0.75, 0.75, 0.75, 0.75, 0, 4);
    setFG2(&hg.fg[1], 0.25, 0.75, 0.45, 0.75, 0.5, 0.75, 0.46, 0.83);
}

- (void)createMMIndexFixMiddleSlideLeft {
    hg.n = 2;
    hg.t = 1*2;
    setFG(&hg.fg[0], 0.25, 0.75, 0.25, 0.75, 0, 4);
    setFG2(&hg.fg[1], 0.75, 0.75, 0.60, 0.75, 0.5, 0.75, 0.46, 0.83);
}

- (void)createMMIndexFixMiddleSlideRight {
    hg.n = 2;
    hg.t = 1*2;
    setFG(&hg.fg[0], 0.25, 0.75, 0.25, 0.75, 0, 4);
    setFG2(&hg.fg[1], 0.60, 0.75, 0.75, 0.75, 0.5, 0.75, 0.46, 0.83);
}

- (void)createMMThreeSwipeLeft {
    hg.n = 3;
    hg.t = 1*2;
    setFG2(&hg.fg[0], 0.30, 0.75, 0.15, 0.75, 0.5, 0.75, 0.46, 0.83);
    setFG2(&hg.fg[1], 0.55, 0.75, 0.40, 0.75, 0.5, 0.75, 0.46, 0.83);
    setFG2(&hg.fg[2], 0.80, 0.75, 0.65, 0.75, 0.5, 0.75, 0.46, 0.83);
}

- (void)createMMThreeSwipeRight {
    hg.n = 3;
    hg.t = 1*2;
    setFG2(&hg.fg[0], 0.20, 0.75, 0.35, 0.75, 0.5, 0.75, 0.46, 0.83);
    setFG2(&hg.fg[1], 0.45, 0.75, 0.60, 0.75, 0.5, 0.75, 0.46, 0.83);
    setFG2(&hg.fg[2], 0.70, 0.75, 0.85, 0.75, 0.5, 0.75, 0.46, 0.83);
}

- (void)createMMThreeSwipeUp {
    hg.n = 3;
    hg.t = 1*2;
    setFG2(&hg.fg[0], 0.25, 0.75, 0.25, 0.83, 0.5, 0.75, 0.46, 0.83);
    setFG2(&hg.fg[1], 0.50, 0.75, 0.50, 0.83, 0.5, 0.75, 0.46, 0.83);
    setFG2(&hg.fg[2], 0.75, 0.75, 0.75, 0.83, 0.5, 0.75, 0.46, 0.83);
}

- (void)createMMThreeSwipeDown {
    hg.n = 3;
    hg.t = 1*2;
    setFG2(&hg.fg[0], 0.25, 0.75, 0.25, 0.67, 0.5, 0.75, 0.46, 0.83);
    setFG2(&hg.fg[1], 0.50, 0.75, 0.50, 0.67, 0.5, 0.75, 0.46, 0.83);
    setFG2(&hg.fg[2], 0.75, 0.75, 0.75, 0.67, 0.5, 0.75, 0.46, 0.83);
}


- (void)createMMThreeFingerClick {
    hg.n = 3;
    hg.t = 0.7*2;
    setFGx(&hg.fg[0], 0.25, 0.75, 0.25, 0.75, 0.25, 0.4);
    setFGx(&hg.fg[1], 0.50, 0.75, 0.50, 0.75, 0.25, 0.4);
    setFGx(&hg.fg[2], 0.75, 0.75, 0.75, 0.75, 0.25, 0.4);
}



- (void)createMMVShape {
    hg.n = 2;
    hg.t = 1*2;
    float s[2] = {0, 0};

    setFG(&hg.fg[0], s[0]+0.11, s[1]+0.84, s[0]+0.11, s[1]+0.84, 0, 4);
    setFG(&hg.fg[1], s[0]+0.87, s[1]+0.84, s[0]+0.87, s[1]+0.84, 0, 4);
}

- (void)createMMThumb {
    hg.n = 1;
    hg.t = 0.7*2;
    setFG(&hg.fg[0], 0.15, 0.55, 0.15, 0.55, 0, 1.0);
}

- (void)createMMMiddleClick {
    hg.n = 2;
    hg.t = 0.7*2;
    setFGx(&hg.fg[0], 0.75, 0.75, 0.75, 0.75, 0.25, 0.4);
    setFGx(&hg.fg[1], 0.50, 0.75, 0.50, 0.75, 0.25, 0.4);
}

- (void)createMMTwoFixOneSlideUp {
    hg.n = 3;
    hg.t = 1*2;

    setFG(&hg.fg[0], 0.50, 0.75, 0.50, 0.75, 0, 4);
    setFG(&hg.fg[1], 0.75, 0.75, 0.75, 0.75, 0, 4);
    setFG2(&hg.fg[2], 0.25, 0.72, 0.25, 0.78, 0.5, 0.75, 0.46, 0.85);
}

- (void)createMMTwoFixOneSlideDown {
    hg.n = 3;
    hg.t = 1*2;

    setFG(&hg.fg[0], 0.50, 0.75, 0.50, 0.75, 0, 4);
    setFG(&hg.fg[1], 0.75, 0.75, 0.75, 0.75, 0, 4);
    setFG2(&hg.fg[2], 0.25, 0.78, 0.25, 0.72, 0.5, 0.75, 0.46, 0.85);
}

- (void)createMMTwoFixOneSlideLeft {
    hg.n = 3;
    hg.t = 1*2;

    setFG(&hg.fg[0], 0.50, 0.75, 0.50, 0.75, 0, 4);
    setFG(&hg.fg[1], 0.75, 0.75, 0.75, 0.75, 0, 4);
    setFG2(&hg.fg[2], 0.25, 0.75, 0.17, 0.75, 0.5, 0.75, 0.46, 0.85);
}

- (void)createMMTwoFixOneSlideRight {
    hg.n = 3;
    hg.t = 1*2;

    setFG(&hg.fg[0], 0.50, 0.75, 0.50, 0.75, 0, 4);
    setFG(&hg.fg[1], 0.75, 0.75, 0.75, 0.75, 0, 4);
    setFG2(&hg.fg[2], 0.17, 0.75, 0.25, 0.75, 0.5, 0.75, 0.46, 0.85);
}



- (void)create:(NSString*)gesture forDevice:(int)aDevice {
    [self setGes:gesture];
    device = aDevice;

    if (device == 0) {

        if ([gesture isEqualToString:@"Three-Finger Tap"]) {
            [self createThreeFingerTap];
        } else if ([gesture isEqualToString:@"Three-Finger Click"]) {
            [self createThreeFingerClick];
        } else if ([gesture isEqualToString:@"Three-Finger Pinch-In"]) {
            [self createThreeFingerPinchIn]; //TODO:
        } else if ([gesture isEqualToString:@"Three-Finger Pinch-Out"]) {
            [self createThreeFingerPinchOut]; //TODO:
        } else if ([gesture isEqualToString:@"Four-Finger Tap"]) {
            [self createFourFingerTap];
        } else if ([gesture isEqualToString:@"Four-Finger Click"]) {
            [self createFourFingerClick];
        } else if ([gesture isEqualToString:@"Index-Fix Two-Tap"]) {
            [self createOneFixTwoTap:0];
        } else if ([gesture isEqualToString:@"Middle-Fix Two-Tap"]) {
            [self createOneFixTwoTap:1];
        } else if ([gesture isEqualToString:@"Ring-Fix Two-Tap"]) {
            [self createOneFixTwoTap:2];
        } else if ([gesture isEqualToString:@"One-Fix Left-Tap"]) {
            [self createOneFixLeftTap];
        } else if ([gesture isEqualToString:@"One-Fix Right-Tap"]) {
            [self createOneFixRightTap];
        } else if ([gesture isEqualToString:@"Pinky-To-Index"]) {
            [self createPinkyToIndex];
        } else if ([gesture isEqualToString:@"Index-To-Pinky"]) {
            [self createIndexToPinky];
        } else if ([gesture isEqualToString:@"One-Fix One-Slide"]) {
            [self createMoveResize];
        } else if ([gesture isEqualToString:@"One-Fix Two-Slide-Up"]) {
            [self createOneFixTwoSlideUp];
        } else if ([gesture isEqualToString:@"One-Fix Two-Slide-Down"]) {
            [self createOneFixTwoSlideDown];
        } else if ([gesture isEqualToString:@"One-Fix-Press Two-Slide-Up"]) {
            [self createOneFixPressTwoSlideUp];
        } else if ([gesture isEqualToString:@"One-Fix-Press Two-Slide-Down"]) {
            [self createOneFixPressTwoSlideDown];
        } /*else if ([gesture isEqualToString:@"One-Fix Three-Slide"]) {
            [self createOneFixThreeSlide];
        } */else if ([gesture isEqualToString:@"Two-Fix Index-Double-Tap"]) {
            [self createTwoFixOneDoubleTap:0];
        } else if ([gesture isEqualToString:@"Two-Fix Middle-Double-Tap"]) {
            [self createTwoFixOneDoubleTap:1];
        } else if ([gesture isEqualToString:@"Two-Fix Ring-Double-Tap"]) {
            [self createTwoFixOneDoubleTap:2];
        } else if ([gesture isEqualToString:@"Two-Fix One-Slide-Up"]) {
            [self createTwoFixOneSlideUp];
        } else if ([gesture isEqualToString:@"Two-Fix One-Slide-Down"]) {
            [self createTwoFixOneSlideDown];
        } else if ([gesture isEqualToString:@"Two-Fix One-Slide-Left"]) {
            [self createTwoFixOneSlideLeft];
        } else if ([gesture isEqualToString:@"Two-Fix One-Slide-Right"]) {
            [self createTwoFixOneSlideRight];
        } else if ([gesture isEqualToString:@"Three-Swipe-Up"]) {
            [self createThreeSwipeUp];
        } else if ([gesture isEqualToString:@"Three-Swipe-Down"]) {
            [self createThreeSwipeDown];
        } else if ([gesture isEqualToString:@"Three-Swipe-Left"]) {
            [self createThreeSwipeLeft];
        } else if ([gesture isEqualToString:@"Three-Swipe-Right"]) {
            [self createThreeSwipeRight];
        } else if ([gesture isEqualToString:@"Four-Swipe-Up"]) {
            [self createFourSwipeUp];
        } else if ([gesture isEqualToString:@"Four-Swipe-Down"]) {
            [self createFourSwipeDown];
        } else if ([gesture isEqualToString:@"Four-Swipe-Left"]) {
            [self createFourSwipeLeft];
        } else if ([gesture isEqualToString:@"Four-Swipe-Right"]) {
            [self createFourSwipeRight];
        } else if ([gesture isEqualToString:@"All Unassigned Gestures"]) {

        } else {
            [self performSelector:NSSelectorFromString([NSString stringWithFormat:@"create%@",
            [[[[gesture stringByReplacingOccurrencesOfString:@" " withString:@""]
             stringByReplacingOccurrencesOfString:@"-" withString:@""]
             stringByReplacingOccurrencesOfString:@"/" withString:@"S"]
             stringByReplacingOccurrencesOfString:@"\\" withString:@"BS"]
            ])];
        }

    } else {

        if ([gesture isEqualToString:@"Middle-Fix Index-Slide-Out"]) {
            [self createMMMiddleFixIndexSlideLeft];
        } else if ([gesture isEqualToString:@"Middle-Fix Index-Slide-In"]) {
            [self createMMMiddleFixIndexSlideRight];
        } else if ([gesture isEqualToString:@"Index-Fix Middle-Slide-In"]) {
            [self createMMIndexFixMiddleSlideLeft];
        } else if ([gesture isEqualToString:@"Index-Fix Middle-Slide-Out"]) {
            [self createMMIndexFixMiddleSlideRight];
        } else if ([gesture isEqualToString:@"Three-Swipe-Left"]) {
            [self createMMThreeSwipeLeft];
        } else if ([gesture isEqualToString:@"Three-Swipe-Right"]) {
            [self createMMThreeSwipeRight];
        } else if ([gesture isEqualToString:@"Three-Swipe-Up"]) {
            [self createMMThreeSwipeUp];
        } else if ([gesture isEqualToString:@"Three-Swipe-Down"]) {
            [self createMMThreeSwipeDown];
        } else if ([gesture isEqualToString:@"Three-Finger Click"]) {
            [self createMMThreeFingerClick];
        } else if ([gesture isEqualToString:@"Middle-Fix Index-Near-Tap"]) {
            [self createMiddleFixIndexNearTap];
        } else if ([gesture isEqualToString:@"Middle-Fix Index-Far-Tap"]) {
            [self createMiddleFixIndexFarTap];
        } else if ([gesture isEqualToString:@"Index-Fix Middle-Near-Tap"]) {
            [self createIndexFixMiddleNearTap];
        } else if ([gesture isEqualToString:@"Index-Fix Middle-Far-Tap"]) {
            [self createIndexFixMiddleFarTap];
        } else if ([gesture isEqualToString:@"One-Fix Left-Tap"]) {
            [self createMMOneFixLeftTap];
        } else if ([gesture isEqualToString:@"One-Fix Right-Tap"]) {
            [self createMMOneFixRightTap];
        } else if ([gesture isEqualToString:@"V-Shape"]) {
            [self createMMVShape];
        } else if ([gesture isEqualToString:@"Thumb"]) {
            [self createMMThumb];
        } else if ([gesture isEqualToString:@"Middle Click"]) {
            [self createMMMiddleClick];
        } else if ([gesture isEqualToString:@"Two-Fix One-Slide-Up"]) {
            [self createMMTwoFixOneSlideUp];
        } else if ([gesture isEqualToString:@"Two-Fix One-Slide-Down"]) {
            [self createMMTwoFixOneSlideDown];
        } else if ([gesture isEqualToString:@"Two-Fix One-Slide-Left"]) {
            [self createMMTwoFixOneSlideLeft];
        } else if ([gesture isEqualToString:@"Two-Fix One-Slide-Right"]) {
            [self createMMTwoFixOneSlideRight];
        } else if ([gesture isEqualToString:@"All Unassigned Gestures"]) {

        }
    }
}

- (void) handleTimer: (NSTimer *) timer {
    [self setNeedsDisplay:YES];
}

- (void)startTimer {
    timer = [NSTimer scheduledTimerWithTimeInterval:0.0175 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
}

- (void)stopTimer {
    [timer invalidate];
}

- (void)dealloc {
    [ges release];
    [super dealloc];
}

@end
