#ifndef glTYPES_OBJC_
#define glTYPES_OBJC_

#import <OpenGL/OpenGL.h>

// Objective-C versions of the basic OpenGL classes

@interface Vector : NSObject <NSCopying>

@property (nonatomic) float x, y, z;
+(id)vectorWithX:(float)x Y:(float)y Z:(float)z;
-(id)initWithX:(float)x Y:(float)y Z:(float)z;

-(void)glVertex3;

@end





@interface Vertex : NSObject <NSCopying>
@property (nonatomic, copy) Vector *position;
@property (nonatomic) float u, v;

+(id)vertexWithPosition:(Vector*)posn u:(float)u v:(float)v;
-(id)initWithPosition:(Vector*)position u:(float)u v:(float)v;

@end


static const int JOINT_MAX_CHILDREN  = 8;



struct GLrect
{
  float       left;
  float       top;
  float       right;
  float       bottom;
};

struct GLtriangle
{
  int         v1;
  int         v2;
  int         v3;
  int         normal1;
  int         normal2;
  int         normal3;
};


#endif  // glTYPES_OBJC_


