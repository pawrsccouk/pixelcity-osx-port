/*-----------------------------------------------------------------------------

  Mesh.cpp

  2009 Shamus Young

-------------------------------------------------------------------------------

  This class is used to make constructing objects easier. It handles
  allocating vertex lists, polygon lists, and suchlike. 

  If you were going to implement vertex buffers, this would be the place to 
  do it.  Take away the _vertex member variable and store verts for ALL meshes
  in a common list, which could then be unloaded onto the good 'ol GPU.

-----------------------------------------------------------------------------*/

#import "Model.h"
#import <assert.h>
#import "Mesh.h"
#import "World.h"
#import "Win.h"

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

CMesh::CMesh ()
{
  _list = glGenLists(1);
  _compiled = false;
  _polycount = 0;
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

CMesh::~CMesh ()
{
  glDeleteLists (_list, 1);
  _vertex.clear ();
  _fan.clear ();
  _quad_strip.clear ();
  _cube.clear ();
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void CMesh::VertexAdd (const GLvertex& v)
{
  _vertex.push_back(v);

}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void CMesh::CubeAdd (const cube& c)
{
  _cube.push_back(c);
  _polycount += 5;
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void CMesh::QuadStripAdd (const quad_strip& qs)
{
  _quad_strip.push_back(qs);
  _polycount += (qs.index_list.size() - 2) / 2;
}


/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void CMesh::FanAdd (const fan& f)
{
  _fan.push_back(f);
  _polycount += f.index_list.size() - 2;
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


void CMesh::Render ()
{
	auto drawAtIndex = [this](int i) {
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
		MakePrimitive mp(GL_QUAD_STRIP);
        std::for_each(qsi->index_list.cbegin(), qsi->index_list.cend(), drawAtIndex);
	}
	
	for (std::vector<cube>::iterator ci = _cube.begin(); ci < _cube.end(); ++ci)
    {
		{	MakePrimitive mp(GL_QUAD_STRIP);
            std::for_each(ci->index_list.begin(), ci->index_list.end(), drawAtIndex);
		}
		
		{	MakePrimitive mp(GL_QUADS);
			_vertex[ci->index_list[7]].glTexCoord2();
			_vertex[ci->index_list[7]].glVertex3();
			_vertex[ci->index_list[5]].glVertex3();
			_vertex[ci->index_list[3]].glVertex3();
			_vertex[ci->index_list[1]].glVertex3();
		}
		
		{   MakePrimitive mp(GL_QUADS);
			glTexCoord2fv(&_vertex[ci->index_list[6]].uv.x);
			glVertex3fv  (&_vertex[ci->index_list[0]].position.x);
			glVertex3fv  (&_vertex[ci->index_list[2]].position.x);
			glVertex3fv  (&_vertex[ci->index_list[4]].position.x);
			glVertex3fv  (&_vertex[ci->index_list[6]].position.x);
		}
	}

	for (std::vector<fan>::iterator fi = _fan.begin(); fi < _fan.end(); ++fi)
    {
		MakePrimitive mp(GL_TRIANGLE_FAN);
        std::for_each(fi->index_list.cbegin(), fi->index_list.cend(), drawAtIndex);
	}
}


/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void CMesh::Compile ()
{
	assert(glIsList(_list));
	{	MakeDisplayList mdl(_list, GL_COMPILE);
		Render ();
	}
	_compiled = true;
}

template <class T>
static std::ostream &streamVector(std::ostream &os, const std::vector<T> &v, const char *name, const char *separator)
{
    os << "\n[VECTOR<" << name << ">.count=" << v.size();
    if(v.size() > 0) {
        os  << ", .items=\n";
        std::copy(v.begin(), v.end(), std::ostream_iterator<T>(os, separator));
    }
    return os << std::endl;
}

std::ostream &CMesh::operator<<(std::ostream &os) const
{
    os << "[MESH LIST=" << _list << ", POLYCOUNT=" << _polycount << ", COMPILED=" << _compiled;
    streamVector<GLvertex  >(os, _vertex    , "VERTEX"    , "\n");
    streamVector<cube      >(os, _cube      , "CUBE"      , "\n");
    streamVector<quad_strip>(os, _quad_strip, "QUAD_STRIP", "\n");
    streamVector<fan       >(os, _fan       , "FAN"       , "\n");
    return os << "]" << std::endl;
}


std::ostream &quad_strip::operator<<(std::ostream &os) const { return streamVector<unsigned long>(os, index_list, "INDEX_LIST", ", "); }
std::ostream &fan::operator<<       (std::ostream &os) const { return streamVector<unsigned long>(os, index_list, "INDEX_LIST", ", "); }
std::ostream &cube::operator<<      (std::ostream &os) const { return streamVector<unsigned long>(os, index_list, "INDEX_LIST", ", "); }

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



