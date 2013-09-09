//
//  PixelCityViewController.h
//  PixelCity
//
//  Created by Patrick Wallace on 24/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//  Released under the GNU GPL v3. See the file COPYING for details.

#import <Cocoa/Cocoa.h>
#import "Render.h"
@class BasicOpenGLView;

@interface PixelCityViewController : NSViewController <NSWindowDelegate>
{
    BOOL fAnimate, fDrawCaps, fDrawHelp;
	BOOL fWireframe, fLetterbox, fFPS, fFog, fFlat, fHelp, fNormalize;
    EffectType effect;
    NSTimer *timer;

        // Menu items
    __weak IBOutlet NSMenuItem * animateMenuItem;
    __weak IBOutlet NSMenuItem * infoMenuItem;
    __weak IBOutlet NSMenuItem * resetMenuItem;
    __weak IBOutlet NSMenuItem * wireframeToggleMenuItem;
    __weak IBOutlet NSMenuItem * effectCycleMenuItem;
    __weak IBOutlet NSMenuItem * letterboxToggleMenuItem;
    __weak IBOutlet NSMenuItem * FPSToggleMenuItem;
    __weak IBOutlet NSMenuItem * fogSettingsMenuItem;
    __weak IBOutlet NSMenuItem * flatToggleMenuItem;
    __weak IBOutlet NSMenuItem * helpToggleMenuItem;
    __weak IBOutlet NSMenuItem * normalizeToggleMenuItem;
    __weak IBOutlet NSMenuItem * debugLogToggleMenuItem;    
}

    // Menu action events.
-(IBAction) animate:         (id) sender;
-(IBAction) info:            (id) sender;
-(IBAction) toggleWireframe: (id) sender;
-(IBAction) nextEffect:      (id) sender;
-(IBAction) toggleLetterbox: (id) sender;
-(IBAction) toggleFPS:       (id) sender;
-(IBAction) toggleFlat:      (id) sender;
-(IBAction) toggleHelp:      (id) sender;
-(IBAction) toggleNormalized:(id) sender;
-(IBAction) toggleDebugLog:  (id) sender;
-(IBAction) resetWorld:      (id) sender;

-(IBAction) showFogSettings: (id) sender;



@end
