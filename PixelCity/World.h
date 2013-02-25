
@class Cars, Entities, Lights;

@interface World : NSObject
{
}

-(id)      init;

@property (nonatomic, readonly) GLrgba bloomColor;
@property (nonatomic, readonly) GLuint logoIndex;

@property (nonatomic, readonly) Cars     *cars;
@property (nonatomic, readonly) Entities *entities;
@property (nonatomic, readonly) Lights   *lights;

@property (nonatomic, readonly) GLbbox hotZone;
@property (nonatomic, readonly) float fadeCurrent;
@property (nonatomic, readonly) GLulong  fadeStart;
@property (nonatomic, readonly) GLulong sceneBegin, sceneElapsed;

-(char) cellAtRow:(int)row column:(int)column;
-(GLrgba)    lightColorAtIndex: (GLuint) index;

-(void)      render;
-(void)      reset;
-(void)      term;
-(void)      update;

@end


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
	MakeDisplayList(GLint name, GLenum mode, const char *location);
	~MakeDisplayList();
};	


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




