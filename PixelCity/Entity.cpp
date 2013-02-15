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

struct entity
{
  CEntity*            object;
};


struct cell
{
  unsigned        list_textured;
  unsigned        list_flat;
  unsigned        list_flat_wireframe;
  unsigned        list_alpha;
  GLvector        pos;
};

static cell           cell_list[GRID_SIZE][GRID_SIZE];
static int            entity_count = 0;
static entity*        entity_list = NULL;
static bool           sorted = false;
static bool           compiled = false;
static int            polycount = 0;
static int            compile_x = 0;
static int            compile_y = 0;
static int            compile_count = 0;
static unsigned long  compile_end = 0;

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

static int do_compare (const void *arg1, const void *arg2 )
{

  struct entity*  e1 = (struct entity*)arg1;
  struct entity*  e2 = (struct entity*)arg2;

  if (e1->object->Alpha () && !e2->object->Alpha ())
    return 1;
  if (!e1->object->Alpha () && e2->object->Alpha ())
    return -1;
  if (e1->object->Texture () > e2->object->Texture ())
    return 1;
  else if (e1->object->Texture () < e2->object->Texture ())
    return -1;
  return 0;

}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void add (CEntity* b)
{

  entity_list = (entity*)realloc(entity_list, sizeof (entity) * (entity_count + 1));
  entity_list[entity_count].object = b;
  entity_count++;
  polycount = 0;

}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

static void do_compile ()
{
  int       i, x, y;
  if (compiled)
    return;

	glReportError("do_compile BEGIN");
  x = compile_x;
  y = compile_y;
  
  //Changing textures is pretty expensive, and thus sorting the entites so that they are grouped by texture used can really improve framerate.
  //qsort (entity_list, entity_count, sizeof (struct entity), do_compare);
  //sorted = true;
  
	//Now group entites on the grid 
	//make a list for the textured objects in this region
	if (!cell_list[x][y].list_textured)
		cell_list[x][y].list_textured = glGenLists(1);
	{
    	MakeDisplayList mdl(cell_list[x][y].list_textured, GL_COMPILE);
		cell_list[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
		for (i = 0; i < entity_count; i++)
        {
			GLvector pos = entity_list[i].object->Center ();
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && !entity_list[i].object->Alpha ())
            {
				pwBindTexture(GL_TEXTURE_2D, entity_list[i].object->Texture ());
				entity_list[i].object->Render ();
			}
		}
	}
	glReportError("do_compile textured entities");
	
	//Make a list of flat-color stuff (A/C units, ledges, roofs, etc.)
	if (!cell_list[x][y].list_flat)
		cell_list[x][y].list_flat = glGenLists(1);
	{
        MakeDisplayList mdl(cell_list[x][y].list_flat, GL_COMPILE);
		pwEnable (GL_CULL_FACE);
		cell_list[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
		for (i = 0; i < entity_count; i++)
        {
			GLvector pos = entity_list[i].object->Center ();
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && !entity_list[i].object->Alpha ())
				entity_list[i].object->RenderFlat (false);
		}
	}
	glReportError("do_compile flat entities");
	
	//Now a list of flat-colored stuff that will be wireframe friendly
	if (!cell_list[x][y].list_flat_wireframe)
		cell_list[x][y].list_flat_wireframe = glGenLists(1);
	{
        MakeDisplayList mdl(cell_list[x][y].list_flat_wireframe, GL_COMPILE);
		pwEnable (GL_CULL_FACE);
		cell_list[x][y].pos = glVector (GRID_TO_WORLD(x), 0.0f, (float)y * GRID_RESOLUTION);
		for (i = 0; i < entity_count; i++)
        {
			GLvector pos = entity_list[i].object->Center ();
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && !entity_list[i].object->Alpha ())
				entity_list[i].object->RenderFlat (true);
		}
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
		for (i = 0; i < entity_count; i++)
        {
			GLvector pos = entity_list[i].object->Center ();
			if (WORLD_TO_GRID(pos.x) == x && WORLD_TO_GRID(pos.z) == y && entity_list[i].object->Alpha ())
            {
				pwBindTexture(GL_TEXTURE_2D, entity_list[i].object->Texture ());
				entity_list[i].object->Render ();
			}
		}
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

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

bool EntityReady ()
{

  return compiled;

}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

float EntityProgress ()
{

  return (float)compile_count / (GRID_SIZE * GRID_SIZE);

}


/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void EntityUpdate ()
{
  if (!TextureReady ()) {
    sorted = false;
    return;
  }

  if (!sorted) {
    qsort (entity_list, entity_count, sizeof (struct entity), do_compare);
    sorted = true;
  }

  //We want to do several cells at once. Enough to get things done, but
  //not so many that the program is unresponsive.
  if (LOADING_SCREEN) {  //If we're using a loading screen, we want to build as fast as possible
    unsigned long stop_time = GetTickCount () + 100;
    while (!compiled && GetTickCount () < stop_time)
      do_compile ();
  } else //Take it slow
    do_compile ();
}

/*------------------------------------------------------------------------------------------------------------------------------------------------------*/

void EntityDump(void)
{
    std::clog << "BEGIN ENTITY DUMP" << std::endl;
    for(int i = 0; i < entity_count; ++i)
        std::clog << "Entity " << i << " = " << *(entity_list[i].object) << std::endl;
    std::clog << "END ENTITY_DUMP" << std::endl;
}

/*------------------------------------------------------------------------------------------------------------------------------------------------------*/



void EntityRender (bool showFlat)
{
	glReportError("EntityRender: Begin");
	
	//Draw all textured objects
	int       polymode[2];
	glGetIntegerv (GL_POLYGON_MODE, &polymode[0]);
	bool wireframe = polymode[0] != GL_FILL;
	if (showFlat)
		pwDisable (GL_TEXTURE_2D);

// PAW: I think this is a duplicate of the code in RenderUpdate
//  long elapsed = 0;
//	if (!LOADING_SCREEN && wireframe) {     //If we're not using a loading screen, make the wireframe fade out via fog
//		elapsed = 6000 - WorldSceneElapsed ();
//		if (elapsed >= 0 && elapsed <= 6000)
//			RenderFogFX (float(elapsed) / 6000.0f);
//		else
//			return;
//	}
	
    for (int x = 0; x < GRID_SIZE; x++)
		for (int y = 0; y < GRID_SIZE; y++)
			if( Visible(x,y) && (cell_list[x][y].list_textured > 0) )
                pwCallList (cell_list[x][y].list_textured);

	glReportError("EntityRender: After glCallList 1");
	
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
		
    glReportError("EntityRender: After glCallList 2");
    
        //draw all alpha-blended objects
    pwBindTexture(GL_TEXTURE_2D, 0);
    pwColor3f(0.0f, 0.0f, 0.0f);
    pwEnable (GL_BLEND);
    for (int x = 0; x < GRID_SIZE; x++)
        for (int y = 0; y < GRID_SIZE; y++)
            if( Visible(x, y) && (cell_list[x][y].list_alpha > 0) )
                pwCallList(cell_list[x][y].list_alpha);
    
    glReportError("EntityRender: End");
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void EntityClear ()
{
	glReportError("EntityClear BEGIN");
	for (int i = 0; i < entity_count; i++) {
		delete entity_list[i].object;
	}
	if (entity_list)
		free (entity_list);
	entity_list = NULL;
	entity_count = compile_x = compile_y = compile_count = 0;
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

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

size_t EntityCount ()
{
  return entity_count;
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void EntityInit (void)
{
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

int EntityPolyCount (void)
{
  if (!sorted)
    return 0;
  if (polycount)
    return polycount;
  for (int i = 0; i < entity_count; i++) 
    polycount += entity_list[i].object->PolyCount ();
  return polycount;
}


/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

CEntity::CEntity (void)
{

  add (this);

}

void CEntity::Render (void)
{
}

void CEntity::RenderFlat (bool wireframe)
{
}

void CEntity::Update (void)
{
}

std::ostream &CEntity::operator<<(std::ostream &os) const
{
    return os << "[ENTITY CENTER=" << _center << "]";
}



