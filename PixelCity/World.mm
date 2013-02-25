/*-----------------------------------------------------------------------------
 
 World.cpp
 
 2009 Shamus Young
 
 -------------------------------------------------------------------------------
 
 This holds a bunch of variables used by the other modules. It has the 
 claim system, which tracks all of the "property" is being used: As roads,
 buildings, etc. 
 
 -----------------------------------------------------------------------------*/


#import "Model.h"
#import "building.h"
#import "car.h"
#import "deco.h"
#import "light.h"
#import "mesh.h"
#import "render.h"
#import "sky.h"
#import "texture.h"
#import "visible.h"
#import "win.h"
#import "world.h"

using namespace std;

struct plot
{
	int x, z, width, depth;
};

typedef enum FadeType {
	FADE_IDLE, FADE_OUT, FADE_WAIT, FADE_IN,
} FadeType;

struct HSL
{
	float hue, sat, lum;
};

static const HSL light_colors[] =
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
static const size_t LIGHT_COLOR_COUNT = (sizeof(light_colors)/sizeof(HSL));

struct BuildingCounts {
    GLuint modern, tower, blocky, skyscraper;
    void reset() { modern = tower = blocky = skyscraper = 0; }
    BuildingCounts()  { reset(); }
};

@interface World ()
{
    BOOL _resetNeeded;
    time_t   _startTime;
    GLlong   _lastUpdate;
    char     _world[WORLD_SIZE][WORLD_SIZE];
    BuildingCounts _counts;
    FadeType _fade;
}
@end

@implementation World
@synthesize cars = _cars, bloomColor = _bloomColor, logoIndex = _logoIndex, hotZone = _hotZone;
@synthesize fadeStart = _fadeStart, fadeCurrent = _fadeCurrent, sceneBegin = _sceneBegin, sceneElapsed = _sceneElapsed;
@synthesize lights = _lights;

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static GLrgba get_light_color (float sat, float lum)
{
	int index = RandomIntR(LIGHT_COLOR_COUNT);
	return glRgbaFromHsl (light_colors[index].hue, sat, lum);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) claimPlot:(plot) plot value:(int) val
{
	for (int xx = plot.x; xx < (plot.x + plot.width); xx++) {
		for (int yy = plot.z; yy < (plot.z + plot.depth); yy++) {
			_world[CLAMP (xx, 0, WORLD_SIZE - 1)][CLAMP (yy, 0, WORLD_SIZE - 1)] |= val;
		}
	}
}

-(BOOL) claimed:(plot) plot
{
	for (int xx = plot.x; xx < plot.x + plot.width; xx++) {
		for (int yy = plot.z; yy < plot.z + plot.depth; yy++) {
			if (_world[CLAMP (xx, 0, WORLD_SIZE - 1)][CLAMP (yy, 0, WORLD_SIZE - 1)])
				return YES;
		}
	}
	return NO;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) buildRoadAtX:(int) x1 y:(int) y1 width:(int) width depth:(int) depth
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
	[self claimPlot:makePlot(x1, y1, width, depth) value:CLAIM_WALK];
	//now place the directional roads
	if (width > depth) {
		[self claimPlot:makePlot(x1, y1 + sidewalk, width, lanes) value:CLAIM_ROAD | MAP_ROAD_WEST];
		[self claimPlot:makePlot(x1, y1 + sidewalk + lanes + divider, width, lanes) value:CLAIM_ROAD | MAP_ROAD_EAST];
	} else {
		[self claimPlot:makePlot(x1 + sidewalk, y1, lanes, depth) value:CLAIM_ROAD | MAP_ROAD_SOUTH];
		[self claimPlot:makePlot(x1 + sidewalk + lanes + divider, y1, lanes, depth) value:CLAIM_ROAD | MAP_ROAD_NORTH];
	}
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(plot) findPlotAtX:(int) x z:(int) z
{	
	//We've been given the location of an open bit of land, but we have no 
	//idea how big it is. Find the boundary.
	int x1 = x, x2 = x;
	while (! [self claimed:makePlot(x1 - 1, z, 1, 1)] && x1 > 0)
		x1--;
	while (! [self claimed:makePlot(x2 + 1, z, 1, 1)] && x2 < WORLD_SIZE)
		x2++;
	int z1 = z, z2 = z;
	while (! [self claimed:makePlot(x, z1 - 1, 1, 1)] && z1 > 0)
		z1--;
	while (! [self claimed:makePlot(x, z2 + 1, 1, 1)] && z2 < WORLD_SIZE)
		z2++;
	plot p;	
	p.width = (x2 - x1);
	p.depth = (z2 - z1);
	p.x = x1;
	p.z = z1;
	return p;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static plot makePlot(int x, int z, int width, int depth)
{
	plot p = {x, z, width, depth};
	return p;	
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


-(void) doBuildingWithPlot:(plot)p
{
	//now we know how big the rectangle plot is. 
	int area = p.width * p.depth;
	GLrgba color = [self lightColorAtIndex:RandomInt()];
	int seed = RandomInt();
	//Make sure the plot is big enough for a building
	if (p.width < 10 || p.depth < 10)
		return;

	//If the area is too big for one building, sub-divide it.
	if (area > 800) {
		if (COIN_FLIP()) {
			p.width /= 2;
			if (COIN_FLIP())
				[self doBuildingWithPlot:makePlot(p.x, p.z, p.width, p.depth)];
			else
				[self doBuildingWithPlot:makePlot(p.x + p.width, p.z, p.width, p.depth)];
			return;
		} else {
			p.depth /= 2;
			if (COIN_FLIP())
				[self doBuildingWithPlot:makePlot(p.x, p.z, p.width, p.depth)];
			else
				[self doBuildingWithPlot:makePlot(p.x, p.z + p.depth, p.width, p.depth)];
			return;
		}
	}
	if (area < 100)
		return;
        //The plot is "square" if width & depth are close
	bool square = abs (p.width - p.depth) < 10;
        //mark the land as used so other buildings don't appear here, even if we don't use it all.
	[self claimPlot:p value:CLAIM_BUILDING];
	
    Building *b = nil;
	//The roundy mod buildings look best on square plots.
	if (square && p.width > 20) {
		int height = 45 + RandomIntR(10);
		_counts.modern++;
		_counts.skyscraper++;
		b = [[Building alloc] initWithType:BUILDING_MODERN x:p.x y:p.z height:height width:p.width depth:p.depth seed:seed color:color world:self];
		return;
	}
	
	 //Rectangular plots are a good place for Blocky style buildings to sprawl blockily.
	 if (p.width > p.depth * 2 || (p.depth > p.width * 2 && area > 800)) {
		 int height = 20 + RandomIntR(10);
		 _counts.blocky++;
		 _counts.skyscraper++;
		 b = [[Building alloc] initWithType:BUILDING_BLOCKY x:p.x y:p.z height:height width:p.width depth:p.depth seed:seed color:color world:self];
		 return;
	 }
	
	//g_tower_count = -1;
	//This spot isn't ideal for any particular building, but try to keep a good mix
	BuildingType type = BUILDING_SIMPLE;
	if (_counts.tower < _counts.modern && _counts.tower < _counts.blocky) {
		type = BUILDING_TOWER;
		_counts.tower++;
	} else if (_counts.blocky < _counts.modern) {
		type = BUILDING_BLOCKY;
		_counts.blocky++;
	} else {
		type = BUILDING_MODERN;
		_counts.modern++;
	}
	int height = 45 + RandomIntR(10);
	b = [[Building alloc] initWithType:type x:p.x y:p.z height:height width:p.width depth:p.depth seed:seed color:color world:self];
	_counts.skyscraper++;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(int) buildLightStripAtX:(int) x1 z:(int) z1 direction:(int) direction
{
	glReportError("build_light_strip START");
	
	int     dir_x, dir_z;
	switch (direction) {
		case NORTH:	dir_z = 1; dir_x = 0;break;
		case SOUTH:	dir_z = 1; dir_x = 0;break;
		case EAST:	dir_z = 0; dir_x = 1;break;
		case WEST:	dir_z = 0; dir_x = 1;break;
	}
	//So we know we're on the corner of an intersection
	//look in the given  until we reach the end of the sidewalk
	int x2 = x1, z2 = z1, length = 0;
	while (x2 > 0 && x2 < WORLD_SIZE && z2 > 0 && z2 < WORLD_SIZE)
    {
		if ((_world[x2][z2] & CLAIM_ROAD))
			break;
		length++;
		x2 += dir_x;
		z2 += dir_z;
	}
	if (length < 10) {
		glReportError("build_light_strip END early.");
		return length;
	}
	int width = std::max(abs(x2 - x1), 1);
	int depth = std::max(abs(z2 - z1), 1);
	GLrgba color = glRgbaFromHsl (0.09f,  0.99f,  0.85f);
	float size_adjust = 2.5f;	//We adjust the size of the lights with this.  
	Deco *d = [[Deco alloc] initWithWorld:self];
	if (direction == EAST)
		[d CreateLightStripWithX:(float)x1 z:(float)z1 - size_adjust width:(float)width depth:(float)depth + size_adjust height:2 color:color];
	else if (direction == WEST)
		[d CreateLightStripWithX:(float)x1 z:(float)z1 width:(float)width depth:(float)depth + size_adjust height:2 color:color];
	else if (direction == NORTH)
		[d CreateLightStripWithX:(float)x1 z:(float)z1 width:(float)width + size_adjust depth:(float)depth height:2 color:color];
	else
		[d CreateLightStripWithX:(float)x1 - size_adjust z:(float)z1 width:(float)width + size_adjust depth:(float)depth height:2 color:color];
	
	glReportError("build_light_strip END");
	return length;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) buildStreetlights
{
	//Scan for places to put runs of streetlights on the north & south side of the road
	for (int x = 1; x < WORLD_SIZE - 1; x++)
    {
		for (int y = 0; y < WORLD_SIZE; y++)
        {
			if((!(_world[x][y] & CLAIM_WALK))   //if this isn't a bit of sidewalk, then keep looking
            || ( (_world[x][y] & CLAIM_ROAD)) ) //also if it's used as a road, skip it.
				continue;
            
			bool road_left  = (_world[x + 1][y] & CLAIM_ROAD) != 0;
			bool road_right = (_world[x - 1][y] & CLAIM_ROAD) != 0;
            
			if((!road_left && !road_right)	//if the cells to our east and west are not road, then we're not on a corner.
            ||  (road_left &&  road_right))	//if the cell to our east AND west is road, then we're on a median. skip it
				continue;
            
			y += [self buildLightStripAtX:x z:y direction:road_right ? SOUTH : NORTH];
		}
	}

        //Scan for places to put runs of streetlights on the north & south side of the road
    for (int y = 1; y < WORLD_SIZE - 1; y++) {
        for (int x = 1; x < WORLD_SIZE - 1; x++) {
            
            if((!(_world[x][y] & CLAIM_WALK))   //if this isn't a bit of sidewalk, then keep looking
            || ( (_world[x][y] & CLAIM_ROAD)))   //If it's used as a road, skip it.
                continue;
            
            bool road_left  = (_world[x][y + 1] & CLAIM_ROAD) != 0;
            bool road_right = (_world[x][y - 1] & CLAIM_ROAD) != 0;
            
            if(( road_left &&  road_right)    //if the cell to our east AND west is road, then we're on a median. skip it
            || (!road_left && !road_right))    //if the cells to our north and south are not road, then we're not on a corner.
                continue;
            
            x += [self buildLightStripAtX:x z:y direction:road_right ? EAST : WEST];
        }
    }
}


    // Builds all the roads needed. Returns a bounding box enclosing the roadmap just built
-(GLbbox) buildRoads
{
    float west_street, north_street, east_street, south_street;
    bool broadway_done = false;
	for (int y = WORLD_EDGE; y < WORLD_SIZE - WORLD_EDGE; y += RandomLongR(25) + 25) {
		if (!broadway_done && y > WORLD_HALF - 20) {
			[self buildRoadAtX:0 y:y width:WORLD_SIZE depth:19];
			y += 20;
			broadway_done = true;
		} else {
			GLuint depth = 6 + RandomIntR(6);
			if (y < WORLD_HALF / 2)
				north_street = (float)(y + depth / 2);
			if (y < (WORLD_SIZE - WORLD_HALF / 2))
				south_street = (float)(y + depth / 2);
			[self buildRoadAtX:0 y:y width:WORLD_SIZE depth:depth];
		}
	}
	
	broadway_done = false;
	for (int x = WORLD_EDGE; x < WORLD_SIZE - WORLD_EDGE; x += RandomLongR(25) + 25)
    {
		if (!broadway_done && x > WORLD_HALF - 20) {
			[self buildRoadAtX:x y:0 width:19 depth:WORLD_SIZE];
			x += 20;
			broadway_done = true;
		}
        else {
			GLuint width = 6 + RandomIntR(6);
			if (x <= WORLD_HALF / 2)
				west_street = (float)(x + width / 2);
			if (x <= WORLD_HALF + WORLD_HALF / 2)
				east_street = (float)(x + width / 2);
			[self buildRoadAtX:x y:0 width:width depth:WORLD_SIZE];
		}
	}
        //We kept track of the positions of streets that will outline the high-detail hot zone in the middle of the world.
        //Save this in a bounding box so that later we can have the camera fly around without clipping through buildings.
    return bboxWithCorners(glVector(west_street, 0.0f, north_street),
                           glVector(east_street, 0.0f, south_street));
}

-(void) addSmallBuildings
{
    auto highType = ^{ return COIN_FLIP() ? BUILDING_TOWER : BUILDING_BLOCKY; };
        //now blanket the rest of the world with lesser buildings
	for (int x = 0; x < WORLD_SIZE; x ++)
    {
		for (int y = 0; y < WORLD_SIZE; y ++)
        {
			if (_world[CLAMP (x,0,WORLD_SIZE)][CLAMP (y,0,WORLD_SIZE)])
				continue;
            
			GLuint width = 12 + RandomIntR(20), depth = 12 + RandomIntR(20), height = std::min(width, depth);
			if (x < 30 || y < 30 || x > WORLD_SIZE - 30 || y > WORLD_SIZE - 30)
				height = RandomIntR(15) + 20;
			else if (x < WORLD_HALF / 2)
				height /= 2;
            
			while (width > 8 && depth > 8)
            {
                plot p = makePlot(x, y, width, depth);
				if (! [self claimed:p])
                {
					[self claimPlot:p value:CLAIM_BUILDING];
					GLrgba building_color = [self lightColorAtIndex:RandomInt()];
                        //if we're out of the hot zone, use simple buildings
					if (x < self.hotZone.min.x || x > self.hotZone.max.x || y < self.hotZone.min.z || y > self.hotZone.max.z)
                    {
						height = 5 + RandomIntR(height) + RandomIntR(height);
                        [Building buildingWithType:BUILDING_SIMPLE x:x + 1 y:y + 1 height:height width:width - 2 depth:depth - 2 seed:RandomInt() color:building_color world:self];
					}
                    else
                    { //use fancy buildings.
						height = 15 + RandomIntR(15);
						width -=2;
						depth -=2;
                        [Building buildingWithType:highType() x:x + 1 y:y + 1 height:height width:width depth:depth seed:RandomInt() color:building_color world:self];
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

-(void) addBigBuildings
{
	//Scan over the center area of the map and place the big buildings 
	int attempts = 0;
	while (_counts.skyscraper < 50 && attempts < 350) {
		int sx = (WORLD_HALF / 2) + (RandomLong() % WORLD_HALF);
		int sy = (WORLD_HALF / 2) + (RandomLong() % WORLD_HALF);
		if (! [self claimed:makePlot(sx, sy, 1,1)]) {
			[self doBuildingWithPlot:[self findPlotAtX:sx z:sy]];
			_counts.skyscraper++;
		}
		attempts++;
	}
}


/*-----------------------------------------------------------------------------
 This will return a random color which is suitible for light sources, taken
 from a narrow group of hues. (Yellows, oranges, blues.)
 -----------------------------------------------------------------------------*/

-(GLrgba) lightColorAtIndex:(GLuint) index
{
	index %= LIGHT_COLOR_COUNT;
	return glRgbaFromHsl (light_colors[index].hue, light_colors[index].sat, light_colors[index].lum);	
}


-(char)cellAtRow:(int) x column:(int) y
{
	return _world[CLAMP(x, 0, WORLD_SIZE - 1)][CLAMP(y, 0, WORLD_SIZE - 1)];	
}

-(GLrgba) bloomColor { return _bloomColor;  }
-(GLuint) logoIndex  { return _logoIndex++; }
-(GLbbox) hotZone    { return _hotZone;     }

-(void) term
{
}

-(void) reset
{
	//If we're already fading out, then this is the developer hammering on the "rebuild" button.  Let's hurry things up for the nice person...
	if (_fade == FADE_OUT)
		[self fullReset];
    
	//If reset is called but the world isn't ready, then don't bother fading out. The program probably just started.
	_fade = FADE_OUT;
	_fadeStart = GetTickCount();
}


-(void) fullReset
{
        //Re-init Random to make the same city each time. Helpful when running tests.
//    RandomInit (6);
	_resetNeeded = false;
	_logoIndex = _sceneBegin = 0;
    [self.entities clear];
	[self.lights clear];
	[self.cars clear];
	[self.textures reset];
	
        //Pick a tint for the bloom
	_bloomColor = get_light_color(0.5f + float(RandomLongR(10)) / 20.0f, 0.75f);
	memset(_world, 0, WORLD_SIZE * WORLD_SIZE);
    _counts.reset();
    
        // Build a road network and garnish it with streetlights.
    _hotZone = [self buildRoads];
    [self buildStreetlights];
        // Add large, detailed buildings near the center of the map, and smaller blurry buildings further away from the camera.
    [self addBigBuildings];
    [self addSmallBuildings];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) render
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

-(float) fadeCurrent  { return _fadeCurrent; }
-(GLulong) sceneBegin { return _sceneBegin; }

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

// How GLlong since this current iteration of the city went on display,
-(GLulong) sceneElapsed
{
	GLulong elapsed = (!self.entities.ready || !self.sceneBegin)
                      ? 1 : GetTickCount () - self.sceneBegin;
	return std::max(elapsed, 1ul);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) update
{	
	GLulong now = GetTickCount();
	if (_resetNeeded) {
		[self fullReset]; //Now we've faded out the scene, rebuild it
	}
	if (_fade != FADE_IDLE) {
		if (_fade == FADE_WAIT && self.textures.ready && self.entities.ready) {
			_fade = FADE_IN;
			_fadeStart = now;
			_fadeCurrent = 1.0f;
		}    
		GLulong fade_delta = now - _fadeStart;
		//See if we're done fading in or out
		if (fade_delta > FADE_TIME && _fade != FADE_WAIT) {
			if (_fade == FADE_OUT) {
				_resetNeeded = YES;
				_fade = FADE_WAIT;
				_fadeCurrent = 1.0f;
			} else {
				_fade = FADE_IDLE;
				_fadeCurrent = 0.0f;
				_startTime = time (NULL);
				_sceneBegin = GetTickCount ();
			}
		} else {
			_fadeCurrent = (float)fade_delta / FADE_TIME;
			if (_fade == FADE_IN)
				_fadeCurrent = 1.0f - _fadeCurrent;
			if (_fade == FADE_WAIT)
				_fadeCurrent = 1.0f;
		}
		if (! self.textures.ready)
			_fadeCurrent = 1.0f;
	} 
	if (_fade == FADE_IDLE && ! self.textures.ready) {
		_fade = FADE_IN;
		_fadeStart = now;
	}
	if (_fade == FADE_IDLE && _sceneElapsed > RESET_INTERVAL)
		[self reset];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(id) init 
{
    self = [super init];
    if(self) {
        _lastUpdate = GetTickCount ();
        _fade = FADE_IDLE;
        _logoIndex = 0;
        _fadeStart = 0;
        _startTime = 0;
        
        _cars     = [[Cars     alloc] initWithWorld:self];
        _lights   = [[Lights   alloc] initWithWorld:self];
        _entities = [[Entities alloc] initWithWorld:self];
        _sky      = [[Sky      alloc] initWithWorld:self];
        _textures = [[Textures alloc] initWithWorld:self];

        [self reset];
        _fade = FADE_OUT;
        _fadeStart = 0;
    }
    return self;
}

@end


int MakePrimitive::nestCount = 0;
int MakeDisplayList::nestCount = 0;

MakePrimitive::MakePrimitive(GLenum type)
{
	assert(nestCount == 0);
	pwBegin(type);
	++nestCount;
}

MakePrimitive::~MakePrimitive()
{
	assert(nestCount == 1);
	pwEnd();
	--nestCount;
}

MakeDisplayList::MakeDisplayList(GLint name, GLenum mode, const char * location)
{
    if(nestCount != 0) NSLog(@"MakeDisplayList %s: Nest count is %d", location, nestCount);
    if(! glIsList(name)) NSLog(@"MakeDisplayList %s: name %d is not a list name", location, name);
//	assert(nestCount == 0);	assert(glIsList(name));
	pwNewList(name, mode);
	++nestCount;
}

MakeDisplayList::~MakeDisplayList()
{	
	assert(nestCount == 1);
	pwEndList();
	--nestCount;
}


PWMatrixStacker::PWMatrixStacker()
{
    pwPushMatrix();
}

PWMatrixStacker::~PWMatrixStacker()
{
    pwPopMatrix();
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

