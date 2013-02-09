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
    void  RenderFlatToggle ();
    void  RenderFogToggle ();
    void  RenderFPSToggle ();
    void  RenderWireframeToggle ();
    void  RenderHelpToggle ();
    void  RenderEffectCycle ();
    void  RenderLetterboxToggle ();
    
        // Ditto external functions for debugging.
    void EntityDump();

#ifdef __cplusplus
}
#endif


#endif
