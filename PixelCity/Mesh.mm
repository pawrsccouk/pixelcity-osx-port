/*-----------------------------------------------------------------------------

  Mesh.cpp

  2009 Shamus Young
  Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
  Released under the GNU GPL v3. See file COPYING for details.

-------------------------------------------------------------------------------
  This class is used to make constructing objects easier. It handles allocating vertex lists, polygon lists, and suchlike. 

  If you were going to implement vertex buffers, this would be the place to do it.  
  Take away the _vertex member variable and store verts for ALL meshes in a common list, 
  which could then be unloaded onto the good 'ol GPU.
-----------------------------------------------------------------------------*/

#import "Model.h"
#import <assert.h>
#import "Mesh.h"
#import "World.h"
#import "Win.h"

@implementation Mesh

-(id)init
{
    self = [super init];
    if(self) {
        _list = glGenLists(1);
        _compiled = false;
        _polycount = 0;
        
    }
    return self;
}

-(void)dealloc
{
  glDeleteLists (_list, 1);
  _vertex.clear ();
  _fan.clear ();
  _quad_strip.clear ();
  _cube.clear ();
}

-(void) addVertex:(const GLvertex&) v
{
  _vertex.push_back(v);
}

-(size_t) vertexCount
{
    return _vertex.size();
}

-(size_t) polyCount
{
    return _polycount;
}

-(void) addCube:(const cube&) c
{
  _cube.push_back(c);
  _polycount += 5;
}

-(void) addQuadStrip:(const quad_strip&) qs
{
  _quad_strip.push_back(qs);
  _polycount += (qs.index_list.size() - 2) / 2;
}

-(void) addFan:(const fan&) f
{
  _fan.push_back(f);
  _polycount += f.index_list.size() - 2;
}

-(void) Render
{
	auto drawAtIndex = [self](int i) {
        _vertex[i].glTexCoord2();
        _vertex[i].glVertex3();
    };
    
	if (_compiled)
    {
		glCallList (_list);
		return;
	}
    
	for (std::vector<quad_strip>::iterator qsi = _quad_strip.begin(); qsi < _quad_strip.end(); ++qsi)
    {
		pwBegin(GL_QUAD_STRIP);
        @try { std::for_each(qsi->index_list.cbegin(), qsi->index_list.cend(), drawAtIndex); }
        @finally { pwEnd(); }
	}
	
	for (std::vector<cube>::iterator ci = _cube.begin(); ci < _cube.end(); ++ci)
    {
		pwBegin(GL_QUAD_STRIP);
        @try {   std::for_each(ci->index_list.begin(), ci->index_list.end(), drawAtIndex); }
        @finally { pwEnd(); }

		
		pwBegin(GL_QUADS);
        @try {
			_vertex[ci->index_list[7]].glTexCoord2();
			_vertex[ci->index_list[7]].glVertex3();
			_vertex[ci->index_list[5]].glVertex3();
			_vertex[ci->index_list[3]].glVertex3();
			_vertex[ci->index_list[1]].glVertex3();
		}
        @finally { pwEnd(); }
            
		pwBegin(GL_QUADS);
		@try {
			glTexCoord2fv(&_vertex[ci->index_list[6]].uv.x);
			glVertex3fv  (&_vertex[ci->index_list[0]].position.x);
			glVertex3fv  (&_vertex[ci->index_list[2]].position.x);
			glVertex3fv  (&_vertex[ci->index_list[4]].position.x);
			glVertex3fv  (&_vertex[ci->index_list[6]].position.x);
		}
        @finally { pwEnd(); }
	}

	for (std::vector<fan>::iterator fi = _fan.begin(); fi < _fan.end(); ++fi)
    {
		pwBegin(GL_TRIANGLE_FAN);
        @try { std::for_each(fi->index_list.cbegin(), fi->index_list.cend(), drawAtIndex); }
        @finally { pwEnd(); }
	}
}

-(void) Compile
{
	assert(glIsList(_list));
	pwNewList(_list, GL_COMPILE);
    @try {
        [self Render];
    }
    @finally { pwEndList(); }
	_compiled = true;
}


@end


cube::cube(int first, ...)
{
    index_list.push_back(first);
    va_list args;
    va_start(args, first);
    int i = 0;
    while( (i = va_arg(args, int)) != LIST_TERM)
        index_list.push_back(i);
}

fan::fan(int first, ...)
{
    index_list.push_back(first);
    va_list args;
    va_start(args, first);
    int i = 0;
    while( (i = va_arg(args, int)) != LIST_TERM)
        index_list.push_back(i);
}

quad_strip::quad_strip(int first, ...)
{
    index_list.push_back(first);
    va_list args;
    va_start(args, first);
    int i = 0;
    while( (i = va_arg(args, int)) != LIST_TERM)
        index_list.push_back(i);
}



