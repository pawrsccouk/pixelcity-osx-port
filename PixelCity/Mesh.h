
#import <vector>
#import "glVertex.h"

    // Terminator for list of ints in cube/fan/qs constructors.
static const int LIST_TERM = -1;

struct cube
{
    cube() {}
        // Constructor takes a list of index values and pushes them on to index_list.
        // End the list with LIST_TERM
        // Example cube c(1, 2, 3, 5, 8, LIST_TERM);
    cube(int first, ...);
    std::vector<unsigned long> index_list;   // probably always .size() == 10...
    std::ostream &operator<<(std::ostream &os) const;
};
inline std::ostream &operator<<(std::ostream &os, const cube &c) { return c.operator<<(os); }

struct quad_strip
{
    quad_strip() {}
        // Constructor takes a list of index values and pushes them on to index_list.
        // End the list with LIST_TERM
        // Example quad_strip s(1, 2, 3, 5, 8, LIST_TERM);
    quad_strip(int first, ...);
    std::vector<unsigned long> index_list;
    std::ostream &operator<<(std::ostream &os) const;
};
inline std::ostream &operator<<(std::ostream &os, const quad_strip &s) { return s.operator<<(os); }

struct fan
{
    fan() {}
        // Constructor takes a list of index values and pushes them on to index_list.
        // End the list with LIST_TERM
        // Example fan f(1, 2, 3, 5, 8, LIST_TERM);
    fan(int first, ...);
    std::vector<unsigned long> index_list;
    std::ostream &operator<<(std::ostream &os) const;
};
inline std::ostream &operator<<(std::ostream &os, const fan &f) { return f.operator<<(os); }

class CMesh
{
    unsigned                _list;
    size_t                  _polycount;
    std::vector<GLvertex>   _vertex;
    std::vector<cube>       _cube;
    std::vector<quad_strip> _quad_strip;
    std::vector<fan>        _fan;
    bool                    _compiled;
    
public:
    CMesh ();
    ~CMesh ();
    void        VertexAdd (const GLvertex& v);
    size_t      VertexCount () { return _vertex.size(); }
    size_t      PolyCount () { return _polycount; }
    void        CubeAdd (const cube& c);
    void        QuadStripAdd (const quad_strip& qs);
    void        FanAdd (const fan& f);
    void        Render ();
    void        Compile ();
    
    std::ostream &operator<<(std::ostream &os) const;
};

inline std::ostream &operator<<(std::ostream &os, const CMesh &m) { return m.operator<<(os); }
