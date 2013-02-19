/*-----------------------------------------------------------------------------

  Ini.cpp

  2009 Shamus Young


-------------------------------------------------------------------------------
  
  This takes various types of data and dumps them into a predefined ini file.

-----------------------------------------------------------------------------*/

#import <Cocoa/Cocoa.h>
#import "Model.h"
#import "ini.h"

static const GLint MAX_RESULT = 256;

// Get the user defaults, creating and registering them if necessary.
static NSUserDefaults* GetUserDefaults()
{
	static NSUserDefaults* defs = nil;
	if(! defs) {
        defs = [NSUserDefaults standardUserDefaults];
		[defs registerDefaults:@{
         @"PWLetterbox"  : @0    ,
         @"PWWireframe"  : @0    ,
         @"PWShowFPS"    : @0    ,
         @"PWShowFog"    : @0    ,
         @"PWEffect"     : @0    ,
         @"PWFlat"       : @0    ,
         @"PWWindowMaximized" : @0  ,
         @"PWWindowWidth"     : @640,
         @"PWWindowHeight"    : @480,
         @"PWWindowX"         : @50 ,
         @"PWWindowY"         : @50}];
	}
	return defs;
}


GLlong IniInt (const char* entry)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	NSString *key = [NSString stringWithFormat:@"PW%@", [NSString stringWithUTF8String:entry]];
	return [userDefaults integerForKey:key];
}


void IniIntSet (const char* entry, int val)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	NSString *key = [NSString stringWithFormat:@"PW%@", [NSString stringWithUTF8String:entry]];
	[userDefaults setInteger:val forKey:key];
}


float IniFloat (const char* entry)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	NSString *key = [NSString stringWithFormat:@"PW%@", [NSString stringWithUTF8String:entry]];
	return [userDefaults floatForKey:key];
}


void IniFloatSet (const char* entry, float val)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	NSString *key = [NSString stringWithFormat:@"PW%@", [NSString stringWithUTF8String:entry]];
	[userDefaults setFloat:val forKey:key];
}


