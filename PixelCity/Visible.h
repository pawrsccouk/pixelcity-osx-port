
    //Controls the ammount of space available for buildings.  Other code is wrtten assuming this will be a power of two.
static const int WORLD_SIZE = 1024;
static const int WORLD_HALF = (WORLD_SIZE / 2);

static const int GRID_RESOLUTION = 32
               , GRID_CELL       = (GRID_RESOLUTION / 2)
               , GRID_SIZE       = (WORLD_SIZE / GRID_RESOLUTION);

inline int WORLD_TO_GRID(float x) { return (int)(x / GRID_RESOLUTION); }
inline float GRID_TO_WORLD(int x) { return ((float)x * GRID_RESOLUTION); }

@class World;

@interface VisibilityGrid : NSObject

-(id)   initWithWorld:(World*) world;
-(void) update;
-(BOOL) visibleAtPosition:(const GLvector &) pos;
-(BOOL) visibleAtX:(int) x Z:(int) z;

@property (nonatomic, readonly, weak) World *world;
@end

