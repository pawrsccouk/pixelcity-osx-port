class CLight
{
  GLvector        _position;
  GLrgba          _color;
  int             _size;
  float           _vert_size;
  float           _flat_size;
  bool            _blink;
  unsigned long   _blink_interval;
  int             _cell_x;
  int             _cell_z;

public:
  CLight(GLvector pos, GLrgba color, int size);
  void            Render ();
  void            Blink ();

};

void  LightRender ();
void  LightClear ();
unsigned long LightCount ();
