//
//  Fog.m
//  PixelCity
//
//  Created by Patrick Wallace on 01/03/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "Model.h"
#import "Fog.h"
#import "Visible.h"

@interface Fog ()

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

    }
    return self;
}

-(float) minDistance { return 0; }
-(float) maxDistance { return WORLD_SIZE; }

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
