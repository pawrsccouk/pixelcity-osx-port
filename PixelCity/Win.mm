/*-----------------------------------------------------------------------------

  Win.cpp

  2006 Shamus Young

-------------------------------------------------------------------------------

  Create the main window and make it go.

-----------------------------------------------------------------------------*/

static const float MOUSE_MOVEMENT = 0.5f;

#import "Model.h"

#import "camera.h"
#import "car.h"
#import "entity.h"
#import "ini.h"
#import "render.h"
#import "texture.h"
#import "win.h"
#import "world.h"
#import "visible.h"
#import "RenderAPI.h"
#import <sys/time.h>

/*
#pragma comment(lib, "opengl32.lib")
#pragma comment(lib, "winmm.lib")
#pragma comment(lib, "glu32.lib")
#if SCREENSAVER
#pragma comment(lib, "scrnsave.lib")
#endif	
*/

static bool lmb = false, rmb = false, mouse_forced = false, quit = false;

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/
/*
static void CenterCursor ()
{

  int             center_x;
  int             center_y;
  RECT            rect;

  SetCursor (NULL);
  mouse_forced = true;
  GetWindowRect (hwnd, &rect);
  center_x = rect.left + (rect.right - rect.left) / 2;
  center_y = rect.top + (rect.bottom - rect.top) / 2;
  SetCursorPos (center_x, center_y);

}
*/
/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/
/*
static void MoveCursor (int x, int y)
{

  int             center_x;
  int             center_y;
  RECT            rect;

  SetCursor (NULL);
  mouse_forced = true;
  GetWindowRect (hwnd, &rect);
  center_x = rect.left + x;
  center_y = rect.top + y;
  SetCursorPos (center_x, center_y);

}
*/

/*-----------------------------------------------------------------------------
                                    n o t e
-----------------------------------------------------------------------------*/
/*
void WinPopup (char* message, ...)
{
  va_list  		marker;
  const size_t BUFSIZE = 1024;
  char        buf[BUFSIZE];

  va_start (marker, message);
  vsprintf_s (buf, BUFSIZE, message, marker); 
  va_end (marker);
  MessageBox (NULL, buf, APP_TITLE, MB_ICONSTOP | MB_OK | MB_TASKMODAL);
}
*/
/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/
/*
int WinWidth (void)
{
  return width;
}
*/
/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/
/*
void WinMousePosition (int* x, int* y)
{
  *x = select_pos.x;
  *y = select_pos.y;
}
*/

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/
/*
int WinHeight (void)
{
  return height;
}
*/
/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/
/*
void WinTerm (void)
{
#if !SCREENAVER
  DestroyWindow (hwnd);
#endif
}
*/

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*
HWND WinHwnd (void)
{
  return hwnd;
}
*/

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void AppQuit ()
{
  quit = true;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void AppUpdate (int width, int height)
{
	DebugLog("AppUpdate");
	glReportError("AppUpdate begins");
    
	CameraUpdate ();
	glReportError("AppUpdate:After CameraUpdate");
    
	EntityUpdate ();
	glReportError("AppUpdate:After EntityUpdate");
    
	WorldUpdate  ();
	glReportError("AppUpdate:After WorldUpdate");
    
        //cleanup and restore the viewport after TextureUpdate()
	RenderResize (width, height); 
	glReportError("AppUpdate:After RenderResize");
    
	VisibleUpdate();
	glReportError("AppUpdate:After VisibleUpdate");
    
	CarUpdate    ();
	glReportError("AppUpdate:After CarUpdate");
    
	RenderUpdate (width, height);
	glReportError("AppUpdate:After RenderUpdate");
}

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void AppInit(int width, int height)
{
	DebugLog("AppInit");
  RandomInit (time (NULL));
  CameraInit ();
  RenderInit (width, height);
  TextureInit();
  WorldInit  ();
}


/*-----------------------------------------------------------------------------
                                W i n M a i n
-----------------------------------------------------------------------------*/

void AppTerm (void) 
{
	DebugLog("AppTerm");
    TextureTerm ();
    WorldTerm ();
    RenderTerminate();
}

void AppResize(int width, int height)
{
	RenderResize(width, height);
}

/*-----------------------------------------------------------------------------
                                W i n M a i n
-----------------------------------------------------------------------------*/
#if !SCREENSAVER

/*
int PASCAL WinMain (HINSTANCE instance_in, HINSTANCE previous_instance,
  LPSTR command_line, int show_style)
{
  MSG		  msg;
  instance = instance_in;
  WinInit();
  AppInit();
  while (!quit) {
		if (PeekMessage (&msg, NULL, 0, 0, PM_REMOVE))	{
			if (msg.message == WM_QUIT)	
				quit = true;
			else {
				TranslateMessage(&msg);			
				DispatchMessage(&msg);			
			}
    } else 
      AppUpdate();
  }
  AppTerm();
  return 0;
}
*/

#else
/*
BOOL WINAPI ScreenSaverConfigureDialog (HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam) { return FALSE; }
BOOL WINAPI RegisterDialogClasses(HANDLE hInst) { return TRUE; }
*/
#endif

/*
LONG WINAPI ScreenSaverProc(HWND hwnd_in,UINT message,WPARAM wparam,LPARAM lparam)
{

  RECT            r;
  int             key;
  float           delta_x, delta_y;
  POINT           p;

  // Handles screen saver messages
  switch(message)
  {
  case WM_SIZE:
    width = LOWORD(lparam);  // width of client area 
    height = HIWORD(lparam); // height of client area 
    if (wparam == SIZE_MAXIMIZED) {
      IniIntSet ("WindowMaximized", 1);
    } else {
      IniIntSet ("WindowWidth", width);
      IniIntSet ("WindowHeight", height);
      IniIntSet ("WindowMaximized", 0);
    }
    RenderResize ();
    break;
  case WM_KEYDOWN:
    key = (int) wparam; 
    if      (key == 'R')		WorldReset (); 
    else if (key == 'W')		RenderWireframeToggle ();
    else if (key == 'E')		RenderEffectCycle ();
    else if (key == 'L')		RenderLetterboxToggle ();
    else if (key == 'F')		RenderFPSToggle ();
    else if (key == 'G')		RenderFogToggle ();
    else if (key == 'T')		RenderFlatToggle ();
    else if (key == VK_F1)		RenderHelpToggle ();
    else if (key == VK_ESCAPE)  PostQuitMessage(0);	// PAW, was break;
    else if (!SCREENSAVER)   //Dev mode keys
	{ if (key == 'C')        CameraAutoToggle (); 
      if (key == 'B')        CameraNextBehavior ();
      if (key == VK_F5)      CameraReset ();
      if (key == VK_UP)      CameraMedial (1.0f);
      if (key == VK_DOWN)    CameraMedial (-1.0f);
      if (key == VK_LEFT)    CameraLateral (1.0f);
      if (key == VK_RIGHT)   CameraLateral (-1.0f);
      if (key == VK_PRIOR)   CameraVertical (1.0f);
      if (key == VK_NEXT)    CameraVertical (-1.0f);
      if (key == VK_F5)      CameraReset ();
      return 0;
    } 
	else
      break;
    return 0;
  case WM_MOVE:
    GetClientRect (hwnd, &r);
    height = r.bottom - r.top;
    width  = r.right  - r.left;
    IniIntSet ("WindowX"     , r.left);
    IniIntSet ("WindowY"     , r.top);
    IniIntSet ("WindowWidth" , width);
    IniIntSet ("WindowHeight", height);
    half_width  = width  / 2;
    half_height = height / 2;
    return 0;
  case WM_LBUTTONDOWN:
    lmb = true;
    SetCapture (hwnd);
    break;
  case WM_RBUTTONDOWN:
    rmb = true;
    SetCapture (hwnd);
    break;
  case WM_LBUTTONUP:
    lmb = false;
    if (!rmb)
	{  ReleaseCapture ();
       MoveCursor (select_pos.x, select_pos.y);
    }
    break;
  case WM_RBUTTONUP:
    rmb = false;
    if (!lmb) 
    { ReleaseCapture ();
      MoveCursor (select_pos.x, select_pos.y);
    }
    break;
  case WM_MOUSEMOVE:
    p.x = LOWORD(lparam);  // horizontal position of cursor 
    p.y = HIWORD(lparam);  // vertical position of cursor 
    if (p.x < 0 || p.x > width)
      break;
    if (p.y < 0 || p.y > height)
      break;
    if (!mouse_forced && !lmb && !rmb) 
    { select_pos = p; 
    }
    if (mouse_forced) {
      mouse_forced = false;
    } else if (rmb || lmb) {
      CenterCursor ();
      delta_x = (float)(mouse_pos.x - p.x) * MOUSE_MOVEMENT;
      delta_y = (float)(mouse_pos.y - p.y) * MOUSE_MOVEMENT;
      if (rmb && lmb) {
        GLvector    pos;
        CameraPan (delta_x);
        pos = CameraPosition ();
        pos.y += delta_y;
        CameraPositionSet (pos);
      } else if (rmb) {
        CameraPan (delta_x);
        CameraForward (delta_y);
      } else if (lmb) {
        GLvector    angle;
        angle = CameraAngle ();
        angle.y -= delta_x;
        angle.x -= delta_y;	// PAW, was +
        CameraAngleSet (angle);
      }
    }
    mouse_pos = p;
    break;
  case WM_CREATE:
    hwnd = hwnd_in;
    if (SCREENSAVER)
      AppInit ();
    SetTimer (hwnd, 1, 7, NULL); 
    return 0;
  case WM_TIMER:
    AppUpdate ();
    return 0;
  case WM_DESTROY:
    PostQuitMessage(0);
    return 0;
  }
#if SCREENSAVER
  return DefScreenSaverProc(hwnd_in,message,wparam,lparam);
#else
  return DefWindowProc (hwnd_in,message,wparam,lparam);   
#endif
}
*/

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/
/*
bool WinInit (void)
{

  WNDCLASSEX    wcex;
  int           x, y;
  int           style;
  bool          max;

	wcex.cbSize         = sizeof(WNDCLASSEX); 
	wcex.style			    = CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc	  = (WNDPROC)ScreenSaverProc;
	wcex.cbClsExtra		  = 0;
	wcex.cbWndExtra		  = 0;
	wcex.hInstance		  = instance;
	wcex.hIcon			    = NULL;
	wcex.hCursor		    = LoadCursor(NULL, IDC_ARROW);
	wcex.hbrBackground	= (HBRUSH)(COLOR_BTNFACE+1);
	wcex.lpszMenuName	  = NULL;
	wcex.lpszClassName	= APP_TITLE;
	wcex.hIconSm		    = NULL;
  if (!RegisterClassEx(&wcex)) {
    WinPopup ("Cannot create window class");
    return false;
  }
  x = IniInt ("WindowX");
  y = IniInt ("WindowY");
  style = WS_TILEDWINDOW;
  style |= WS_MAXIMIZE;
  width = IniInt ("WindowWidth");
  height = IniInt ("WindowHeight");
  width = CLAMP (width, 800, 2048);
  height = CLAMP (height, 600, 2048);
  half_width = width / 2;
  half_height = height / 2;
  max = IniInt ("WindowMaximized") == 1;
  if (!(hwnd = CreateWindowEx (0, APP_TITLE, APP_TITLE, style,
    CW_USEDEFAULT, CW_USEDEFAULT, width, height, NULL, NULL, instance, NULL))) {
    WinPopup ("Cannot create window");
    return false;
  }
  if (max) 
    ShowWindow (hwnd, SW_MAXIMIZE);
  else
    ShowWindow (hwnd, SW_SHOW);
  UpdateWindow (hwnd);
  return true;
}
*/

// PAW: Replacement for Windows function that returns time since computer was started in milliseconds.
// gettimeofday returns it in microseconds, so we need to convert the result.
unsigned long GetTickCount()
{
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return (((tv.tv_sec * 1000 * 1000) + tv.tv_usec) / 1000);
}
