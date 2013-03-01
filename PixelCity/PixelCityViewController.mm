//
//  PixelCityViewController.m
//  PixelCity
//
//  Created by Patrick Wallace on 24/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PixelCityViewController.h"
#import "FogSettingsWindowController.h"
#import "BasicOpenGLView.h"
#import "GLCheck.h"
#import "win.h"
#import "ini.h"
#import "Render.h"
#import "Model.h"
#import "World.h"
#import "texture.h"
#import "Fog.h"

@interface PixelCityViewController ()
{
        // Panels
    FogSettingsWindowController * _fogSettingsWindowController;
}
@property (nonatomic, readonly) BasicOpenGLView *glView;    // self.view with a cast.
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

-(BasicOpenGLView*) glView { return (BasicOpenGLView*)self.view; }


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
            // Set up the app once the model has been created, and OpenGL initialised.
        self.glView.setupCallback = ^{ [self setupApp]; };
    }
    
    return self;
}


-(void)awakeFromNib
{
        // Set up the app once the model has been created, and OpenGL initialised.
    self.glView.setupCallback = ^{ [self setupApp]; };
}

-(void) saveSettings
{
	IniIntSet (kShowFPS, fFPS ? 1 : 0);
	IniIntSet (kLetterbox, fLetterbox ? 1 : 0);
	IniIntSet (kWireframe, fWireframe ? 1 : 0);
	IniIntSet (kFlat, fFlat ? 1 : 0);
	IniIntSet (kEffect, effect);
}

static void loadAndInit(NSMenuItem *item, BOOL *flag, NSString *settingName, void (^fn)(BOOL))
{
    (*flag) = IniInt(settingName) != 0;
    [item setState:(*flag) ? NSOnState : NSOffState];
    fn(*flag);
}

-(void) setupApp
{
    Renderer *renderer = self.glView.world.renderer;
        //load in our settings
    loadAndInit(letterboxToggleMenuItem, &fLetterbox, kLetterbox, ^(BOOL b){ renderer.letterbox  = b; } );
    loadAndInit(wireframeToggleMenuItem, &fWireframe, kWireframe, ^(BOOL b){ renderer.wireframe  = b; } );
    loadAndInit(flatToggleMenuItem     , &fFlat     , kFlat     , ^(BOOL b){ renderer.flat = b; } );
    loadAndInit(FPSToggleMenuItem      , &fFPS      , kShowFPS  , ^(BOOL b){ renderer.fps  = b; } );
    
    fDebugLog = NO;
    renderer.helpMode   = fHelp      = NO;
    renderer.normalized = fNormalize = NO;
    renderer.effect     = effect     = EffectType(IniInt(kEffect));

        // start animation timer
	timer = [NSTimer timerWithTimeInterval:(1.0f / 60.0f) target:self selector:@selector(animationTick:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize
    
        // allow the fog settings controller to apply the saved fog settings to the app.
    if(! _fogSettingsWindowController) {
        _fogSettingsWindowController = [[FogSettingsWindowController alloc] initWithWindowNibName:@"FogSettingsPanel"];
    }
    _fogSettingsWindowController.fog = renderer.fog;
    [_fogSettingsWindowController setupApp];
    
    self.glView.animating = fAnimate = YES;
}

-(void) animationTick:(NSTimer*)timer
{
    [self.glView animationTick];
}

#pragma mark - IB Actions

    // Dump logs and debug info to the console.
-(IBAction) info: (id) sender
{
    NSLog(@"%@", self.glView.world.entities);
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
    toggleFlag(animateMenuItem, ^(bool b) { self.glView.animating = b; }, &fAnimate);
}

-(IBAction)toggleWireframe:(id)sender
{
    toggleFlag(wireframeToggleMenuItem, ^(bool b) { self.glView.world.renderer.wireframe = b; }, &fWireframe);
}

-(IBAction)nextEffect:(id)sender
{
    effect = EffectType((effect + 1) % EFFECT_COUNT);
	self.glView.world.renderer.effect = effect;
}

-(IBAction) toggleLetterbox: (id) sender
{
    toggleFlag(letterboxToggleMenuItem, ^(bool b) { self.glView.world.renderer.letterbox = b; }, &fLetterbox);
        // PAW: I think I'm supposed to change the window size to match the letterbox size here.
	NSSize size = [self.view bounds].size;
    [self.glView.world.renderer resize:size];
}

-(IBAction) toggleFPS:(id) sender
{
    toggleFlag(FPSToggleMenuItem, ^(bool b) {  self.glView.world.renderer.fps = b; }, &fFPS);
}

-(IBAction) toggleFlat:(id) sender
{
    toggleFlag(flatToggleMenuItem, ^(bool b) { self.glView.world.renderer.flat = b; }, &fFlat);
}

-(IBAction)toggleDebugLog:(id)sender
{
    toggleFlag(debugLogToggleMenuItem, nil, &fDebugLog);
}

-(IBAction) toggleHelp:(id) sender
{
    toggleFlag(helpToggleMenuItem, ^(bool b) { self.glView.world.renderer.helpMode = b; }, &fHelp);
}

-(IBAction)toggleNormalized:(id)sender
{
    toggleFlag(normalizeToggleMenuItem, ^(bool b) { self.glView.world.renderer.normalized = b; }, &fNormalize);
}

-(void)resetWorld:(id)sender
{
    [self.glView.world reset];
}

#pragma mark Fog inspector

static NSString* const fogMenuShowText = @"Show fog settings",  * const fogMenuHideText = @"Hide fog settings";

-(IBAction)showFogSettings:(id)sender
{
    fFog = ! fFog;
    fogSettingsMenuItem.title = fFog ? fogMenuHideText : fogMenuShowText;
    _fogSettingsWindowController.fog = self.glView.world.renderer.fog;
    [_fogSettingsWindowController showWindow:self];
}

#pragma mark - NSWindow delegate

-(void)windowWillClose:(NSNotification *)notification
{
    [self.glView.world term];  // Stop any OpenGL renders while we wait for the window to be closed.
    [self saveSettings];
}

#pragma mark - NSApplication delegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

@end
