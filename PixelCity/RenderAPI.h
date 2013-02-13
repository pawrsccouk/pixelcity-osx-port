//
//  RenderAPI.h
//  PixelCity
//
//  Created by Patrick Wallace on 08/02/2013.
//
//

#ifndef PixelCity_RenderAPI_h
#define PixelCity_RenderAPI_h

#ifdef __cplusplus
extern "C"
{
#endif
    
        // Functions called externally from Objective-C to toggle the various display elements.
    void  RenderEffectCycle ();

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
    
        // Print text into a texture which has already been prepared.
        // textureId is the ID of the texture we want to write into.
        // x, y are the position, texWidth and texHeight are the size of the texture we can draw in.
        // red, green, blue, alpha are the color
        // fmt + varargs are for the printf which makes the string.
    void  RenderPrintIntoTexture (GLuint textureId, int x, int y, int texWidth, int texHeight,
                                  int font, float red, float green, float blue, float alpha, const char *fmt, ...);
    
        // Create a texture containing a line of text, and then display it over the main screen.
        // line = 0 means the top of the screen, line = 1 is the next line down and so on.
        // fmt + varargs are used as in printf.
    void  RenderPrintOverlayText (int line, const char *fmt, ...);


#ifdef __cplusplus
}
#endif


#endif
