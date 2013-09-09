//
//  Fog.h
//  PixelCity
//
//  2009 Shamus Young
//  Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
//  Released under the GNU GPL v3. See file COPYING for details.

#import <Foundation/Foundation.h>


@interface Fog : NSObject

    // Can be GL_LINEAR, GL_EXP or GL_EXP2
@property (nonatomic) GLuint mode;

    // Start and end are the ranges of the linear gradient. Anything before start is clear, and anything beyond end is pure fog.
@property (nonatomic) float start, end;
    // These are the minimum and maximum values for start and end. 
@property (nonatomic, readonly) float minDistance, maxDistance;

    // Density of fog. Used in GL_EXP or GL_EXP2 modes.
@property (nonatomic) float density;

    // Enable or disable the fog.
@property (nonatomic) BOOL enable;

    // Color of the fog.  If animateColor is set, then this will cycle through colors
@property (nonatomic) NSColor *color;
@property (nonatomic) BOOL animateColor;

    // Apply the fog settings to the current opengl context
-(void) apply;

    // Remove the fog settings from the current context (so that subsequent items drawn
    // will appear through the fog).
-(void) remove;

@end
