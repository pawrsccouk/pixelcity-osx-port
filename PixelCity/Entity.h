
#ifndef PixelCity_ENTITY
#define PixelCity_ENTITY

@interface Entity : NSObject
{
  GLvector _center;

}
-(id)init;
@property (nonatomic) GLuint texture;
@property (nonatomic) BOOL alpha;
@property (nonatomic) unsigned long polyCount;
@property (nonatomic, readonly) GLvector center;
  
        // Virtual Methods
-(void) Render;
-(void) RenderFlat:(BOOL) wirefame;
-(void) Update;
@end

//inline std::ostream &operator<<(std::ostream &os, const CEntity &e) { return e.operator<<(os); }
// 
//inline GLuint        CEntity::Texture ()  const { return 0; }
//inline bool          CEntity::Alpha ()    const { return false; }
//inline unsigned long CEntity::PolyCount() const { return 0; }
//inline GLvector      CEntity::Center()    const { return _center; }
//inline void CEntity::Render (void) const               {}
//inline void CEntity::RenderFlat (bool wireframe) const {}
//inline void CEntity::Update (void)                     {}


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