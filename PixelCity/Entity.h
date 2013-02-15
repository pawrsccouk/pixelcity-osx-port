
#ifndef PixelCity_ENTITY
#define PixelCity_ENTITY

class CEntity
{
private:
protected:

  GLvector _center;

public:
  CEntity (void);
  virtual ~CEntity () {};
  
        // Properties
  virtual GLuint          Texture ()  const;
  virtual bool            Alpha ()    const;
  virtual unsigned long   PolyCount() const;
  GLvector Center() const;
  
        // Methods
  virtual void Render (void);
  virtual void RenderFlat (bool wirefame);
  virtual void Update (void);
  
  virtual std::ostream &operator<<(std::ostream &os) const;
};

inline std::ostream &operator<<(std::ostream &os, const CEntity &e) { return e.operator<<(os); }
 
inline GLuint        CEntity::Texture ()  const { return 0; }
inline bool          CEntity::Alpha ()    const { return false; }
inline unsigned long CEntity::PolyCount() const { return 0; }
inline GLvector      CEntity::Center()    const { return _center; }


#ifdef __cplusplus
extern "C" {
#endif

void      EntityClear ();
size_t    EntityCount (void);
float     EntityProgress ();
bool      EntityReady ();
void      EntityRender (bool showFlat);
void      EntityUpdate (void);
int       EntityPolyCount (void);
void      EntityDump(void);

#ifdef __cplusplus
}
#endif


#endif