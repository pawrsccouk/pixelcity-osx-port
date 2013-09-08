//
//  FogSettingsViewController.h
//  PixelCity
//
//  Created by Patrick Wallace on 01/03/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Fog;

@interface FogSettingsWindowController : NSWindowController
{
    IBOutlet NSButton *showFogButton, *animateColorButton;
    IBOutlet NSTextField *startField, *endField, *densityField;
    IBOutlet NSTextField *valueRangeLabel;
    IBOutlet NSPopUpButton *modeButton;
    IBOutlet NSColorWell *colorWell;
}

@property (nonatomic, weak) Fog *fog;

    // Apply the fog settings to the model before it starts to animate.
-(void) setupApp;

#pragma mark - IB Actions

-(IBAction) showFogChanged: (id)sender;
-(IBAction) startChanged:   (id)sender;
-(IBAction) endChanged:     (id)sender;
-(IBAction) densityChanged: (id)sender;
-(IBAction) modeChanged:    (id)sender;
-(IBAction) fogColorChanged:(id)sender;
-(IBAction) fogColorAnimateChanged:(id)sender;

@end
