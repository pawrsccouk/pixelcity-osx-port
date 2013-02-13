#import <OpenGL/gl.h>
#import "glTypes.h"
#import "glRGBA.h"

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

// Generic template class to handle creating/setting something in the constructor
// and deleting/unsetting it when it goes out of scope.
// Templated so that std::ptr_fun, std::bind2nd etc will work.

// Not working, and I can't find out why right now.
//template <class _Arg, class _Result>
//struct RAII
//{
//    RAII( std::unary_function<_Arg, _Result> createFunction, std::unary_function<_Arg, _Result> releaseFunction)
//    : _releaseFn(releaseFunction)
//    {
//        createFunction();
//    }
//    
//    ~RAII()
//    {
//        _releaseFn();
//    }
//
//private:
//    std::unary_function<_Arg, _Result> _releaseFn;
//};

struct PWMatrixStacker
{
    PWMatrixStacker();
    ~PWMatrixStacker();
};

struct DebugRep
{
	const char* _location;
	DebugRep(const char* location);
	~DebugRep();
};




