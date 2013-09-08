//
//  FogSettingsViewController.m
//  PixelCity
//
//  Created by Patrick Wallace on 01/03/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "FogSettingsWindowController.h"
#import "Model.h"
#import "Fog.h"
#import "Ini.h"

@interface FogSettingsWindowController ()

@end

@implementation FogSettingsWindowController


static void loadAndSetup(NSTextField *textField, void (^block)(float value), NSString *key)
{
    NSCAssert(textField, @"textField for key %@ is not set", key);
    float value = IniFloat(key);
    if(block) { block(value); }
    textField.floatValue = value;
}

    // Values for the tag in Interface builder.
enum ModeTags { TAG_LINEAR = 1, TAG_EXP, TAG_EXP2 };

-(void)setupApp
{
    NSWindow *window = self.window; // triggers window load from NIB.
    NSAssert(window, @"%@: .window is null after load", self);
    NSAssert(self.fog, @"%@: .fog property has not been set.", self);
    Fog *fog = self.fog;
    BOOL showFog = (IniInt(kShowFog) != 0);
    showFogButton.state = showFog ? NSOnState : NSOffState;
    fog.enable = showFog;
    
    loadAndSetup(startField  , ^(float value) { fog.start   = value; }, kFogStartDistance);
    loadAndSetup(endField    , ^(float value) { fog.end     = value; }, kFogEndDistance  );
    loadAndSetup(densityField, ^(float value) { fog.density = value; }, kFogDensity      );    
    
    GLlong fogMode = IniInt(kFogMode);
    switch (fogMode) {
        case GL_LINEAR: [modeButton selectItemWithTag:TAG_LINEAR];   break;
        case GL_EXP   : [modeButton selectItemWithTag:TAG_EXP];      break;
        case GL_EXP2  : [modeButton selectItemWithTag:TAG_EXP2];     break;
        default       : [modeButton selectItemWithTag:TAG_LINEAR];
                        NSLog(@"Unknown fog mode setting %ld, defaulting to LINEAR", fogMode);
                        fogMode = GL_LINEAR;
            break;
    }
    fog.mode = fogMode;
    
    valueRangeLabel.stringValue = [NSString stringWithFormat:@"Values range from %.0f to %.0f", fog.minDistance, fog.maxDistance];
    
    NSColor *fogColor = IniColor(kFogColor);
    fog.color = fogColor;
    colorWell.color = fogColor;
    
    BOOL animateColor = (IniInt(kAnimateFogColor) != 0);
    fog.animateColor = animateColor;
    animateColorButton.state = animateColor ? NSOnState : NSOffState;
}

-(void) assertParam:(id) sender ofClass:(Class) cls
{
    NSAssert([sender isKindOfClass:cls], @"%@: Sender %@ is not of class %@.", self, sender, cls);
    NSAssert(self.fog, @"%@: .fog is not set.", self);
    NSAssert(self.window, @"%@: .window is not set.", self);
}

-(IBAction)showFogChanged:(id)sender
{
    [self assertParam:sender ofClass:NSButton.class];
    NSButton *button = sender;
    self.fog.enable = (button.state == NSOnState);
    IniIntSet(kShowFog, self.fog.enable ? 1 : 0);
}

-(IBAction)startChanged:(id)sender
{
    [self assertParam:sender ofClass:NSTextField.class];
    NSTextField *textField = sender;
    self.fog.start = textField.stringValue.floatValue;
    IniFloatSet(kFogStartDistance, self.fog.start);
}

-(IBAction)endChanged:(id)sender
{
    [self assertParam:sender ofClass:NSTextField.class];
    NSTextField *textField = sender;
    self.fog.end = textField.floatValue;
    IniFloatSet(kFogEndDistance, self.fog.end);
}

-(IBAction)densityChanged:(id)sender
{
    [self assertParam:sender ofClass:NSTextField.class];
    NSTextField *textField = sender;
    self.fog.density = textField.floatValue;
    IniFloatSet(kFogDensity, self.fog.density);
}

-(IBAction)modeChanged:(id)sender
{
    [self assertParam:sender ofClass:NSPopUpButton.class];
    NSPopUpButton *button = sender;
    NSMenuItem *menuItem = button.selectedCell;
    NSAssert((menuItem.tag == TAG_LINEAR || menuItem.tag == TAG_EXP || menuItem.tag == TAG_EXP2),
             @"menuItem %@ from button %@ has invalid tag %ld", menuItem, button, (GLlong)menuItem.tag);
    GLenum mode = GL_LINEAR;
    switch (menuItem.tag) {
        case TAG_LINEAR: mode = GL_LINEAR; break;
        case TAG_EXP   : mode = GL_EXP   ; break;
        case TAG_EXP2  : mode = GL_EXP2  ; break;
    }
    self.fog.mode = mode;
    IniIntSet(kFogMode, mode);
}

-(IBAction)fogColorChanged:(id)sender
{
    [self assertParam:sender ofClass:NSColorWell.class];
    NSColorWell *well = sender;
    self.fog.color = well.color;
    IniColorSet(kFogColor, self.fog.color);
}

-(void)fogColorAnimateChanged:(id)sender
{
    [self assertParam:sender ofClass:NSButton.class];
    NSButton *button = sender;
    self.fog.animateColor = (button.state == NSOnState);
    IniIntSet(kAnimateFogColor, self.fog.animateColor);
}

@end
