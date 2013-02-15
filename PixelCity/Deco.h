#import "entity.h"
#import "glRGBA.h"

class CDeco : CEntity
{
  GLrgba        _color;
  class CMesh*  _mesh;
  int           _type;
  unsigned      _texture;
  bool          _use_alpha;

public:
                CDeco ();
                ~CDeco ();
  void          CreateLogo(const GLvector2 &start, const GLvector2 &end, float base, int seed, const GLrgba &color);
  void          CreateLightStrip (float x, float z, float width, float depth, float height, GLrgba color);
  void          CreateLightTrim (GLvector* chain, int count, float height, unsigned long seed, GLrgba color);
  void          CreateRadioTower (GLvector pos, float height);
  void          Render (void);
  void          RenderFlat (bool colored);
  
  bool          Alpha () const;
  unsigned long PolyCount () const;
  GLuint        Texture () const;
};