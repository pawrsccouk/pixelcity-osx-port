/*-----------------------------------------------------------------------------

  Entity.cpp

  Copyright (c) 2005 Shamus Young.  All Rights Reserved
  Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
  Released under the GNU GPL v3. See file COPYING for details.

-------------------------------------------------------------------------------

  An entity is any renderable stationary object in the world.  This is an 
  abstract class.  This module gathers up the Entities, sorts them by 
  texture use and location, and then stores them in OpenGL render lists
  for faster rendering.    

-----------------------------------------------------------------------------*/

#import "Model.h"
#import "entity.h"
#import "render.h"
#import "texture.h"
#import "visible.h"
#import "win.h"
#import "World.h"
#import "assert.h"

struct Cell
{
  unsigned        list_textured;
  unsigned        list_flat;
  unsigned        list_flat_wireframe;
  unsigned        list_alpha;
  GLvector        pos;
};


@interface Entities ()
{
    Cell _cellList[GRID_SIZE][GRID_SIZE];
}
@end

@implementation Entities
@synthesize polyCount = _polyCount, ready = _compiled, world = _world;



-(void) do_compile
{
    if (_compiled)
        return;

	glReportError("do_compile BEGIN");

	//Now group entites on the grid 
	//make a list for the textured objects in this region
    int x = _compileX, y = _compileY;
	if (! _cellList[x][y].list_textured) {
		_cellList[x][y].list_textured = glGenLists(1);
    }
	
    pwNewList(_cellList[x][y].list_textured, GL_COMPILE);
    @try {
        _cellList[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
        for(Entity *ent in _allEntities) {
            GLvector pos = ent.center;
            if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && !ent.alpha) {
                pwBindTexture(GL_TEXTURE_2D, ent.texture);
                [ent Render];
            }
        }
    }
    @finally { pwEndList(); }
	glReportError("do_compile textured entities");
	
	//Make a list of flat-color stuff (A/C units, ledges, roofs, etc.)
	if (! _cellList[x][y].list_flat) {
		_cellList[x][y].list_flat = glGenLists(1);
    }
    
    pwNewList(_cellList[x][y].list_flat, GL_COMPILE);
	@try {
		pwEnable (GL_CULL_FACE);
		_cellList[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
        for(Entity *ent in _allEntities) {
			GLvector pos = ent.center;
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && !ent.alpha)
				[ent RenderFlat:NO];
		};
	}
    @finally { pwEndList(); }
	glReportError("do_compile flat entities");
	
    
	//Now a list of flat-colored stuff that will be wireframe friendly
	if (! _cellList[x][y].list_flat_wireframe) {
		_cellList[x][y].list_flat_wireframe = glGenLists(1);
    }
	
    pwNewList(_cellList[x][y].list_flat_wireframe, GL_COMPILE);
    @try {
		pwEnable (GL_CULL_FACE);
		_cellList[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
        for(Entity *ent in _allEntities) {
			GLvector pos = ent.center;
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && !ent.alpha)
				[ent RenderFlat:YES];
		};
	}
    @finally { pwEndList(); }
	glReportError("do_compile Flat wireframeable entities");
	
	//Now a list of stuff to be alpha-blended, and thus rendered last
	if (! _cellList[x][y].list_alpha) {
		_cellList[x][y].list_alpha = glGenLists(1);
    }
    
    pwNewList(_cellList[x][y].list_alpha, GL_COMPILE);
	@try {
		_cellList[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
		pwDepthMask (GL_FALSE);
		pwEnable (GL_BLEND);
		pwDisable (GL_CULL_FACE);
        for(Entity *ent in _allEntities) {
			GLvector pos = ent.center;
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && ent.alpha)
            {
				pwBindTexture(GL_TEXTURE_2D, ent.texture);
				[ent Render];
			}
		};
		pwDepthMask (GL_TRUE);
	}
    @finally { pwEndList(); }
	glReportError("do_compile Alpha-blended entities");
	

  //now walk the grid
    _compileX++;
    if (_compileX == GRID_SIZE) {
        _compileX = 0;
        _compileY++;
        if (_compileY == GRID_SIZE)
            _compiled = YES;

        _compileEnd = GetTickCount ();
    } 
    _compileCount++;
}



-(float) progress
{
  return (float)_compileCount / (GRID_SIZE * GRID_SIZE);
}




-(void) update
{
    if (! self.world.textures.ready) {
        _sorted = NO;
        return;
    }
    
        //Changing textures is pretty expensive, and thus sorting the entites so that they are grouped by texture used can really improve framerate.
    if (! _sorted) {
        [_allEntities sortUsingComparator:^NSComparisonResult(Entity *e1, Entity *e2) {
         if ( e1.alpha && !e2.alpha)    return NSOrderedAscending;
         if (!e1.alpha &&  e2.alpha)    return NSOrderedDescending;
         if ( e1.texture > e2.texture)  return NSOrderedAscending;
         if ( e1.texture < e2.texture)  return NSOrderedDescending;
         return NSOrderedSame;
         }];
        _sorted = true;
    }

        //We want to do several cells at once. Enough to get things done, but not so many that the program is unresponsive.
    if (LOADING_SCREEN) {  //If we're using a loading screen, we want to build as fast as possible
        GLulong stop_time = GetTickCount () + 100;
        while (! _compiled && GetTickCount () < stop_time)
            [self do_compile];
    } else //Take it slow
        [self do_compile];
}

/*------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(NSString *) description
{
    return [NSString stringWithFormat:@"Entities %p sorted=%d, compiled=%d, %d polys", self, _sorted, self.ready, self.polyCount];
}

/*------------------------------------------------------------------------------------------------------------------------------------------------------*/



-(void) render:(BOOL) showFlat
{
        //Draw all textured objects
    VisibilityGrid *visibilityGrid = self.world.visibilityGrid;
    auto isWireframe = ^{ int polymode[2];  glGetIntegerv (GL_POLYGON_MODE, &polymode[0]); return polymode[0] != GL_FILL; };
	
    if (showFlat) {
		pwDisable (GL_TEXTURE_2D);
	}
    for (int x = 0; x < GRID_SIZE; x++) {
		for (int z = 0; z < GRID_SIZE; z++) {
			if( [visibilityGrid visibleAtX:x Z:z] && (_cellList[x][z].list_textured > 0) ) {
                pwCallList (_cellList[x][z].list_textured);
            }
        }
    }

        //draw all flat colored objects
	pwBindTexture(GL_TEXTURE_2D, 0);
	pwColor3f (0, 0, 0);
    bool wireframe = isWireframe();
	for (int x = 0; x < GRID_SIZE; x++) {
		for (int z = 0; z < GRID_SIZE; z++) {
			if ([visibilityGrid visibleAtX:x Z:z]) {
				if (wireframe) {
					if(_cellList[x][z].list_flat_wireframe > 0) {
                        pwCallList(_cellList[x][z].list_flat_wireframe);
                    }
				} else {
					if(_cellList[x][z].list_flat > 0) {
                        pwCallList(_cellList[x][z].list_flat);
                    }
				}
			}
        }
    }

        //draw all alpha-blended objects
    pwBindTexture(GL_TEXTURE_2D, 0);
    pwColor3f(0.0f, 0.0f, 0.0f);
    pwEnable (GL_BLEND);
    for (int x = 0; x < GRID_SIZE; x++) {
        for (int z = 0; z < GRID_SIZE; z++) {
            if( [visibilityGrid visibleAtX:x Z:z] && (_cellList[x][z].list_alpha > 0) ) {
                pwCallList(_cellList[x][z].list_alpha);
            }
        }
    }
}



-(void) clear
{
    [_allEntities removeAllObjects];
	_compileX = _compileY = _compileCount = 0;
	_compiled = _sorted = NO;
	
	// PAW: Only regenerate the list once the names have been allocated with glGenList() otherwise OpenGL errors.
	for (int x = 0; x < GRID_SIZE; x++) {
		for (int y = 0; y < GRID_SIZE; y++) {
			Cell* pcell = &(_cellList[x][y]);
			if(pcell->list_textured       > 0) { pwNewList(pcell->list_textured      , GL_COMPILE);  pwEndList();  }
			if(pcell->list_alpha          > 0) { pwNewList(pcell->list_alpha         , GL_COMPILE);  pwEndList();  }
			if(pcell->list_flat_wireframe > 0) { pwNewList(pcell->list_flat_wireframe, GL_COMPILE);  pwEndList();  }
			if(pcell->list_flat           > 0) { pwNewList(pcell->list_flat          , GL_COMPILE);  pwEndList();  }
		}
	}
}


-(void) term
{
    auto freeList = ^(GLuint *plist) { pwDeleteLists(*plist, 1); *plist = 0; };
	for (int x = 0; x < GRID_SIZE; x++) {
		for (int y = 0; y < GRID_SIZE; y++) {
			Cell* pcell = &(_cellList[x][y]);
			if(pcell->list_textured       > 0) { freeList(&pcell->list_textured      ); }
			if(pcell->list_alpha          > 0) { freeList(&pcell->list_alpha         ); }
			if(pcell->list_flat_wireframe > 0) { freeList(&pcell->list_flat_wireframe); }
			if(pcell->list_flat           > 0) { freeList(&pcell->list_flat          ); }
		}
	}
}

-(GLulong) count
{
  return _allEntities.count;
}


-(id) initWithWorld:(World*)world
{
    self = [super init];
    if(self) {
        _world = world;
        _allEntities = [NSMutableArray array];
    }
    return self;
}


-(GLint) polyCount
{
    if (! _sorted)   return 0;
    if (_polyCount)  return _polyCount;
    
    for(Entity *ent in _allEntities)
        _polyCount += ent.polyCount;
    return _polyCount;
}

-(void)addEntity:(Entity*) entity
{
    [_allEntities addObject:entity];
    _polyCount = 0;
}

@end


//----------------------------------------------------------------------------------------------------------------------------------
#pragma mark - Entity

@implementation Entity
@synthesize center = _center, world = _world;

-(id)init
{
    [NSException raise:@"Logic error" format:@"Don't use raw init, use initWithWorld or initWithParent instead"];
    return [super init];
}

-(id)initWithWorld:(World*) world
{
    self = [super init];
    if(self) {
        _world = world;
        [world.entities addEntity:self];
    }
    return self;
    
}


-(void) Render
{
}

-(void) RenderFlat:(BOOL) wirefame
{
}

-(void) Update
{
}

-(GLuint) texture { return 0; }
-(BOOL) alpha { return NO; }
-(GLulong) polyCount { return 0; }

@end



