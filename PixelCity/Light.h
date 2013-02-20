
#if defined(__cplusplus)
extern "C" {
#endif

    void  LightRender (void);
    void  LightClear (void);
    GLulong LightCount (void);

#if defined(__cplusplus)
}
#endif

void LightAdd(const GLvector &position, const GLrgba &color, int size, bool blink);

