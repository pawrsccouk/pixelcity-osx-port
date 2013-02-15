//
//  NSColor_OpenGL.h
//  PixelCity
//
//  Created by Patrick Wallace on 14/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSColor_OpenGL.h"

#define MAKERGBA(_red, _green, _blue, _alpha) \
  CGFloat _red, _green, _blue, _alpha;        \
  [self getRed:&_red green:&_green blue:&_blue alpha:&_alpha];

@implementation NSColor (OpenGL)

    // Return a new color which is the equivalent of adding, subtracting, multiplying or dividing each component by the given value.
    // The results are not clamped.
-(NSColor*) add:(CGFloat)value
{
    MAKERGBA(r, g, b, a)
    return [NSColor colorWithDeviceRed:r+value green:g+value blue:b+value alpha:a];
}

-(NSColor*) subtract:(CGFloat)value
{
    MAKERGBA(r, g, b, a)
    return [NSColor colorWithDeviceRed:r-value green:g-value blue:b-value alpha:a];
}

-(NSColor*) multiplyBy:(CGFloat)value
{
    MAKERGBA(r, g, b, a)
    return [NSColor colorWithDeviceRed:r*value green:g*value blue:b*value alpha:a];
}

-(NSColor*) divideBy:(CGFloat)value
{
    MAKERGBA(r, g, b, a)
    return [NSColor colorWithDeviceRed:r/value green:g/value blue:b/value alpha:a];
}

    // Apply the colors as if the user called glColor3f(red, green, blue);
-(void)glColor3
{
    MAKERGBA(r, g, b, a)
    glColor3f(r, g, b);
}
    // Apply the colors as if the user called glColor4f(red, green, blue, alpha);
-(void)glColor4
{
    MAKERGBA(r, g, b, a)
    glColor4f(r, g, b, a);
}

@end
