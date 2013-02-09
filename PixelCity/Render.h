

bool  RenderBloom ();
bool  RenderFlat ();
float RenderFogDistance ();
bool  RenderFog ();
void  RenderFogFX (float scalar);
void  RenderInit(int width, int height);
int   RenderMaxTextureSize ();
void  RenderResize (int width, int height);
void  RenderTerm ();
void  RenderUpdate (int width, int height);
bool  RenderWireframe ();
void  RenderPrint (int x, int y, int font, GLrgba color, const char *fmt, ...);
void  RenderPrint (int line, const char *fmt, ...);



