@class World;


@interface Sky : NSObject

@property (nonatomic, readonly) __weak World *world;

-(id)initWithWorld:(World*) world;
-(void) render;
-(void) clear;

@end

