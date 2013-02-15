#ifndef _LIGHT_H_
#define _LIGHT_H_

#if defined(__cplusplus)
extern "C" {
#endif

    void  LightRender (void);
    void  LightClear (void);
    unsigned long LightCount (void);

#if defined(__cplusplus)
}
#endif

void LightAdd(const GLvector &position, const GLrgba &color, int size, bool blink);

#endif // _LIGHT_H_
