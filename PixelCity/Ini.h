
#ifdef __cplusplus
extern "C" {
#endif

GLlong    IniInt      (const char* entry);
void      IniIntSet   (const char* entry, int val);
float     IniFloat    (const char* entry);
void      IniFloatSet (const char* entry, float val);

#ifdef __cplusplus
}
#endif

