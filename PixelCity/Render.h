
@class World;


typedef enum EffectType
{
    EFFECT_NONE,
    EFFECT_BLOOM,
    EFFECT_BLOOM_RADIAL,
    EFFECT_COLOR_CYCLE,
    EFFECT_GLASS_CITY,
    EFFECT_DEBUG,
    EFFECT_DEBUG_OVERBLOOM,
    
    EFFECT_COUNT,
} EffectType;


@interface Renderer : NSObject

@property (nonatomic, readonly) float fogDistance;
@property (nonatomic, readonly) int   maxTextureSize;
@property (nonatomic, readonly, weak) World *world;
@property (nonatomic) EffectType effect;
@property (nonatomic) BOOL flat, fog, fps, wireframe, helpMode, letterbox, normalized;

    // Return the number of fonts that this system will show. Used to determine the <font> parameter to RenderPrintIntoTexture.
//@property (nonatomic, readonly) GLint fontCount;

-(id)initWithWorld:(World*) world viewSize:(CGSize) viewSize;
-(void)resize:(CGSize) size;
-(void)update:(CGSize) size;


-(void) dump;

    // The window is about to close, so don't do any more rendering.
-(void)terminate;

    // Create a texture containing a line of text, and then display it over the main screen.
    // line = 0 means the top of the screen, line = 1 is the next line down and so on.
    // fmt + varargs are passed to sprintf.
-(void)  printOverlayTextAtLine:(int) line format:(const char *)fmt, ...;

@end

