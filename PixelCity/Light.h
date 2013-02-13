#ifndef _LIGHT_H_
#define _LIGHT_H_

#if defined(__cplusplus)
extern "C" {
#endif

    void  LightRender (void);
    
    void  LightClear (void);
    
    unsigned long   LightCount (void);
    
    void LightAdd(Vector *position, NSColor *color, int size, BOOL blink);

#if defined(__cplusplus)
}
#endif


#endif // _LIGHT_H_
