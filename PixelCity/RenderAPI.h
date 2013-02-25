//
//  RenderAPI.h
//  PixelCity
//
//  Created by Patrick Wallace on 08/02/2013.
//
//

#ifdef __cplusplus
extern "C"
{
#endif
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
    
   
        // Functions called externally from Objective-C to toggle the various display elements.
    EffectType  RenderEffect();
    void  RenderSetEffect(EffectType effect);
    void  RenderSetFlat(bool);
    void  RenderSetFog(bool);
    void  RenderSetFPS(bool);
    void  RenderSetWireframe(bool);
    void  RenderSetHelpMode(bool);
    void  RenderSetLetterbox(bool);
    void  RenderSetNormalized(bool);
    
        // Ditto external functions for debugging.
    void EntityDump();
    
        // The window is about to close, so don't do any more rendering.
    void RenderTerminate();

        // These handle displaying text.
    
        // Return the number of fonts that this system will show.
        // Used to determine the <font> parameter to RenderPrintIntoTexture.
    int RenderGetNumFonts();
        
        // Create a texture containing a line of text, and then display it over the main screen.
        // line = 0 means the top of the screen, line = 1 is the next line down and so on.
        // fmt + varargs are used as in printf.
    void  RenderPrintOverlayText (int line, const char *fmt, ...);


#ifdef __cplusplus
}
#endif


