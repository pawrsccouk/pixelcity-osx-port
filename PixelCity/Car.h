
// Handles all the cars in the scene.
@class World;

@interface Cars : NSObject

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) World *world;

-(id) initWithWorld:(World*) world;

    // Disable all the cars in the array, making them invisible.
-(void)   clear;
    // Render all the cars.
-(void)   render;
    // Update positions of all cars.
-(void)   update;

@end