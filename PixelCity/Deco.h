// 2009 Shamus Young
// Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
// Released under the GNU GPL v3. See file COPYING for details.

#import "Entity.h"
#import "glRgba.h"

@interface Deco : Entity

-(void) CreateLogoWithStart:(const GLvector2 &) start
                        end:(const GLvector2 &) end
                       base:(float) base
                       seed:(int)   seed
                      color:(const GLrgba &)color;

-(void) CreateLightStripWithX:(float)  x
                            z:(float)  z
                        width:(float)  width
                        depth:(float)  depth
                       height:(float)  height
                        color:(GLrgba) color;

-(void) CreateLightTrimWithChain:(GLvector*) chain
                           count:(int)   count
                          height:(float) height
                            seed:(int)   seed
                           color:(const GLrgba &) color
                       trimColor:(const GLrgba &) trimColor;

-(void) CreateRadioTowerWithPosition:(GLvector) pos
                              height:(float) height;
@end

