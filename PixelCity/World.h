
GLrgba    WorldBloomColor ();
char      WorldCell (int x, int y);
GLrgba    WorldLightColor (unsigned index);
int       WorldLogoIndex ();
GLbbox    WorldHotZone ();
void      WorldInit (void);
float     WorldFade (void);
void      WorldRender ();
void      WorldReset (void);
unsigned long WorldSceneBegin ();
unsigned long WorldSceneElapsed ();
void      WorldTerm (void);
void      WorldUpdate (void);

#include <OpenGL/gl.h>

// Replacements for glPush/PopMatrix that track and debug.
void pwPushMatrix(void);
void pwPopMatrix(void);


// PAW: Helper classes for display-list rendering and primitive creation. 
// Avoid stack overflows by using RAII.
struct MakePrimitive
{
	static int nestCount;	// debug variable used to check we are not nesting.
	MakePrimitive(GLenum type);
	~MakePrimitive();
};

struct MakeDisplayList
{
	static int nestCount;	// debug variable used to check we are not nesting.
	MakeDisplayList(GLint name, GLenum mode);
	~MakeDisplayList();
};	

struct DebugRep
{
	const char* _location;
	DebugRep(const char* location);
	~DebugRep();
};

// Replacements for OpenGL calls that report errors.
void pwEnable (GLenum i);
void pwDisable(GLenum i);
void pwMatrixMode(GLenum i);
void pwLoadIdentity();
void pwDepthMask(GLboolean b);
void pwRotatef(GLfloat angle, GLfloat x, GLfloat y, GLfloat z);
void pwTranslatef(GLfloat x, GLfloat y, GLfloat z);
void pwHint(GLenum target, GLenum mode);
void pwShadeModel(GLenum e);
void pwFogi(GLenum name, GLint mode);
void pwDepthFunc(GLenum f);
void pwCullFace(GLenum f);
void pwBlendFunc(GLenum sfactor, GLenum dfactor);
void pwViewport(GLint x, GLint y, GLsizei w, GLsizei h);
void pwClearColor(GLclampf r, GLclampf g, GLclampf b, GLclampf a);
void pwClear(GLbitfield mask);
void pwFogf(GLenum name, GLfloat param);
void pwFogfv(GLenum name, const GLfloat* params);
void pwBegin(GLenum mode);
void pwEnd();
void pwNewList(GLint name, GLenum mode);
void pwEndList();
void pwLineWidth(GLfloat f);
void pwBindTexture(GLenum type, GLuint texture);
void pwPolygonMode(GLenum face, GLenum mode);

void pwTexImage2D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
void pwTexParameteri(GLenum target, GLenum pname, GLenum param);
void pwCopyTexImage2D(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
void pwGetTexImage(GLenum target, GLint level, GLenum format, GLenum type, GLvoid *pixels);
GLint pwuBuild2DMipmaps( GLenum target, GLint internalFormat, GLsizei width, GLsizei height, GLenum format, GLenum type, const void *data );



