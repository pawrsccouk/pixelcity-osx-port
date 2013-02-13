
#import <vector>
#import "glVertex.h"

struct cube
{
    std::vector<unsigned long> index_list;   // probably always .size() == 10...
    std::ostream &operator<<(std::ostream &os) const;
};
inline std::ostream &operator<<(std::ostream &os, const cube &c) { return c.operator<<(os); }

struct quad_strip
{
    std::vector<unsigned long> index_list;
    std::ostream &operator<<(std::ostream &os) const;
};
inline std::ostream &operator<<(std::ostream &os, const quad_strip &s) { return s.operator<<(os); }

struct fan
{
    std::vector<unsigned long> index_list;
    std::ostream &operator<<(std::ostream &os) const;
};
inline std::ostream &operator<<(std::ostream &os, const fan &f) { return f.operator<<(os); }

class CMesh
{
public:
    CMesh ();
    ~CMesh ();
    unsigned                _list;
    size_t                  _polycount;
    std::vector<GLvertex>   _vertex;
    std::vector<cube>       _cube;
    std::vector<quad_strip> _quad_strip;
    std::vector<fan>        _fan;
    bool                    _compiled;
    
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
