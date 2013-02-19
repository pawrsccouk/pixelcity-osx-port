#import "entity.h"
#import "glRGBA.h"

@class Mesh;
@interface Deco : Entity
{
  GLrgba        _color;
  Mesh         *_mesh;
  int           _type;
  unsigned      _texture;
  BOOL          _use_alpha;
}
-(id)init;
-(void) CreateLogoWithStart:(const GLvector2 &)start end:(const GLvector2 &) end base:(float) base seed:(int) seed color:(const GLrgba &)color;
-(void) CreateLightStripWithX:(float) x z:(float) z width:(float) width depth:(float) depth height:(float) height color:(GLrgba) color;
-(void) CreateLightTrimWithChain:(GLvector*) chain count:(int) count height:(float) height seed:(unsigned long) seed color:(GLrgba) color;
-(void) CreateRadioTowerWithPosition:(GLvector) pos height:(float) height;
@end

