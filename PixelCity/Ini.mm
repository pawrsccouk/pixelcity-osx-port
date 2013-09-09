/*-----------------------------------------------------------------------------

  Ini.cpp

  2009 Shamus Young
  Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
  Released under the GNU GPL v3. See file COPYING for details.

-------------------------------------------------------------------------------
  
  This takes various types of data and dumps them into a predefined ini file.
  PAW: On the Mac, it stores the data in an NSUserDefaults object.

-----------------------------------------------------------------------------*/

#import <Cocoa/Cocoa.h>
#import "Model.h"
#import "ini.h"

NSString *const kFogStartDistance = @"FogStartDistance",
         *const kFogEndDistance   = @"FogEndDistance"  ,
         *const kFogDensity = @"FogDensity",
         *const kShowFog    = @"ShowFog"   ,
         *const kFogMode    = @"FogMode"   ,
         *const kFogColor   = @"FogColor"  ,
         *const kShowFPS    = @"ShowFPS"   ,
         *const kLetterbox  = @"Letterbox" ,
         *const kWireframe  = @"Wireframe" ,
         *const kFlat       = @"Flat"      ,
         *const kEffect     = @"Effect"    ,
         *const kAnimateFogColor = @"AnimateFogColor";


static const GLint MAX_RESULT = 256;

// Get the user defaults, creating and registering them if necessary.
static NSUserDefaults* GetUserDefaults()
{
	static NSUserDefaults* defs = nil;
	if(! defs) {    
        defs = [NSUserDefaults standardUserDefaults];
		[defs registerDefaults:@{
         @"Letterbox"  : @0    ,
         @"Wireframe"  : @0    ,
         @"ShowFPS"    : @0    ,
         @"Effect"     : @0    ,
         @"Flat"       : @0    ,
         @"WindowMaximized" : @0  ,
         @"WindowWidth"     : @640,
         @"WindowHeight"    : @480,
         @"WindowX"         : @50 ,
         @"WindowY"         : @50,
         kShowFog           : @1,
         kFogMode           : @0x2601, //GL_LINEAR,
         kFogStartDistance  : @512,
         kFogEndDistance    : @612,
         kFogDensity        : @1.0f,
         kFogColor          : @"0.12 0.12 0.12 0.12",
         kAnimateFogColor   : @0
         }];
	}
	return defs;
}


GLlong IniInt (NSString * key)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	return [userDefaults integerForKey:key];
}


void IniIntSet (NSString * key, int val)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	[userDefaults setInteger:val forKey:key];
}


float IniFloat (NSString * key)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	return [userDefaults floatForKey:key];
}


void IniFloatSet (NSString * key, float val)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	[userDefaults setFloat:val forKey:key];
}

NSColor *IniColor(NSString *key)
{
    NSUserDefaults *userDefaults = GetUserDefaults();
    NSString *colorString = [userDefaults stringForKey:key];
    NSScanner *scanner = [NSScanner scannerWithString:colorString];
    float red = 1.0f, green = 1.0f, blue = 1.0f, alpha = 1.0f;
    BOOL ok = YES;
    ok = ok && [scanner scanFloat:&red  ];
    ok = ok && [scanner scanFloat:&green];
    ok = ok && [scanner scanFloat:&blue ];
    ok = ok && [scanner scanFloat:&alpha];
    NSCAssert(ok, @"Failed to scan string [%@] into float, float, float, float for color [%@]", colorString, key);
    return [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
}

void IniColorSet(NSString *key, NSColor *value)
{
    NSUserDefaults *userDefs = GetUserDefaults();
    CGFloat red, green ,blue, alpha;
    [value getRed:&red green:&green blue:&blue alpha:&alpha];
    [userDefs setValue:[NSString stringWithFormat:@"%f %f %f %f", red, green, blue, alpha] forKey:key];
}

