// 2009 Shamus Young
// Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
// Released under the GNU GPL v3. See file COPYING for details.

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

@class Fog;

@interface Renderer : NSObject

@property (nonatomic, readonly) int   maxTextureSize;
@property (nonatomic, readonly, weak) World *world;
@property (nonatomic, readonly) Fog *fog;

@property (nonatomic) EffectType effect;
@property (nonatomic) BOOL flat, fps, wireframe, helpMode, letterbox, normalized;


-(id)initWithWorld:(World*) world
          viewSize:(CGSize) viewSize;

-(void)resize:(CGSize) viewSize;

    // Draws the current view to the OpenGL context.
-(void) draw;

    // The window is about to close, so don't do any more rendering.
-(void)terminate;

    // Create a texture containing a line of text, and then display it over the main screen.
    // line = 0 means the top of the screen, line = 1 is the next line down and so on.
    // fmt + varargs are passed to sprintf.
-(void)  printOverlayTextAtLine:(int) line
                         format:(const char *)fmt, ...
                            __attribute__((format(printf, 2, 3)));

    // Print some debugging information on the debug output stream.
-(void) dump;


@end

