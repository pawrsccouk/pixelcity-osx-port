//
//  Pixel_City_ScreensaverView.h
//  Pixel City Screensaver
//
//  Created by Patrick Wallace on 20/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>

@interface Pixel_City_ScreensaverView : ScreenSaverView
{
    IBOutlet __weak NSButton *toggleFogBtn;
    IBOutlet __weak NSButton *toggleFlatBtn;
    IBOutlet __weak NSButton *toggleWireframeBtn;
    IBOutlet __weak NSButton *toggleCycleEffectsBtn;
    
    IBOutlet __weak NSPopUpButton *effectBtn;
    IBOutlet __weak NSTextField   *effectCycleTimeField, *animationTimeLabel;
    IBOutlet __weak NSSlider      *animationTimeSlider;
}

@property (nonatomic, strong) IBOutlet NSPanel *optionsPanel;

    // Close button.
- (IBAction)closeConfig:(id)sender;

    // Checkboxes
- (IBAction)showFog:(id)sender;
- (IBAction)showFlat:(id)sender;
- (IBAction)showWireframe:(id)sender;
- (IBAction)cycleEffects:(id)sender;

    // Other controls.
- (IBAction)effectCycleTimeChanged:(NSNotification*)notification;
- (IBAction)effectChanged:(id)sender;
- (IBAction)animationTimeChanged:(id)sender;
@end
