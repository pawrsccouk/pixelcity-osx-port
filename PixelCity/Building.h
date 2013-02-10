#import "entity.h"
#import "GLrgba.h"

enum BuildingType
{
  BUILDING_SIMPLE,
  BUILDING_BLOCKY,
  BUILDING_MODERN,
  BUILDING_TOWER
};

class CBuilding : public CEntity
{
private:

  int           _x, _y, _width, _depth, _height;
  unsigned long _texture_type, _seed, _roof_tiers;
  GLrgba        _color, _trim_color;
  class CMesh  *_mesh, *_mesh_flat;
  bool          _have_lights, _have_trim, _have_logo;

  void                    CreateSimple ();
  void                    CreateBlocky ();
  void                    CreateModern ();
  void                    CreateTower ();
  
  float                   ConstructWall (int start_x, int start_y, int start_z,
                                         int direction, int length, int height,
                                         unsigned long window_groups, float uv_start, bool blank_corners);
  void                    ConstructSpike (int left, int right, int front, int back, int bottom, int top);
  void                    ConstructCube (int left, int right, int front, int back, int bottom, int top);
  void                    ConstructCube (float left, float right, float front, float back, float bottom, float top);
  void                    ConstructRoof (float left, float right, float front, float back, float bottom);

public:
    CBuilding (BuildingType type, int x, int y, int height, int width, int depth, int seed, GLrgba color);
    ~CBuilding ();
    void     Render (void);
    unsigned long  PolyCount ();
    void     RenderFlat (bool colored);
    GLuint   Texture ();

    virtual std::ostream &operator<<(std::ostream &os) const;
};

inline std::ostream &operator<<(std::ostream &os, const CBuilding &b) { return b.operator<<(os); }
