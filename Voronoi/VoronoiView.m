//
//  VoronoiView.m
//  Voronoi
//
//  Created by Dave Kennedy on 27/08/2015.
//  Copyright (c) 2015 Dave Kennedy. All rights reserved.
//

#import "VoronoiView.h"
#include <math.h>

@interface VoronoiView ()

@property NSMutableArray* points;
@property NSImage* image;

- (void) drawPoint:(NSPoint) point;
- (NSArray*) buildColors;
- (NSImage*) buildVoronoi;
- (CGContextRef) contextOfSize:(CGSize) size;
- (NSImage*) fromContext:(CGContextRef) context;
- (NSInteger) nearestPointToX:(int) x y:(int) y;
- (int) distanceToPoint:(NSValue*) value fromX:(int) x y:(int)y;

@end

int rand_lim(int limit) {
    /* return a random number between 0 and limit inclusive.
     */
    
    int divisor = RAND_MAX/(limit+1);
    int retval;
    
    do {
        retval = rand() / divisor;
    } while (retval > limit);
    
    return retval;
}

@implementation VoronoiView

- (void) awakeFromNib {
    self.points = [[NSMutableArray alloc] init];
}

- (BOOL) acceptsFirstResponder {
    return YES;
}

- (void) mouseDown:(NSEvent *)theEvent {
    [self.points addObject:[NSValue valueWithPoint:[theEvent locationInWindow]]];
    self.image = [self buildVoronoi];
    [self setNeedsDisplay:YES];
    
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    [self.image drawInRect:[self bounds]];
    [[NSColor blackColor] setFill];
    for (NSValue* value in self.points) {
        [self drawPoint:[value pointValue]];
    }
}


- (void) drawPoint:(NSPoint) point {
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - 1, point.y - 1,
                                                       3, 3)] fill];
}

- (NSArray*) buildColors {
    NSMutableArray* colors = [[NSMutableArray alloc] init];
    for (NSValue* v in self.points) {
        int r = rand_lim(255);
        int g = rand_lim(255);
        int b = rand_lim(255);
        [colors addObject:[NSColor colorWithCalibratedRed:r/255.f
                                                    green:g/255.f
                                                     blue:b/2.55f
                                                    alpha:1]];
    }
    return colors;
}

- (CGContextRef) contextOfSize:(CGSize) size
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:contextRef flipped:NO];
    
    NSGraphicsContext* currentContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext:graphicsContext];
    [NSGraphicsContext setCurrentContext:currentContext];
    CGColorSpaceRelease(colorSpace);
    
    return contextRef;
}

- (NSImage*) fromContext:(CGContextRef) context
{
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    NSImage* newImage = [[NSImage alloc] initWithCGImage:imageRef
                                                    size:NSMakeSize(
                                                                    CGBitmapContextGetWidth(context),
                                                                    CGBitmapContextGetHeight(context))];
    return newImage;
}

- (int) distanceToPoint:(NSValue*) value fromX:(int) x y:(int)y
{
    NSPoint point = [value pointValue];
    int dx = point.x - x;
    int dy = point.y - y;
    
    return sqrt((dx*dx) + (dy*dy));
}

- (NSInteger) nearestPointToX:(int) x y:(int) y
{
    int point = 0;
    int distance = [self distanceToPoint:[self.points objectAtIndex:0] fromX:x y:y];
    for (int i = 0; i < [self.points count]; i++) {
        int d = [self distanceToPoint:[self.points objectAtIndex:i] fromX:x y:y];
        if (d < distance) {
            distance = d;
            point = i;
        }
    }
    return point;
}

- (uint32_t) intFromColor:(NSColor*) color {
     return ((int)([color alphaComponent] * 255) << 24 |
             ((int)([color redComponent] * 255)) << 16 |
             ((int)([color greenComponent] * 255)) << 8 |
             ((int)([color blueComponent])) * 255);
}

- (NSImage*) buildVoronoi {
    NSArray* colors = [self buildColors];
    NSRect imgRect = [self bounds];
    NSSize imgSize = imgRect.size;
    CGContextRef context = [self contextOfSize:imgSize];
    
    size_t width = CGBitmapContextGetWidth(context);
    size_t height = CGBitmapContextGetHeight(context);
    
    uint32_t* data = CGBitmapContextGetData(context);
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            NSInteger nearestPoint = [self nearestPointToX:x y:y];
            NSColor* color = [colors objectAtIndex:nearestPoint];
            data[(height - y - 1) * width + x] = [self intFromColor:color];
        }
    }
    
    return [self fromContext:context];
}

@end
