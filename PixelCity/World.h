#include <OpenGL/gl.h>
#include "glTypes.h"
#include "glRGBA.h"

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




