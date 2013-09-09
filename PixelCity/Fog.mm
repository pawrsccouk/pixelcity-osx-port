//
//  Fog.m
//  PixelCity
//
// 2009 Shamus Young
// Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
// Released under the GNU GPL v3. See file COPYING for details.


#import "Model.h"
#import "Fog.h"
#import "Visible.h"

enum fogAnimation { fogGROWING, fogSHRINKING };
enum fogAnimationColor { fogRED, fogGREEN, fogBLUE };

@interface Fog ()
{
    BOOL _growing;
    enum fogAnimationColor _animColor;
}
@end

@implementation Fog
@synthesize start, end, enable, color, mode, density;

- (id)init
{
    self = [super init];
    if (self) {
        self.start = WORLD_HALF;
        self.end   = WORLD_HALF + 100;
        self.color = [NSColor colorWithDeviceRed:0.15 green:0.15 blue:0.15 alpha:0.15];
        
        self.animateColor = NO;
        _growing = YES;
        _animColor = fogRED;
    }
    return self;
}

-(float) minDistance { return 0; }
-(float) maxDistance { return WORLD_SIZE; }



-(void) updateColor
{
    static const float INTERVAL = 0.005, MIN_CHANNEL = 0.0f, MAX_CHANNEL = 0.5f;

    CGFloat red, green, blue, alpha;
    [self.color getRed:&red green:&green blue:&blue alpha:&alpha];
    
        // Return an animation type suitable for the value in channel.
    auto animForChannel = ^(CGFloat channel) {
        if(channel >= MAX_CHANNEL) return NO ;
        if(channel <= MIN_CHANNEL) return YES;
        return (BOOL)COIN_FLIP();
    };
    
        // Start a new animation
    auto newColorAnim = ^{
        _animColor = (enum fogAnimationColor)RandomIntR(3);
        switch (_animColor) {
            case fogRED  : _growing = animForChannel(red  );  break;
            case fogGREEN: _growing = animForChannel(green);  break;
            case fogBLUE : _growing = animForChannel(blue );  break;
        }
    };
    
        // Bump the given channel up by an interval, and reschedule a new animation if the channel is full or empty.
    auto updateColor = ^(CGFloat *channel) {
        if(_growing) { *channel += INTERVAL; }
        else         { *channel -= INTERVAL; }
        
        if(*channel >= MAX_CHANNEL || *channel <= MIN_CHANNEL) {
            newColorAnim();
        }
    };
    
    NSAssert(_animColor == fogRED || _animColor == fogGREEN || _animColor == fogBLUE, @"_animColor was %d", _animColor);
    switch (_animColor) {
        case fogRED:     updateColor(&red)  ; break;
        case fogGREEN:   updateColor(&green); break;
        case fogBLUE:    updateColor(&blue) ; break;
    }
    self.color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
}

-(void) apply
{
    if(self.enable) {
        pwEnable (GL_FOG);
        
        GLenum fogMode = self.mode;
        if(! (fogMode == GL_LINEAR || fogMode == GL_EXP || fogMode == GL_EXP2)) {
            NSLog(@"Unknown OpenGL fog mode %d, defaulting to LINEAR", mode);
            fogMode = GL_LINEAR;
        }
        
        pwFogi (GL_FOG_MODE, fogMode);
        if(fogMode == GL_LINEAR) {
            pwFogf (GL_FOG_START, self.start);
            pwFogf (GL_FOG_END  , self.end  );
        }
        else {
            pwFogf(GL_FOG_DENSITY, self.density);
        }
         
        CGFloat red, green, blue, alpha;
        [self.color getRed:&red green:&green blue:&blue alpha:&alpha];
        float colorfv[4] = { (float)red, (float)green, (float)blue, (float)alpha };
        pwFogfv(GL_FOG_COLOR, colorfv);
        
            // Get the next color in the animation, if necessary
        if(self.animateColor) {
            [self updateColor];
        }
    }
    else {
        pwDisable(GL_FOG);
    }
}

-(void) remove
{
    pwDisable(GL_FOG);
}

@end
