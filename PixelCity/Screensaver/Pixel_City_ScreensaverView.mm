//
//  Pixel_City_ScreensaverView.m
//  Pixel City Screensaver
//
//  Created by Patrick Wallace on 20/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//  Released under the GNU GPL v3. See the file COPYING for details.

#import "Pixel_City_ScreensaverView.h"
#import "Model.h"
#import "BasicOpenGLView.h"
#import "Render.h"
#import "World.h"
#import "Fog.h"
#import "Ini.h"

static  NSString * const moduleName = @"paw.PixelCity_Screensaver",
                 *kCycleEffects = @"CycleEffects", *kEffectCycleTime = @"EffectCycleTime", *kAnimationSpeed = @"AnimationSpeed";

@interface Pixel_City_ScreensaverView ()
{
    BasicOpenGLView *_glView;
    BOOL _fFog, _fFlat, _fWireframe, _fCycleEffects;
    NSInteger _effectCycleTime;
    EffectType _effect;
    int _animationSpeed;
}
@end

@implementation Pixel_City_ScreensaverView
@synthesize optionsPanel = _optionsPanel;

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self)
    {
        [self registerDefaultPreferences];
        
        _glView = [[BasicOpenGLView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        if(_glView)
        {
                // Defer a callback to load initial preferences when the objects have been created.
            __weak Pixel_City_ScreensaverView *myself = self;
            _glView.setupCallback = ^{ [myself loadPreferences]; };
            
            _glView.animating = NO;
            _animationSpeed   = 30;                 // for now, re-set from the preferences later.
            self.autoresizesSubviews = YES;         // Make sure we autoresize
            [self addSubview:_glView];              // We make it a subview of the screensaver view
            self.animationTimeInterval = 1/60.0;    // Then we set our animation loop timer
        }
        else
            NSLog(@"Error: OpenGL Screen Saver failed to initialize NSOpenGLView!");
    }
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
    _glView.animating = YES;
}

- (void)stopAnimation
{
    [super stopAnimation];
    _glView.animating = NO;
}

- (void)drawRect:(NSRect)rect
{
    NSLog(@"Screensaver view drawRect");
    [super drawRect:rect];
    [_glView drawRect:rect];
}

- (void)animateOneFrame
{
    [_glView animationTick];
}

- (BOOL)hasConfigureSheet
{
    return YES;
}


- (NSWindow*)configureSheet
{
    if (! self.optionsPanel) {
        [NSBundle loadNibNamed:@"optionsPanel" owner:self];
        NSAssert(self.optionsPanel, @"configureSheet: loaded nib but it didn't connect up the options panel.");
    }
    
    [self loadPreferences];
    return self.optionsPanel;
}


static void toggleFlag(BasicOpenGLView *glView, NSButton *checkBox, void(^pbl)(bool), BOOL *pFlag)
{
	*pFlag = checkBox.state == NSOnState;
	if(pbl) {
        pbl(*pFlag);
            // Update the view to display the new settings.
        glView.needsDisplay = YES;
        [glView drawRect:glView.bounds];
    }
}


- (IBAction)showFog:(id)sender
{
    toggleFlag(_glView, toggleFogBtn, ^(bool b) { _glView.world.renderer.fog.enable = b; }, &_fFog);
}

- (IBAction)showFlat:(id)sender
{
    toggleFlag(_glView, toggleFlatBtn, ^(bool b) { _glView.world.renderer.flat = b; }, &_fFlat);
}

- (IBAction)showWireframe:(id)sender
{
    toggleFlag(_glView, toggleWireframeBtn, ^(bool b) { _glView.world.renderer.wireframe = b; }, &_fWireframe);
}

- (IBAction)cycleEffects:(id)sender
{
    toggleFlag(_glView, toggleCycleEffectsBtn, ^(bool b) { _glView.world.renderer.wireframe = b; }, &_fCycleEffects);
    [effectCycleTimeField setEditable:_fCycleEffects];
}
    // Other controls.
- (IBAction)effectCycleTimeChanged:(NSNotification*)sender
{
    _effectCycleTime = effectCycleTimeField.stringValue.integerValue;
    if(_effectCycleTime < 0)
        _effectCycleTime = 0;
}

    // Tags on the effects menu button in Interface Builder
enum { tagNONE = 1, tagBLOOM, tagRADIAL_BLOOM, tagRAINBOW, tagGLASS };

- (IBAction)effectChanged:(id)sender
{
    NSAssert([sender isKindOfClass:NSPopUpButton.class], @"Sender %@ is not a popup button", sender);
    NSPopUpButton *button = sender;
    EffectType effType = EFFECT_NONE;
    switch (button.selectedItem.tag) {
        case tagNONE        : effType = EFFECT_NONE        ; break;
        case tagBLOOM       : effType = EFFECT_BLOOM       ; break;
        case tagRADIAL_BLOOM: effType = EFFECT_BLOOM_RADIAL; break;
        case tagRAINBOW     : effType = EFFECT_COLOR_CYCLE ; break;
        case tagGLASS       : effType = EFFECT_GLASS_CITY  ; break;
        default:
            NSLog(@"Unknown effect tag %ld from popup menu item %@ in button %@.", button.selectedItem.tag, button.selectedItem, button);
            break;
    }
    _glView.world.renderer.effect = _effect = effType;
    _glView.needsDisplay = YES;
    [_glView drawRect:_glView.bounds];
}

-(void) setAnimationSpeed:(NSInteger) fps
{
    animationTimeLabel.stringValue = [NSString stringWithFormat:@"%ld fps", fps];
    self.animationTimeInterval = 1.0f / float(fps);
    _animationSpeed = (int)fps;
}

-(IBAction)animationTimeChanged:(id)sender
{
    NSAssert([sender isKindOfClass:NSSlider.class], @"Sender %@ is not a slider", sender);
    NSSlider *slider = sender;
    [self setAnimationSpeed:slider.intValue];
}

- (void) registerDefaultPreferences
{
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:moduleName];
    
        // Register our default values
    [defaults registerDefaults:@{
             kShowFog         : @"YES",
             kFogMode         : @0x2601, // GL_LINEAR
             kFogStartDistance: @0,
             kFogEndDistance  : @512,
             kFogColor        : @"0.2 0.2 0.2 1.0",
             kFlat            : @"NO" ,
             kWireframe       : @"NO" ,
             kCycleEffects    : @"NO" ,
             kEffect          : @0    ,
             kEffectCycleTime : @30   ,
             kAnimationSpeed  : @30
     }];
}

static NSColor *colorFromString(NSString *colorString)
{
    NSScanner *scanner = [NSScanner scannerWithString:colorString];
    BOOL ok = YES;
    float red = 1.0f, green = 1.0f, blue = 1.0f, alpha = 1.0f;
    ok = ok && [scanner scanFloat:&red  ];
    ok = ok && [scanner scanFloat:&green];
    ok = ok && [scanner scanFloat:&blue ];
    ok = ok && [scanner scanFloat:&alpha];
    NSCAssert(ok, @"Color format string [%@] should be 4 floating-point values", colorString);
    return [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
}

- (void) loadPreferences
{
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:moduleName];
    _fWireframe     = [defaults boolForKey:kWireframe   ];
    _fFlat          = [defaults boolForKey:kFlat        ];
    _fFog           = [defaults boolForKey:kShowFog     ];
    _fCycleEffects  = [defaults boolForKey:kCycleEffects];
    
    _effect = (EffectType)[defaults integerForKey:kEffect];
    _effectCycleTime = [defaults integerForKey:kEffectCycleTime];
    
    [toggleCycleEffectsBtn setState:_fCycleEffects];
    [toggleFlatBtn         setState:_fFlat];
    [toggleFogBtn          setState:_fFog];
    [toggleWireframeBtn    setState:_fWireframe];
    
    [effectBtn selectItemAtIndex:_effect];
    [effectCycleTimeField setStringValue:[NSNumber numberWithInt:_effectCycleTime].stringValue];
    
    Renderer *renderer  = _glView.world.renderer;
    renderer.flat       = _fFlat;
    renderer.wireframe  = _fWireframe;
    renderer.effect     = _effect;
    [self setAnimationSpeed:[defaults integerForKey:kAnimationSpeed]];
    
        // Fog settings.
    Fog *fog = renderer.fog;
    fog.enable = _fFog;
    fog.start = [defaults floatForKey:kFogStartDistance];
    fog.end   = [defaults floatForKey:kFogEndDistance  ];
    
    fog.color = colorFromString([defaults stringForKey:kFogColor]);
    fog.mode  = [defaults integerForKey:kFogMode];
}

-(void) savePreferences
{
        // Save the preferences.
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:moduleName];
    
    [defaults setBool:_fFog          forKey:kShowFog      ];
    [defaults setBool:_fFlat         forKey:kFlat         ];
    [defaults setBool:_fWireframe    forKey:kWireframe    ];
    [defaults setBool:_fCycleEffects forKey:kCycleEffects ];

    [defaults setInteger:_effect          forKey:kEffect];
    [defaults setInteger:_effectCycleTime forKey:kEffectCycleTime];
    [defaults setInteger:_animationSpeed  forKey:kAnimationSpeed];
    [defaults synchronize];
}

- (IBAction)closeConfig:(id)sender
{
        // save prefs and close the sheet.
    [self savePreferences];
    NSAssert(self.optionsPanel, @"closeConfig called, but optionsPanel is not set.");
    [[NSApplication sharedApplication] endSheet:self.optionsPanel];
}


+(BOOL)performGammaFade
{
    return NO;  // The opengl part does it's own fading.
}

@end

void DebugLog(const char *fmt, ...)
{
    // Do nothing. Screensaver doesn't have the option for debug logging.
}
