@class World, Light;

    // Collection of lights. These are actually entities to be displayed rather than lights that illuminate the scene.
    // Lights should also be added to the Entities collection, as lights are also entities.
    // The convienience method newLightWithPosition:color:size:blink does this for you.
@interface Lights : NSObject

@property (nonatomic, readonly) GLulong count;
@property (nonatomic, readonly) __weak World *world;

    // Creates a new light, adds it to the lights and entities collections and returns it.
-(Light*) newLightWithPosition:(const GLvector &)position
                         color:(const GLrgba &)color
                          size:(int) size
                         blink:(BOOL) blink;

-(id) initWithWorld:(World*) world;

    // Remove all lights from this collection. Leaves Entities unchanged.
-(void) clear;

    // Add a light to this collection.
-(void) addLight:(Light*) light;

    // Render all the lights in this collection.
-(void) render;

@end

