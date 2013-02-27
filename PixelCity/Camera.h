
@class World;

@interface Camera : NSObject

@property (nonatomic) GLvector angle, position, movement;
@property (nonatomic) float distance;
@property (nonatomic, readonly) World *world;

-(id) initWithWorld:(World *) world;

-(void) autoToggle;
-(void) nextBehavior;
-(void) reset;
-(void) update;

-(void) forward:(float) delta;
-(void) pan:    (float) delta_x;
-(void) pitch:  (float) delta_y;
-(void) yaw:    (float) delta_x;

-(void) vertical:(float) val;
-(void) lateral: (float) val;
-(void) medial:  (float) val;

@end

