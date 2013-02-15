//
//  NSColor_OpenGL.h
//  PixelCity
//
//  Created by Patrick Wallace on 14/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (OpenGL)

    // Return a new color which is the equivalent of adding, subtracting, multiplying or dividing each component by the given value.
    // The results are not clamped.
-(NSColor*) add:(CGFloat)value;
-(NSColor*) subtract:(CGFloat)value;
-(NSColor*) multiplyBy:(CGFloat)value;
-(NSColor*) divideBy:(CGFloat)value;

    // Apply the colors as if the user called glColor3f(red, green, blue);
-(void)glColor3;
    // Apply the colors as if the user called glColor4f(red, green, blue, alpha);
-(void)glColor4;

@end
