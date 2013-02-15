/*-----------------------------------------------------------------------------

  Car.cpp

  2009 Shamus Young

-------------------------------------------------------------------------------

  This creates the little two-triangle cars and moves them around the map.

-----------------------------------------------------------------------------*/


#import "Model.h"
#import "car.h"
#import "building.h"
#import "mesh.h"
#import "render.h"
#import "texture.h"
#import "visible.h"
#import "win.h"
#import "World.h"
#import "camera.h"

static const int DEAD_ZONE = 200, STUCK_TIME = 230, UPDATE_INTERVAL = 50; //milliseconds
static const float MOVEMENT_SPEED = 0.61f,  CAR_SIZE = 3.0f;

class CCar
{
    GLvector m_position, m_drivePosition;
    bool            m_ready;
    bool            m_front;
    int             m_drive_angle;
    unsigned int    m_row, m_col;
    int             m_direction;
    int             m_change;
    int             m_stuck;
    float           m_speed;
    float           m_max_speed;
    CCar*           m_next;
    
friend void CarClear();
friend void CarRender();
friend void CarUpdate();

public:
    CCar();
    bool testPositionRow(int row, int col);
    void Render();
    void Update();
    void Park();

};



static GLvector direction[] = 
{
  GLvector( 0.0f, 0.0f, -1.0f),
  GLvector( 1.0f, 0.0f,  0.0f),
  GLvector( 0.0f, 0.0f,  1.0f),
  GLvector(-1.0f, 0.0f,  0.0f),
};

static const int dangles[] = { 0, 90, 180, 270 };
static GLvector2 angles[360];
static bool    angles_done;

std::vector<CCar*> all_cars;

static int     count;
static unsigned char carmap[WORLD_SIZE][WORLD_SIZE];
static unsigned long next_update;

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

int CarCount ()
{
  return count;
}

void CarAdd()
{
    all_cars.push_back(new CCar);
    count++;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CarClear ()
{
    std::for_each(all_cars.begin(), all_cars.end(), std::mem_fn(&CCar::Park));
    memset(carmap, 0, sizeof (carmap));
    count = 0;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CarRender ()
{
  if (!angles_done) {
    for (int i = 0 ;i < 360; i++) {
      angles[i].x = cosf ((float)i * DEGREES_TO_RADIANS) * CAR_SIZE;
      angles[i].y = sinf ((float)i * DEGREES_TO_RADIANS) * CAR_SIZE;
    }
  }
  pwDepthMask (GL_FALSE);
  pwEnable (GL_BLEND);
  pwDisable (GL_CULL_FACE);
  pwBlendFunc (GL_ONE, GL_ONE);
  pwBindTexture (GL_TEXTURE_2D, 0);
  pwBindTexture(GL_TEXTURE_2D, TextureId (TEXTURE_HEADLIGHT));
  std::for_each(all_cars.begin(), all_cars.end(), std::mem_fn(&CCar::Render));
  pwDepthMask (GL_TRUE);
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CarUpdate ()
{
    if (!TextureReady () || !EntityReady ())
        return;
    unsigned long now = GetTickCount ();
    if (next_update > now)
        return;
    next_update = now + UPDATE_INTERVAL;
    std::for_each(all_cars.begin(), all_cars.end(), std::mem_fn(&CCar::Update));
}




CCar::CCar()
{
    m_ready = false;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

bool CCar::testPositionRow(int row, int col)
{
        //test the given position and see if it's already occupied
  if (carmap[row][col])
    return false;
        //now make sure that the lane is going the right direction
  if (WorldCell(row, col) != WorldCell(m_row, m_col))
    return false;
  return true;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CCar::Park() { m_ready = false;}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CCar::Update()
{
        //If the car isn't ready, place it on the map and get it moving
    GLvector old_pos, camera = CameraPosition();
    if (!m_ready) {

            //if the car isn't ready, we need to place it somewhere on the map
        m_row = DEAD_ZONE + RandomIntR(WORLD_SIZE - DEAD_ZONE * 2);
        m_col = DEAD_ZONE + RandomIntR(WORLD_SIZE - DEAD_ZONE * 2);
            //if there is already a car here, forget it.
        if (carmap[m_row][m_col] > 0)
            return;
            //if this spot is not a road, forget it
        if (!(WorldCell (m_row, m_col) & CLAIM_ROAD))
            return;
        if (!Visible (glVector ((float)m_row, 0.0f, (float)m_col)))
            return;
        
            //good spot. place the car
        m_position = glVector ((float)m_row, 0.1f, (float)m_col);
        m_drivePosition = m_position;
        m_ready = true;
        
        if (WorldCell (m_row, m_col) & MAP_ROAD_NORTH)  m_direction = NORTH;
        if (WorldCell (m_row, m_col) & MAP_ROAD_EAST)   m_direction = EAST;
        if (WorldCell (m_row, m_col) & MAP_ROAD_SOUTH)  m_direction = SOUTH;
        if (WorldCell (m_row, m_col) & MAP_ROAD_WEST)   m_direction = WEST;
        
            m_drive_angle = dangles[m_direction];
            m_max_speed = (float)(4 + RandomLongR(6)) / 10.0f;
            m_speed = 0.0f;
            m_change = 3;
            m_stuck = 0;
            carmap[m_row][m_col]++;
    }
    
    
        //take the car off the map and move it
    carmap[m_row][m_col]--;
    old_pos = m_position;
    m_speed += m_max_speed * 0.05f;
    m_speed = MIN(m_speed, m_max_speed);
    m_position = m_position + (direction[m_direction] * MOVEMENT_SPEED * m_speed);
    
        //If the car has moved out of view, there's no need to keep simulating it.
        //if the car is far away, remove it.  We use manhattan units because buildings almost always block views of cars on the diagonal.
        //if the car gets too close to the edge of the map, take it out of play
    if((!Visible(glVector((float)m_row, 0.0f, (float)m_col)))
    || (fabs (camera.x - m_position.x) + fabs (camera.z - m_position.z) > RenderFogDistance())
    || (m_position.x < DEAD_ZONE || m_position.x > (WORLD_SIZE - DEAD_ZONE))
    || (m_position.z < DEAD_ZONE || m_position.z > (WORLD_SIZE - DEAD_ZONE))
    || (m_stuck >= STUCK_TIME) ) {
        m_ready = false;
        return;
    }
    
        //Check the new position and make sure its not in another car
    int new_row = (int)m_position.x, new_col = (int)m_position.z;
    if (new_row != m_row || new_col != m_col) {
            //see if the new position places us on top of another car
        if (carmap[new_row][new_col]) {
            m_position = old_pos;
            m_speed = 0.0f;
            m_stuck++;
        } else {
                //look at the new position and decide if we're heading towards or away from the camera
            m_row = new_row;
            m_col = new_col;
            m_change--;
            m_stuck = 0;
            if (m_direction == NORTH)
                m_front = camera.z < m_position.z;
            else if (m_direction == SOUTH)
                m_front = camera.z > m_position.z;
            else if (m_direction == EAST)
                m_front = camera.x > m_position.x;
            else
                m_front = camera.x < m_position.x;
        }
    }
    m_drivePosition = (m_drivePosition + m_position) / 2.0f;
        //place the car back on the map
    carmap[m_row][m_col]++;
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CCar::Render()
{
	if (!m_ready || !Visible (m_drivePosition))
		return;
    
	if (m_front)  glColor3f(1.0f, 1.0f, 0.8f);
	else          glColor3f(0.5f, 0.2f, 0.0f);
	
	GLvector pos = m_drivePosition;
	int angle = 360 - (int)MathAngle2 (m_position.x, m_position.z, pos.x, pos.z);
	angle %= 360;
	int turn = (int)MathAngleDifference ((float)m_drive_angle, (float)angle);
	m_drive_angle += SIGN (turn);
	pos = pos + glVector (0.5f, 0.0f, 0.5f);
		
	float top = m_front ? CAR_SIZE : 0.0f;
    glBegin(GL_QUADS);
        glTexCoord2f (0, 0);
        glVertex3f (pos.x + angles[angle].x, -CAR_SIZE, pos.z + angles[angle].y);
        glTexCoord2f (1, 0);
        glVertex3f (pos.x - angles[angle].x, -CAR_SIZE, pos.z - angles[angle].y);
        glTexCoord2f (1, 1);
        glVertex3f (pos.x - angles[angle].x,  top, pos.z - angles[angle].y);
        glTexCoord2f (0, 1);
        glVertex3f (pos.x + angles[angle].x,  top, pos.z +  angles[angle].y);
    
    glEnd();
}

