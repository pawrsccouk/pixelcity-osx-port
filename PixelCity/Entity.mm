/*-----------------------------------------------------------------------------

  Entity.cpp

  Copyright (c) 2005 Shamus Young
  All Rights Reserved

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

struct cell
{
  unsigned        list_textured;
  unsigned        list_flat;
  unsigned        list_flat_wireframe;
  unsigned        list_alpha;
  GLvector        pos;
};

static cell           cell_list[GRID_SIZE][GRID_SIZE];
//std::vector<CEntity *> entity_vec;
static NSMutableArray *allEntities = [NSMutableArray array];
static bool           sorted = false, compiled = false;
static int            polycount = 0, compile_x = 0, compile_y = 0, compile_count = 0;
static GLulong  compile_end = 0;


/*
static bool comparator(const CEntity *e1, const CEntity *e2)
{
    if (!e1->Alpha () &&  e2->Alpha()) return true;
    if ( e1->Alpha()  && !e2->Alpha()) return false;
    return (e1->Texture() < e2->Texture());
}
*/



static void do_compile ()
{
    if (compiled)
        return;

	glReportError("do_compile BEGIN");

	//Now group entites on the grid 
	//make a list for the textured objects in this region
    int x = compile_x, y = compile_y;
	if (!cell_list[x][y].list_textured)
		cell_list[x][y].list_textured = glGenLists(1);
	{
    	MakeDisplayList mdl(cell_list[x][y].list_textured, GL_COMPILE);
		cell_list[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
        for(Entity *ent in allEntities) {
			GLvector pos = ent.center;
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && !ent.alpha) {
				pwBindTexture(GL_TEXTURE_2D, ent.texture);
				[ent Render];
			}
		};
	}
	glReportError("do_compile textured entities");
	
	//Make a list of flat-color stuff (A/C units, ledges, roofs, etc.)
	if (!cell_list[x][y].list_flat)
		cell_list[x][y].list_flat = glGenLists(1);
    
	{
        MakeDisplayList mdl(cell_list[x][y].list_flat, GL_COMPILE);
		pwEnable (GL_CULL_FACE);
		cell_list[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
        for(Entity *ent in allEntities) {
			GLvector pos = ent.center;
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && !ent.alpha)
				[ent RenderFlat:NO];
		};
	}
	glReportError("do_compile flat entities");
	
	//Now a list of flat-colored stuff that will be wireframe friendly
	if (!cell_list[x][y].list_flat_wireframe)
		cell_list[x][y].list_flat_wireframe = glGenLists(1);
	{
        MakeDisplayList mdl(cell_list[x][y].list_flat_wireframe, GL_COMPILE);
		pwEnable (GL_CULL_FACE);
		cell_list[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
        for(Entity *ent in allEntities) {
			GLvector pos = ent.center;
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && !ent.alpha)
				[ent RenderFlat:YES];
		};
	}
	glReportError("do_compile Flat wireframeable entities");
	
	//Now a list of stuff to be alpha-blended, and thus rendered last
	if (!cell_list[x][y].list_alpha)
		cell_list[x][y].list_alpha = glGenLists(1);
    
	{
        MakeDisplayList mdl(cell_list[x][y].list_alpha, GL_COMPILE);
		cell_list[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
		pwDepthMask (GL_FALSE);
		pwEnable (GL_BLEND);
		pwDisable (GL_CULL_FACE);
        for(Entity *ent in allEntities) {
			GLvector pos = ent.center;
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && ent.alpha)
            {
				pwBindTexture(GL_TEXTURE_2D, ent.texture);
				[ent Render];
			}
		};
		pwDepthMask (GL_TRUE);
	}	
	glReportError("do_compile Alpha-blended entities");
	

  //now walk the grid
  compile_x++;
  if (compile_x == GRID_SIZE) {
    compile_x = 0;
    compile_y++;
    if (compile_y == GRID_SIZE)
      compiled = true;
    compile_end = GetTickCount ();
  } 
  compile_count++;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

bool EntityReady ()
{
  return compiled;
}


float EntityProgress ()
{
  return (float)compile_count / (GRID_SIZE * GRID_SIZE);
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


void EntityUpdate ()
{
    if (!TextureReady ()) {
        sorted = false;
        return;
    }
    
        //Changing textures is pretty expensive, and thus sorting the entites so that they are grouped by texture used can really improve framerate.
    if (!sorted) {
        [allEntities sortUsingComparator:^NSComparisonResult(Entity *e1, Entity *e2) {
         if ( e1.alpha && !e2.alpha)    return NSOrderedAscending;
         if (!e1.alpha &&  e2.alpha)    return NSOrderedDescending;
         if ( e1.texture > e2.texture)  return NSOrderedAscending;
         if ( e1.texture < e2.texture)  return NSOrderedDescending;
         return NSOrderedSame;
         }];
        sorted = true;
    }

        //We want to do several cells at once. Enough to get things done, but not so many that the program is unresponsive.
    if (LOADING_SCREEN) {  //If we're using a loading screen, we want to build as fast as possible
        GLulong stop_time = GetTickCount () + 100;
        while (!compiled && GetTickCount () < stop_time)
            do_compile ();
    } else //Take it slow
        do_compile ();
}

/*------------------------------------------------------------------------------------------------------------------------------------------------------*/

void EntityDump(void)
{
//    std::clog << "BEGIN ENTITY DUMP" << std::endl;
//    size_t i = 0;
//    for(Entity *ent in allEntities) {
//        std::clog << "Entity " << i++ << " = " << *e << std::endl;
//    });
//    std::clog << "END ENTITY_DUMP" << std::endl;
}

/*------------------------------------------------------------------------------------------------------------------------------------------------------*/



void EntityRender (bool showFlat)
{
    //Draw all textured objects
	int       polymode[2];
	glGetIntegerv (GL_POLYGON_MODE, &polymode[0]);
	bool wireframe = polymode[0] != GL_FILL;
	if (showFlat)
		pwDisable (GL_TEXTURE_2D);
	
    for (int x = 0; x < GRID_SIZE; x++)
		for (int y = 0; y < GRID_SIZE; y++)
			if( Visible(x,y) && (cell_list[x][y].list_textured > 0) )
                pwCallList (cell_list[x][y].list_textured);

        //draw all flat colored objects
	pwBindTexture(GL_TEXTURE_2D, 0);
	pwColor3f (0, 0, 0);
	for (int x = 0; x < GRID_SIZE; x++) 
		for (int y = 0; y < GRID_SIZE; y++) 
			if (Visible (x, y)) {
				if (wireframe) {
					if(cell_list[x][y].list_flat_wireframe > 0) { pwCallList(cell_list[x][y].list_flat_wireframe); }
				} else {
					if(cell_list[x][y].list_flat           > 0) { pwCallList(cell_list[x][y].list_flat          ); }
				}
			}

        //draw all alpha-blended objects
    pwBindTexture(GL_TEXTURE_2D, 0);
    pwColor3f(0.0f, 0.0f, 0.0f);
    pwEnable (GL_BLEND);
    for (int x = 0; x < GRID_SIZE; x++)
        for (int y = 0; y < GRID_SIZE; y++)
            if( Visible(x, y) && (cell_list[x][y].list_alpha > 0) )
                pwCallList(cell_list[x][y].list_alpha);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void EntityClear ()
{
	glReportError("EntityClear BEGIN");
    [allEntities removeAllObjects];
	compile_x = compile_y = compile_count = 0;
	compiled = sorted = false;
	
	// PAW: Only generate the list once the names have been allocated with glGenList() otherwise OpenGL errors.
	for (int x = 0; x < GRID_SIZE; x++) {
		for (int y = 0; y < GRID_SIZE; y++) {
			cell* pcell = &(cell_list[x][y]);
			if(pcell->list_textured       > 0) { MakeDisplayList mdl(pcell->list_textured      , GL_COMPILE);  }
			if(pcell->list_alpha          > 0) { MakeDisplayList mdl(pcell->list_alpha         , GL_COMPILE);  }
			if(pcell->list_flat_wireframe > 0) { MakeDisplayList mdl(pcell->list_flat_wireframe, GL_COMPILE);  }
			if(pcell->list_flat           > 0) { MakeDisplayList mdl(pcell->list_flat          , GL_COMPILE);  }
		}
	}
	glReportError("EntityClear END");
}


size_t EntityCount ()
{
  return allEntities.count;
}


void EntityInit (void)
{
}


int EntityPolyCount (void)
{
    if (!sorted)    return 0;
    if (polycount)  return polycount;
    
    for(Entity *ent in allEntities)
        polycount += ent.polyCount;
    return polycount;
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

@implementation Entity
@synthesize center = _center;

-(id)init
{
    self = [super init];
    if(self) {
        [allEntities addObject:self];
        polycount = 0;
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



