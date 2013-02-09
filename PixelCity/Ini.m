/*-----------------------------------------------------------------------------

  Ini.cpp

  2009 Shamus Young


-------------------------------------------------------------------------------
  
  This takes various types of data and dumps them into a predefined ini file.

-----------------------------------------------------------------------------*/

#import <Cocoa/Cocoa.h>

#define FORMAT_VECTOR       "%f %f %f"
#define MAX_RESULT          256
#define FORMAT_FLOAT        "%1.2f"
#define INI_FILE            ".\\" APP ".ini"
#define SECTION             "Settings"

#include <stdio.h>
#include <stdlib.h>
//#include "glTypes.h"

#include "ini.h"
//#include "win.h"

// Get the user defaults, creating and registering them if necessary.
static NSUserDefaults* GetUserDefaults()
{
	static NSUserDefaults* defs = nil;
	if(defs == nil)
	{	defs = [NSUserDefaults standardUserDefaults];

		NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:0]  , 	 @"PWLetterbox"      ,
					[NSNumber numberWithInt:1]  , 	 @"PWWireframe"      ,
					[NSNumber numberWithInt:0]  , 	 @"PWShowFPS"        ,
					[NSNumber numberWithInt:0]  , 	 @"PWShowFog"        ,
					[NSNumber numberWithInt:0]  , 	 @"PWEffect"         ,
					[NSNumber numberWithInt:1]  , 	 @"PWFlat"           ,
					[NSNumber numberWithInt:1]  , 	 @"PWSetDefaults"    ,
					[NSNumber numberWithInt:0]  , 	 @"PWWindowMaximized",
					[NSNumber numberWithInt:640], 	 @"PWWindowWidth"    ,
					[NSNumber numberWithInt:480], 	 @"PWWindowHeight"   ,
					[NSNumber numberWithInt:50] , 	 @"PWWindowX"        ,
					[NSNumber numberWithInt:50] , 	 @"PWWindowY"        ,
					nil];
//		for (id key in d) {
//			NSLog(@"key: %@, value: %@", key, [d objectForKey:key]);
//		}

		[defs registerDefaults:d];
	}
	return defs;
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

//  return GetPrivateProfileInt (SECTION, entry, 0, INI_FILE);
long IniInt (const char* entry)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	NSString *key = [NSString stringWithFormat:@"PW%@", [NSString stringWithUTF8String:entry]];
	
	return [userDefaults integerForKey:key];
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void IniIntSet (const char* entry, int val)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	NSString *key = [NSString stringWithFormat:@"PW%@", [NSString stringWithUTF8String:entry]];
	[userDefaults setInteger:val forKey:key];

//  char        buf[20];
//  sprintf (buf, "%d", val);
//  WritePrivateProfileString (SECTION, entry, buf, INI_FILE);
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

float IniFloat (const char* entry)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	NSString *key = [NSString stringWithFormat:@"PW%@", [NSString stringWithUTF8String:entry]];
	float f = [userDefaults floatForKey:key];
	return f;
//  GetPrivateProfileString (SECTION, entry, "", result, MAX_RESULT, INI_FILE);
//  return (float)atof(result);
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void IniFloatSet (const char* entry, float val)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	NSString *key = [NSString stringWithFormat:@"PW%@", [NSString stringWithUTF8String:entry]];
	[userDefaults setFloat:val forKey:key];
	
//  char        buf[20];
//  sprintf (buf, FORMAT_FLOAT, val);
//  WritePrivateProfileString (SECTION, entry, buf, INI_FILE);
}


/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/
// Warning, the char* this returns will be autoreleased. Take a local copy or use quickly and discard.
static const char* IniString (const char* entry)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	NSString *key = [NSString stringWithFormat:@"PW%@", [NSString stringWithUTF8String:entry]];
	NSString* str = [userDefaults stringForKey:key];
	if(str) {
		return [str UTF8String];
	}
	return "";
	 
  //GetPrivateProfileString (SECTION, entry, "", result, MAX_RESULT, INI_FILE);
  //return result;
}
/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

static void IniStringSet (const char* entry, const char* val)
{
	NSUserDefaults* userDefaults = GetUserDefaults();
	NSString *key = [NSString stringWithFormat:@"PW%@", [NSString stringWithUTF8String:entry]];
	[userDefaults setObject:[NSString stringWithUTF8String:val] forKey:key];
  //WritePrivateProfileString (SECTION, entry, val, INI_FILE);
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void IniVectorSet (const char* entry, float x, float y, float z)
{
  char result[MAX_RESULT];
  sprintf(result, FORMAT_VECTOR, x, y, z);
  IniStringSet(entry, result);
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void IniVector (const char* entry, float* px, float* py, float* pz)
{
	const char *result = IniString(entry);	// result is autoreleased.
	sscanf(result, FORMAT_VECTOR, px, py, pz);
}
