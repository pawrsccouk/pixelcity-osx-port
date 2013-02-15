//
// File:		GLString.h 
//				(Originally StringTexture.h)
//
// Abstract:	Uses Quartz to draw a string into an OpenGL texture
//
// Version:		1.1 - Minor enhancements and bug fixes.
//				1.0 - Original release.
//				
//
// Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//				in consideration of your agreement to the following terms, and your use,
//				installation, modification or redistribution of this Apple software
//				constitutes acceptance of these terms.  If you do not agree with these
//				terms, please do not use, install, modify or redistribute this Apple
//				software.
//
//				In consideration of your agreement to abide by the following terms, and
//				subject to these terms, Apple grants you a personal, non - exclusive
//				license, under Apple's copyrights in this original Apple software ( the
//				"Apple Software" ), to use, reproduce, modify and redistribute the Apple
//				Software, with or without modifications, in source and / or binary forms;
//				provided that if you redistribute the Apple Software in its entirety and
//				without modifications, you must retain this notice and the following text
//				and disclaimers in all such redistributions of the Apple Software. Neither
//				the name, trademarks, service marks or logos of Apple Inc. may be used to
//				endorse or promote products derived from the Apple Software without specific
//				prior written permission from Apple.  Except as expressly stated in this
//				notice, no other rights or licenses, express or implied, are granted by
//				Apple herein, including but not limited to any patent rights that may be
//				infringed by your derivative works or by other works in which the Apple
//				Software may be incorporated.
//
//				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//				WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//				PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//				ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//				CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//				SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//				INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//				AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//				UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//				OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2003-2007 Apple Inc. All Rights Reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLContext.h>

@interface NSBezierPath (RoundRect)
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius;

- (void)appendBezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius;
@end

@interface GLString : NSObject
{
	NSAttributedString * _string;
	CGLContextObj _cgl_ctx;          // current context at time of texture creation
	float	      _cRadius;          // Corner radius, if 0 just a rectangle. Defaults to 4.0f
	BOOL          _requiresUpdate;
}

// this API requires a current rendering context and all operations will be performed in regards to thar context
// the same context should be current for all method calls for a particular object instance

#pragma mark - Initializers

    // designated initializer
- (id) initWithAttributedString:(NSAttributedString *)attributedString
                      textColor:(NSColor *)color
                       boxColor:(NSColor *)color
                    borderColor:(NSColor *)color;

- (id) initWithString:(NSString *)aString
           attributes:(NSDictionary *)attribs
            textColor:(NSColor *)color
             boxColor:(NSColor *)color
          borderColor:(NSColor *)color;

// basic methods that pick up defaults
- (id) initWithString:(NSString *)aString attributes:(NSDictionary *)attribs;
- (id) initWithAttributedString:(NSAttributedString *)attributedString;

- (void) dealloc;

#pragma mark - Properties

@property (nonatomic, readonly) GLuint textureId; // 0 if no texture allocated
@property (nonatomic, readonly) NSSize texSize; // actually size of texture generated in texels, (0, 0) if no texture allocated

@property (nonatomic, copy) NSColor *textColor;     // The pre-multiplied default text color (includes alpha) string attributes could override this
@property (nonatomic, copy) NSColor *boxColor;      // The pre-multiplied box color (includes alpha) alpha of 0.0 means no background box
@property (nonatomic, copy) NSColor *borderColor;   // The pre-multiplied border color (includes alpha) alpha of 0.0 means no border
@property (nonatomic) BOOL antialias;
@property (nonatomic, readonly) BOOL staticFrame;   // Whether or not a static frame will be used
@property (nonatomic, readonly) NSSize frameSize;   // Either dynamc frame (text size + margins) or static frame size (switch with staticFrame)
@property (nonatomic, readonly) NSSize marginSize;  // current margins for text offset and pads for dynamic frame


#pragma mark - Methods

- (void) genTexture:(GLuint)textureType; // generates the texture without drawing texture to current context.
- (void) drawWithBounds:(NSRect)bounds;  // will update the texture if required due to change in settings
                                         // (note context should be setup to be orthographic scaled to per pixel scale)
- (void) drawAtPoint:(NSPoint)point;

    // these will force the texture to be regenerated at the next draw
- (void) setMargins:(NSSize)size;           // set offset size and size to fit with offset
- (void) useStaticFrame:(NSSize)size;       // set static frame size and size to frame
- (void) useDynamicFrame;                   // set static frame size and size to frame

    // set string after initial creation
- (void) setString:(NSAttributedString *)attributedString;
- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs;


#pragma mark - External textures.

    // Draw into an already-created texture, whose ID, width and height are provided.
    // This ignores the texture already set up, if one exists.
//-(void) drawIntoTexture:(GLuint)textureId x:(int)x y:(int)y width:(GLuint)texWidth height:(GLuint)texHeight;

    // Create a new texture which shows the provided text.
    // The size of the texture is determined by the amount of text we need to draw.
    // Returns the ID of the texture on success, or 0 on failure.
-(GLuint) makeTexture;

@end

