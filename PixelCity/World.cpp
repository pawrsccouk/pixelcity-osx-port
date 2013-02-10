/*-----------------------------------------------------------------------------
 
 World.cpp
 
 2009 Shamus Young
 
 -------------------------------------------------------------------------------
 
 This holds a bunch of variables used by the other modules. It has the 
 claim system, which tracks all of the "property" is being used: As roads,
 buildings, etc. 
 
 -----------------------------------------------------------------------------*/

#define HUE_COUNT         (sizeof(hue_list)/sizeof(float))
#define LIGHT_COLOR_COUNT (sizeof(light_colors)/sizeof(HSL))

#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
//#include <gl\glaux.h>
#include <math.h>
#include <time.h>
#include <vector>
#include <assert.h>

#include "glTypes.h"
#include "building.h"
#include "car.h"
#include "deco.h"
#include "camera.h"
#include "light.h"
#include "macro.h"
#include "mathx.h"
#include "mesh.h"
#include "random.h"
#include "render.h"
#include "sky.h"
#include "texture.h"
#include "visible.h"
#include "win.h"
#include "world.h"
#include "PWGL.h"

using namespace std;

struct plot
{
	int             x;
	int             z;
	int             width;
	int             depth;
	
};

enum {
	FADE_IDLE,
	FADE_OUT,
	FADE_WAIT,
	FADE_IN,
};

struct HSL
{
	float     hue;
	float     sat;
	float     lum;
};

class CStreet
{
public:
	int                 _x;
	int                 _y;
	int                 _width;
	int                 _depth;
	CMesh*              _mesh;
	
	CStreet (int x, int y, int width, int depth);
	~CStreet();
	void                Render ();
	
};

static HSL            light_colors[] = 
{ 
	0.04f,  0.9f,  0.93f,   //Amber / pink
	0.055f, 0.95f, 0.93f,   //Slightly brighter amber 
	0.08f,  0.7f,  0.93f,   //Very pale amber
	0.07f,  0.9f,  0.93f,   //Very pale orange
	0.1f,   0.9f,  0.85f,   //Peach
	0.13f,  0.9f,  0.93f,   //Pale Yellow
	0.15f,  0.9f,  0.93f,   //Yellow
	0.17f,  1.0f,  0.85f,   //Saturated Yellow
	0.55f,  0.9f,  0.93f,   //Cyan
	0.55f,  0.9f,  0.93f,   //Cyan - pale, almost white
	0.6f,   0.9f,  0.93f,   //Pale blue
	0.65f,  0.9f,  0.93f,   //Pale Blue II, The Palening
	0.65f,  0.4f,  0.99f,   //Pure white. Bo-ring.
	0.65f,  0.0f,  0.8f,    //Dimmer white.
	0.65f,  0.0f,  0.6f,    //Dimmest white.
}; 

static GLrgba         g_bloom_color;
static long           g_last_update;
static char           g_world[WORLD_SIZE][WORLD_SIZE];
static CSky*          g_sky;
static unsigned long  g_fade_start = 0;
static float          g_fade_current = 0.0f;
static unsigned long  g_scene_begin = 0;
static int            g_fade_state = 0, g_modern_count = 0, g_tower_count = 0, g_blocky_count = 0, g_skyscrapers = 0, g_logo_index = 0;
static bool           g_reset_needed = false;
static GLbbox         g_hot_zone;
static time_t         g_start_time = 0;

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

static GLrgba get_light_color (float sat, float lum)
{
	int index = RandomInt(LIGHT_COLOR_COUNT);
	return glRgbaFromHsl (light_colors[index].hue, sat, lum);
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

static void claim (int x, int y, int width, int depth, int val)
{
	for (int xx = x; xx < (x + width); xx++) {
		for (int yy = y; yy < (y + depth); yy++) {
			g_world[CLAMP (xx,0,WORLD_SIZE - 1)][CLAMP (yy,0,WORLD_SIZE - 1)] |= val;
		}
	}
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

static bool claimed (int x, int y, int width, int depth)
{
	for (int xx = x; xx < x + width; xx++) {
		for (int yy = y; yy < y + depth; yy++) {
			if (g_world[CLAMP (xx,0,WORLD_SIZE - 1)][CLAMP (yy,0,WORLD_SIZE - 1)])
				return true;
		}
	}
	return false;	
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

static void build_road (int x1, int y1, int width, int depth)
{
	//the given rectangle defines a street and its sidewalk. See which way it goes.
	int lanes = (width > depth) ? depth : width;
	//if we dont have room for both lanes and sidewalk, abort
	if (lanes < 4)
		return;
	//if we have an odd number of lanes, give the extra to a divider.
	int divider;
	if (lanes % 2) {
		lanes--;
		divider = 1;
	} else
		divider = 0;
	//no more than 10 traffic lanes, give the rest to sidewalks
	int sidewalk = std::max(2, (lanes - 10));
	lanes -= sidewalk;
	sidewalk /= 2;
	//take the remaining space and give half to each direction
	lanes /= 2;
	//Mark the entire rectangle as used
	claim (x1, y1, width, depth, CLAIM_WALK);
	//now place the directional roads
	if (width > depth) {
		claim (x1, y1 + sidewalk, width, lanes, CLAIM_ROAD | MAP_ROAD_WEST);
		claim (x1, y1 + sidewalk + lanes + divider, width, lanes, CLAIM_ROAD | MAP_ROAD_EAST);
	} else {
		claim (x1 + sidewalk, y1, lanes, depth, CLAIM_ROAD | MAP_ROAD_SOUTH);
		claim (x1 + sidewalk + lanes + divider, y1, lanes, depth, CLAIM_ROAD | MAP_ROAD_NORTH);
	}
	
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

static plot find_plot (int x, int z)
{	
	//We've been given the location of an open bit of land, but we have no 
	//idea how big it is. Find the boundary.
	int x1 = x, x2 = x;
	while (!claimed (x1 - 1, z, 1, 1) && x1 > 0)
		x1--;
	while (!claimed (x2 + 1, z, 1, 1) && x2 < WORLD_SIZE)
		x2++;
	int z1 = z, z2 = z;
	while (!claimed (x, z1 - 1, 1, 1) && z1 > 0)
		z1--;
	while (!claimed (x, z2 + 1, 1, 1) && z2 < WORLD_SIZE)
		z2++;
	plot p;	
	p.width = (x2 - x1);
	p.depth = (z2 - z1);
	p.x = x1;
	p.z = z1;
	return p;
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

static plot make_plot (int x, int z, int width, int depth)
{
	plot p = {x, z, width, depth};
	return p;	
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

void do_building (plot p)
{
	//now we know how big the rectangle plot is. 
	int area = p.width * p.depth;
	GLrgba color = WorldLightColor(RandomInt());
	int seed = RandomInt();
	//Make sure the plot is big enough for a building
	if (p.width < 10 || p.depth < 10)
		return;

	//If the area is too big for one building, sub-divide it.
	if (area > 800) {
		if (COIN_FLIP()) {
			p.width /= 2;
			if (COIN_FLIP())
				do_building (make_plot (p.x, p.z, p.width, p.depth));
			else
				do_building (make_plot (p.x + p.width, p.z, p.width, p.depth));
			return;
		} else {
			p.depth /= 2;
			if (COIN_FLIP())
				do_building (make_plot (p.x, p.z, p.width, p.depth));
			else
				do_building (make_plot (p.x, p.z + p.depth, p.width, p.depth));
			return;
		}
	}
	if (area < 100)
		return;
        //The plot is "square" if width & depth are close
	bool square = abs (p.width - p.depth) < 10;
        //mark the land as used so other buildings don't appear here, even if we don't use it all.
	claim (p.x, p.z, p.width, p.depth, CLAIM_BUILDING);
	
	//The roundy mod buildings look best on square plots.
	if (square && p.width > 20) {
		int height = 45 + RandomInt(10);
		g_modern_count++;
		g_skyscrapers++;
		new CBuilding (BUILDING_MODERN, p.x, p.z, height, p.width, p.depth, seed, color);
		return;
	}
	
	 //Rectangular plots are a good place for Blocky style buildings to sprawl blockily.
	 if (p.width > p.depth * 2 || (p.depth > p.width * 2 && area > 800)) {
		 int height = 20 + RandomInt(10);
		 g_blocky_count++;
		 g_skyscrapers++;
		 new CBuilding (BUILDING_BLOCKY, p.x, p.z, height, p.width, p.depth, seed, color);
		 return;
	 }
	
	//g_tower_count = -1;
	//This spot isn't ideal for any particular building, but try to keep a good mix
	BuildingType type = BUILDING_SIMPLE;
	if (g_tower_count < g_modern_count && g_tower_count < g_blocky_count) {
		type = BUILDING_TOWER;
		g_tower_count++;
	} else if (g_blocky_count < g_modern_count) {
		type = BUILDING_BLOCKY;
		g_blocky_count++;
	} else {
		type = BUILDING_MODERN;
		g_modern_count++;
	}
	int height = 45 + RandomInt(10);
	new CBuilding (type, p.x, p.z, height, p.width, p.depth, seed, color);
	g_skyscrapers++;
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

static int build_light_strip (int x1, int z1, int direction)
{
	glReportError("build_light_strip START");
	
	CDeco*  d;
	GLrgba  color;
	int     x2, z2;
	int     length;
	int     width, depth;
	int     dir_x, dir_z;
	float   size_adjust;
	
	//We adjust the size of the lights with this.  
	size_adjust = 2.5f;
	color = glRgbaFromHsl (0.09f,  0.99f,  0.85f);
	switch (direction) {
		case NORTH:
			dir_z = 1; dir_x = 0;break;
		case SOUTH:
			dir_z = 1; dir_x = 0;break;
		case EAST:
			dir_z = 0; dir_x = 1;break;
		case WEST:
			dir_z = 0; dir_x = 1;break;
	}
	//So we know we're on the corner of an intersection
	//look in the given  until we reach the end of the sidewalk
	x2 = x1;
	z2 = z1;
	length = 0;
	while (x2 > 0 && x2 < WORLD_SIZE && z2 > 0 && z2 < WORLD_SIZE) {
		if ((g_world[x2][z2] & CLAIM_ROAD))
			break;
		length++;
		x2 += dir_x;
		z2 += dir_z;
	}
	if (length < 10) {
		glReportError("build_light_strip END early.");
		return length;
	}
	width = std::max(abs(x2 - x1), 1);
	depth = std::max(abs(z2 - z1), 1);
	d = new CDeco;
	if (direction == EAST)
		d->CreateLightStrip ((float)x1, (float)z1 - size_adjust, (float)width, (float)depth + size_adjust, 2, color);
	else if (direction == WEST)
		d->CreateLightStrip ((float)x1, (float)z1, (float)width, (float)depth + size_adjust, 2, color);
	else if (direction == NORTH)
		d->CreateLightStrip ((float)x1, (float)z1, (float)width + size_adjust, (float)depth, 2, color);
	else
		d->CreateLightStrip ((float)x1 - size_adjust, (float)z1, (float)width + size_adjust, (float)depth, 2, color);
	
	glReportError("build_light_strip END");
	return length;
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

static void do_reset (void)
{	
	int       x, y;
	unsigned int depth, width, height;
	int       attempts;
	bool      road_left, road_right;
	GLrgba    light_color;
	GLrgba    building_color;
	float     west_street, north_street, east_street, south_street;
	glReportError("do_reset BEGIN");
	//Re-init Random to make the same city each time. Helpful when running tests.
	RandomInit (6);
	g_reset_needed = false;
	bool broadway_done = false;
	g_skyscrapers = 0;
	g_logo_index = 0;
	g_scene_begin = 0;
	g_tower_count = g_blocky_count = g_modern_count = 0;
	g_hot_zone = glBboxClear ();
	EntityClear ();
	LightClear ();
	CarClear ();
	TextureReset ();
	glReportError("do_reset after clearing Entities, Lights, Cars & Textures.");
	
	//Pick a tint for the bloom 
	g_bloom_color = get_light_color(0.5f + (float)RandomLong (10) / 20.0f, 0.75f);
	light_color = glRgbaFromHsl (0.11f, 1.0f, 0.65f);
	memset(g_world, 0, WORLD_SIZE * WORLD_SIZE);
	for (y = WORLD_EDGE; y < WORLD_SIZE - WORLD_EDGE; y += RandomLong (25) + 25) {
		if (!broadway_done && y > WORLD_HALF - 20) {
			build_road (0, y, WORLD_SIZE, 19);
			y += 20;
			broadway_done = true;
		} else {
			depth = 6 + RandomInt(6);
			if (y < WORLD_HALF / 2)
				north_street = (float)(y + depth / 2);
			if (y < (WORLD_SIZE - WORLD_HALF / 2))
				south_street = (float)(y + depth / 2);
			build_road (0, y, WORLD_SIZE, depth);
		}
	}
	
	broadway_done = false;
	for (x = WORLD_EDGE; x < WORLD_SIZE - WORLD_EDGE; x += RandomLong (25) + 25) {
		if (!broadway_done && x > WORLD_HALF - 20) {
			build_road (x, 0, 19, WORLD_SIZE);
			x += 20;
			broadway_done = true;
		} else {
			width = 6 + RandomInt(6);
			if (x <= WORLD_HALF / 2)
				west_street = (float)(x + width / 2);
			if (x <= WORLD_HALF + WORLD_HALF / 2)
				east_street = (float)(x + width / 2);
			build_road (x, 0, width, WORLD_SIZE);
		}
	}
	//We kept track of the positions of streets that will outline the high-detail hot zone 
	//in the middle of the world.  Save this in a bounding box so that later we can 
	//have the camera fly around without clipping through buildings.
	g_hot_zone = glBboxContainPoint (g_hot_zone, glVector (west_street, 0.0f, north_street)); 
	g_hot_zone = glBboxContainPoint (g_hot_zone, glVector (east_street, 0.0f, south_street));
	
	//Scan for places to put runs of streetlights on the east & west side of the road
	for (x = 1; x < WORLD_SIZE - 1; x++) {
		for (y = 0; y < WORLD_SIZE; y++) {
			//if this isn't a bit of sidewalk, then keep looking
			if (!(g_world[x][y] & CLAIM_WALK))
				continue;
			//If it's used as a road, skip it.
			if ((g_world[x][y] & CLAIM_ROAD))
				continue;
			road_left = (g_world[x + 1][y] & CLAIM_ROAD) != 0;
			road_right = (g_world[x - 1][y] & CLAIM_ROAD) != 0;
			//if the cells to our east and west are not road, then we're not on a corner. 
			if (!road_left && !road_right)
				continue;
			//if the cell to our east AND west is road, then we're on a median. skip it
			if (road_left && road_right)
				continue;
			y += build_light_strip (x, y, road_right ? SOUTH : NORTH);
		}
	}
	
	//Scan for places to put runs of streetlights on the north & south side of the road
	for (y = 1; y < WORLD_SIZE - 1; y++) {
		for (x = 1; x < WORLD_SIZE - 1; x++) {
			//if this isn't a bit of sidewalk, then keep looking
			if (!(g_world[x][y] & CLAIM_WALK))
				continue;
			//If it's used as a road, skip it.
			if ((g_world[x][y] & CLAIM_ROAD))
				continue;
			road_left = (g_world[x][y + 1] & CLAIM_ROAD) != 0;
			road_right = (g_world[x][y - 1] & CLAIM_ROAD) != 0;
			//if the cell to our east AND west is road, then we're on a median. skip it
			if (road_left && road_right)
				continue;
			//if the cells to our north and south are not road, then we're not on a corner. 
			if (!road_left && !road_right)
				continue;
			x += build_light_strip (x, y, road_right ? EAST : WEST);
		}
	}
  	glReportError("do_reset After Streetlights");
	
	//Scan over the center area of the map and place the big buildings 
	attempts = 0;
	while (g_skyscrapers < 50 && attempts < 350) {
		x = (WORLD_HALF / 2) + (RandomLong () % WORLD_HALF);
		y = (WORLD_HALF / 2) + (RandomLong () % WORLD_HALF);
		if (!claimed (x, y, 1,1)) {
			do_building (find_plot (x, y));
			g_skyscrapers++;
		}
		attempts++;
	}
  	glReportError("do_reset After big buildings");

	//now blanket the rest of the world with lesser buildings
	for (x = 0; x < WORLD_SIZE; x ++) {
		for (y = 0; y < WORLD_SIZE; y ++) {
			if (g_world[CLAMP (x,0,WORLD_SIZE)][CLAMP (y,0,WORLD_SIZE)])
				continue;
			width = 12 + RandomInt(20);
			depth = 12 + RandomInt(20);
			height = std::min(width, depth);
			if (x < 30 || y < 30 || x > WORLD_SIZE - 30 || y > WORLD_SIZE - 30)
				height = RandomInt(15) + 20;
			else if (x < WORLD_HALF / 2)
				height /= 2;
			while (width > 8 && depth > 8) {
				if (!claimed (x, y, width, depth)) {
					claim(x, y, width, depth, CLAIM_BUILDING);
					building_color = WorldLightColor (RandomInt());
                        //if we're out of the hot zone, use simple buildings
					if (x < g_hot_zone.min.x || x > g_hot_zone.max.x || y < g_hot_zone.min.z || y > g_hot_zone.max.z) {
						height = 5 + RandomInt(height) + RandomInt(height);
						new CBuilding (BUILDING_SIMPLE, x + 1, y + 1, height, width - 2, depth - 2, RandomInt(), building_color);
					} else { //use fancy buildings.
						height = 15 + RandomInt(15);
						width -=2;
						depth -=2;
						new CBuilding((COIN_FLIP() ? BUILDING_TOWER : BUILDING_BLOCKY), x + 1, y + 1, height, width, depth, RandomInt(), building_color);
					}
					break;
				}
				width--;
				depth--;
			}
                //leave big gaps near the edge of the map, no need to pack detail there.
			if (y < WORLD_EDGE || y > WORLD_SIZE - WORLD_EDGE) 
				y += 32;
		}
            //leave big gaps near the edge of the map
		if (x < WORLD_EDGE || x > WORLD_SIZE - WORLD_EDGE) 
			x += 28;
	}
}

/*-----------------------------------------------------------------------------
 
 This will return a random color which is suitible for light sources, taken
 from a narrow group of hues. (Yellows, oranges, blues.)
 
 -----------------------------------------------------------------------------*/

GLrgba WorldLightColor (unsigned index)
{
	index %= LIGHT_COLOR_COUNT;
	return glRgbaFromHsl (light_colors[index].hue, light_colors[index].sat, light_colors[index].lum);	
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

char WorldCell (int x, int y)
{
	return g_world[CLAMP (x, 0,WORLD_SIZE - 1)][CLAMP (y, 0, WORLD_SIZE - 1)];	
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

GLrgba WorldBloomColor ()
{	
	return g_bloom_color;	
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

int WorldLogoIndex ()
{
	return g_logo_index++;	
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

GLbbox WorldHotZone ()
{
	
	return g_hot_zone;
	
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

void WorldTerm (void)
{
	
	
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

void WorldReset (void)
{
	
	//If we're already fading out, then this is the developer hammering on the 
	//"rebuild" button.  Let's hurry things up for the nice man...
	if (g_fade_state == FADE_OUT) 
		do_reset ();
	//If reset is called but the world isn't ready, then don't bother fading out.
	//The program probably just started.
	g_fade_state = FADE_OUT;
	g_fade_start = GetTickCount ();
	
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

void WorldRender ()
{
	if (!SHOW_DEBUG_GROUND) 
		return;
	//Render a single texture over the city that shows traffic lanes
	pwDepthMask (GL_FALSE);
	pwDisable (GL_CULL_FACE);
	pwDisable (GL_BLEND);
	pwEnable (GL_TEXTURE_2D);
	glColor3f (1,1,1);
	pwBindTexture (GL_TEXTURE_2D, 0);
	{	MakePrimitive mp(GL_QUADS);
		glTexCoord2f (0, 0);   glVertex3f ( 0, 0, 0);
		glTexCoord2f (0, 1);   glVertex3f ( 0, 0,  1024);
		glTexCoord2f (1, 1);   glVertex3f ( 1024, 0, 1024);
		glTexCoord2f (1, 0);   glVertex3f ( 1024, 0, 0);
	}
	pwDepthMask (GL_TRUE);
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

float WorldFade (void)
{
	
	return g_fade_current;
	
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

unsigned long WorldSceneBegin()
{
	return g_scene_begin;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

// How long since this current iteration of the city went on display,
unsigned long WorldSceneElapsed()
{
	unsigned long elapsed = (!EntityReady () || !WorldSceneBegin ()) ? 1
                                                                     : GetTickCount () - (WorldSceneBegin());
	return std::max(elapsed, 1ul);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void WorldUpdate (void)
{	
	unsigned long now = GetTickCount ();
	if (g_reset_needed) {
		do_reset (); //Now we've faded out the scene, rebuild it
	}
	if (g_fade_state != FADE_IDLE) {
		if (g_fade_state == FADE_WAIT && TextureReady () && EntityReady ()) {
			g_fade_state = FADE_IN;
			g_fade_start = now;
			g_fade_current = 1.0f;
		}    
		unsigned long fade_delta = now - g_fade_start;
		//See if we're done fading in or out
		if (fade_delta > FADE_TIME && g_fade_state != FADE_WAIT) {
			if (g_fade_state == FADE_OUT) {
				g_reset_needed = true;
				g_fade_state = FADE_WAIT;
				g_fade_current = 1.0f;
			} else {
				g_fade_state = FADE_IDLE;
				g_fade_current = 0.0f;
				g_start_time = time (NULL);
				g_scene_begin = GetTickCount ();
			}
		} else {
			g_fade_current = (float)fade_delta / FADE_TIME;
			if (g_fade_state == FADE_IN)
				g_fade_current = 1.0f - g_fade_current;
			if (g_fade_state == FADE_WAIT)
				g_fade_current = 1.0f;
		}
		if (!TextureReady ())
			g_fade_current = 1.0f;
	} 
	if (g_fade_state == FADE_IDLE && !TextureReady ()) {
		g_fade_state = FADE_IN;
		g_fade_start = now;
	}
	if (g_fade_state == FADE_IDLE && WorldSceneElapsed () > RESET_INTERVAL)
		WorldReset ();
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

void WorldInit (void)
{
	g_last_update = GetTickCount ();
	
	for (int i = 0; i < CARS; i++)
		new CCar ();
	g_sky = new CSky ();
	
	WorldReset ();
	g_fade_state = FADE_OUT;
	g_fade_start = 0;
}

int MakePrimitive::nestCount = 0;
int MakeDisplayList::nestCount = 0;

MakePrimitive::MakePrimitive(GLenum type)
{
	//DebugLog("MakePrimitive::MakePrimitive");
	assert(nestCount == 0);
	pwBegin(type);
	++nestCount;
}

MakePrimitive::~MakePrimitive()
{
	//DebugLog("MakePrimitive::~MakePrimitive");
	assert(nestCount == 1);
	pwEnd();
	--nestCount;
}

MakeDisplayList::MakeDisplayList(GLint name, GLenum mode)
{
	assert(nestCount == 0);	assert(glIsList(name));
	pwNewList(name, mode);
	++nestCount;
}

MakeDisplayList::~MakeDisplayList()
{	
	assert(nestCount == 1);
	pwEndList();
	--nestCount;
}


DebugRep::DebugRep(const char* location)
: _location(location)
{
	DebugLog("Entered %s", _location);
}

DebugRep::~DebugRep()
{
	DebugLog("Left %s", _location);
}

