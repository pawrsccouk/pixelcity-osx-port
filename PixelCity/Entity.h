@class Entity, World;

@interface Entities : NSObject
{
    GLint   _compileX, _compileY, _compileCount;
    BOOL    _sorted;
    GLulong _compileEnd;
    NSMutableArray *_allEntities;
}
@property (nonatomic, readonly) GLulong count;
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) BOOL ready;
@property (nonatomic, readonly) GLint polyCount;
@property (nonatomic, readonly) __weak World *world;

-(id)   initWithWorld:(World*) world;
-(void) clear;
-(void)addEntity:(Entity*) entity;
-(void) render:(BOOL) showFlat;
-(void) update;
-(void) term;

@end


@interface Entity : NSObject
{
  GLvector _center;

}
    // Designated initializer
    // Add this entity to the global list of entities in the world provided.
-(id)initWithWorld:(World*) world;

@property (nonatomic) GLuint texture;
@property (nonatomic) BOOL alpha;
@property (nonatomic) GLulong polyCount;
@property (nonatomic, readonly) GLvector center;
@property (nonatomic, readonly) __weak World *world;

        // Virtual Methods
-(void) Render;
-(void) RenderFlat:(BOOL) wirefame;
-(void) Update;
@end
