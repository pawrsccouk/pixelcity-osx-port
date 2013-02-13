#ifndef TYPES
#import "glTypes.h"
#endif

#ifndef ENTITY

#define ENTITY

class CEntity
{
private:
protected:

  GLvector                _center;

public:
                          CEntity (void);
  virtual                 ~CEntity () {};
  virtual void            Render (void);
  virtual void            RenderFlat (bool wirefame);
  virtual GLuint          Texture () { return 0; }
  virtual void            Update (void);
  virtual bool            Alpha () { return false; }
  virtual unsigned long   PolyCount () { return 0; }
  GLvector                Center () { return _center; }
  
  virtual std::ostream &operator<<(std::ostream &os) const;
};

inline std::ostream &operator<<(std::ostream &os, const CEntity &e) { return e.operator<<(os); }

void      EntityClear ();
int       EntityCount (void);
float     EntityProgress ();
bool      EntityReady ();
void      EntityRender (bool showFlat);
void      EntityUpdate (void);
int       EntityPolyCount (void);
void      EntityDump(std::ostream &os);

#endif