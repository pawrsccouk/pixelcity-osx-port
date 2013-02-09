
#ifdef __cplusplus
extern "C" {
#endif

long      IniInt      (const char* entry);
void      IniIntSet   (const char* entry, int val);
float     IniFloat    (const char* entry);
void      IniFloatSet (const char* entry, float val);
//char*     IniString   (const char* entry);
//void      IniStringSet(const char* entry, const char* val);
void      IniVectorSet(const char* entry, float   x, float   y, float   z);
void      IniVector   (const char* entry, float* px, float* py, float* pz);

#ifdef __cplusplus
}
#endif

