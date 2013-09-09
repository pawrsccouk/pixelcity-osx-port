// 2009 Shamus Young
// Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
// Released under the GNU GPL v3. See file COPYING for details.

    // Keys for the preference values
extern NSString * const kFogStartDistance, * const kFogEndDistance, * const kFogDensity, * const kShowFog, * const kFogMode, * const kFogColor;
extern NSString * const kShowFPS, * const kLetterbox, * const kWireframe, * const kFlat, * const kEffect , * const kAnimateFogColor;

#ifdef __cplusplus
extern "C" {
#endif

GLlong    IniInt      (NSString * entry);
void      IniIntSet   (NSString * entry, int val);
float     IniFloat    (NSString * entry);
void      IniFloatSet (NSString * entry, float val);
NSColor  *IniColor    (NSString * entry);
void      IniColorSet (NSString * entry, NSColor *val);

#ifdef __cplusplus
}
#endif

