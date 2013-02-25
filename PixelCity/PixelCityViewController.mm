//
//  PixelCityViewController.m
//  PixelCity
//
//  Created by Patrick Wallace on 24/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PixelCityViewController.h"
#import "BasicOpenGLView.h"
#import "GLCheck.h"
#import "win.h"
#import "ini.h"
#import "RenderAPI.h"
#import "Model.h"
#import "World.h"
#import "texture.h"

@interface PixelCityViewController ()

@end

static BOOL fDebugLog = NO;

void DebugLog(const char* str, ...)
{
    if(fDebugLog) {
        va_list args;
        va_start(args, str);
        
        char buffer[512];
        memset(buffer, 0, 512);
        
        @try {        vsprintf(buffer, str, args);    }
        @finally {    va_end(args);                   }
        
        NSLog(@"%@\n", [NSString stringWithUTF8String:buffer]);
    }
}


@implementation PixelCityViewController

-(void)setView:(NSView *)view
{
    [super setView:view];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initApp];
    }
    
    return self;
}


-(void)awakeFromNib
{
    [self initApp];
}

-(void) saveSettings
{
	IniIntSet ("ShowFPS", fFPS ? 1 : 0);
	IniIntSet ("ShowFog", fFog ? 1 : 0);
	IniIntSet ("Letterbox", fLetterbox ? 1 : 0);
	IniIntSet ("Wireframe", fWireframe ? 1 : 0);
	IniIntSet ("Flat", fFlat ? 1 : 0);
	IniIntSet ("Effect", effect);
}

static void loadAndInit(NSMenuItem *item, BOOL *flag, const char *settingName, void (*fn)(bool))
{
    (*flag) = IniInt(settingName) != 0;
    [item setState:(*flag) ? NSOnState : NSOffState];
    fn(*flag);
}

-(void) initApp
{
        //load in our settings
    loadAndInit(letterboxToggleMenuItem, &fLetterbox, "Letterbox", RenderSetLetterbox);
    loadAndInit(wireframeToggleMenuItem, &fWireframe, "Wireframe", RenderSetWireframe);
    loadAndInit(fogToggleMenuItem      , &fFog      , "ShowFog"  , RenderSetFog);
    loadAndInit(flatToggleMenuItem     , &fFlat     , "Flat"     , RenderSetFlat);
    loadAndInit(FPSToggleMenuItem      , &fFPS      , "ShowFPS"  , RenderSetFPS);
    effect     = (EffectType)IniInt("Effect");
    RenderSetEffect(effect);
    
    fDebugLog  = fHelp = fNormalize = NO;
    fAnimate = YES;
    RenderSetHelpMode(fHelp);
    RenderSetNormalized(fNormalize);

        // start animation timer
	timer = [NSTimer timerWithTimeInterval:(1.0f / 60.0f) target:self selector:@selector(animationTick:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize
    
    ((BasicOpenGLView*)self.view).animating = fAnimate;
}

-(void) animationTick:(NSTimer*)timer
{
    [(BasicOpenGLView*)self.view animationTick];
}

#pragma mark - IB Actions

    // Dump logs and debug info to the console.
-(IBAction) info: (id) sender
{
    EntityDump();
}


static void toggleFlag(NSMenuItem *menuItem, void(^pbl)(bool), BOOL *pFlag)
{
	*pFlag = ! *pFlag;
	[menuItem setState:(*pFlag) ? NSOnState : NSOffState];
	if(pbl)
        pbl(*pFlag);
}

-(IBAction) animate:(id) sender
{
    toggleFlag(animateMenuItem, ^(bool b) { ((BasicOpenGLView*)self.view).animating = b; }, &fAnimate);
}

-(IBAction)toggleWireframe:(id)sender
{
    toggleFlag(wireframeToggleMenuItem, ^(bool b) { RenderSetWireframe(b); }, &fWireframe);
}

-(IBAction)nextEffect:(id)sender
{
    effect = EffectType((effect + 1) % EFFECT_COUNT);
	RenderSetEffect(effect);
}

-(IBAction) toggleLetterbox: (id) sender
{
    toggleFlag(letterboxToggleMenuItem, ^(bool b) { RenderSetLetterbox(b); }, &fLetterbox);
        // PAW: I think I'm supposed to change the window size to match the letterbox size here.
	NSSize size = [self.view bounds].size;
	AppResize(size.width, size.height);
}

-(IBAction) toggleFPS:(id) sender
{
    toggleFlag(FPSToggleMenuItem, ^(bool b) {  RenderSetFPS(b); }, &fFPS);
}

-(IBAction) toggleFog:(id) sender
{
    toggleFlag(fogToggleMenuItem, ^(bool b) { RenderSetFog(b); }, &fFog);
}

-(IBAction) toggleFlat:(id) sender
{
    toggleFlag(flatToggleMenuItem, ^(bool b) { RenderSetFlat(b); }, &fFlat);
}

-(IBAction)toggleDebugLog:(id)sender
{
    toggleFlag(debugLogToggleMenuItem, nil, &fDebugLog);
}

-(IBAction) toggleHelp:(id) sender
{
    toggleFlag(helpToggleMenuItem, ^(bool b) { RenderSetHelpMode(b); }, &fHelp);
}

-(IBAction)toggleNormalized:(id)sender
{
    toggleFlag(normalizeToggleMenuItem, ^(bool b) { RenderSetNormalized(b); }, &fNormalize);
}

-(void)resetWorld:(id)sender
{
    [((BasicOpenGLView*)self.view).world reset];
}

#pragma mark - NSWindow delegate

-(void)windowWillClose:(NSNotification *)notification
{
    RenderTerminate();  // Stop any OpenGL renders and wait for the window to be closed.
    [self saveSettings];
}

#pragma mark - NSApplication delegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

@end
