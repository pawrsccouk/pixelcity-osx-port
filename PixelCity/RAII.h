#import <OpenGL/gl.h>

// PAW: Helper classes for display-list rendering and primitive creation. 
// Avoid stack overflows by using RAII.



// glBegin(type)/glEnd()
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

// glPushMatrix() / glPopMatrix()
struct PWMatrixStacker
{
    PWMatrixStacker();
    ~PWMatrixStacker();
};

// Prints "Entering <location>" when created, and "Leaving <location>" when goes out of scope.
struct DebugRep
{
	const char* _location;
	DebugRep(const char* location);
	~DebugRep();
};



