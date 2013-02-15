//
// File:		GLString.m
//				(Originally StringTexture.m)
//
// Abstract:	Uses Quartz to draw a string into an OpenGL texture
//
// Version:		1.1 - Antialiasing option, Rounded Corners to the frame
//					  self contained OpenGL state, performance enhancements,
//					  other bug fixes.
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

#import "GLString.h"
#import "PWGL.h"
#import "RenderAPI.h"

// The following is a NSBezierPath category to allow
// for rounded corners of the border

#pragma mark NSBezierPath Category

@implementation NSBezierPath (RoundRect)

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius {
    NSBezierPath *result = [NSBezierPath bezierPath];
    [result appendBezierPathWithRoundedRect:rect cornerRadius:radius];
    return result;
}

- (void)appendBezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius {
    if (!NSIsEmptyRect(rect)) {
		if (radius > 0.0) {
			// Clamp radius to be no larger than half the rect's width or height.
			float clampedRadius = MIN(radius, 0.5 * MIN(rect.size.width, rect.size.height));
			
			NSPoint topLeft = NSMakePoint(NSMinX(rect), NSMaxY(rect));
			NSPoint topRight = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
			NSPoint bottomRight = NSMakePoint(NSMaxX(rect), NSMinY(rect));
			
			[self moveToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect))];
			[self appendBezierPathWithArcFromPoint:topLeft     toPoint:rect.origin radius:clampedRadius];
			[self appendBezierPathWithArcFromPoint:rect.origin toPoint:bottomRight radius:clampedRadius];
			[self appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight    radius:clampedRadius];
			[self appendBezierPathWithArcFromPoint:topRight    toPoint:topLeft     radius:clampedRadius];
			[self closePath];
		} else {
			// When radius == 0.0, this degenerates to the simple case of a plain rectangle.
			[self appendBezierPathWithRect:rect];
		}
    }
}

@end

#pragma mark - GLString

@implementation GLString
@synthesize textureId = _textureId, texSize = _texSize, textColor = _textColor, boxColor = _boxColor, borderColor = _borderColor;
@synthesize marginSize = _marginSize, antialias = _antialias, staticFrame = _staticFrame, frameSize = _frameSize;


- (void) deleteTexture
{
	if (_textureId && _cgl_ctx) {
		(*_cgl_ctx->disp.delete_textures)(_cgl_ctx->rend, 1, &_textureId);
		_textureId = 0; // ensure it is zeroed for failure cases
		_cgl_ctx = 0;
	}
}

- (void) dealloc
{
	[self deleteTexture];
}

// designated initializer
- (id) initWithAttributedString:(NSAttributedString *)attributedString
                      textColor:(NSColor *)text
                       boxColor:(NSColor *)box
                    borderColor:(NSColor *)border
{
	self = [super init];
    if(self) {
        _cgl_ctx = NULL;
        _textureId = 0;
        _texSize.width = 0.0f;
        _texSize.height = 0.0f;
        _string = attributedString;
        _textColor = text;
        _boxColor = box;
        _borderColor = border;
        _staticFrame = NO;
        _antialias = YES;
        _marginSize.width = 4.0f; // standard margins
        _marginSize.height = 2.0f;
        _cRadius = 4.0f;
        _requiresUpdate = YES;
            // all other variables 0 or NULL
    }
	return self;
}

- (id) initWithString:(NSString *)aString
           attributes:(NSDictionary *)attribs
            textColor:(NSColor *)text
             boxColor:(NSColor *)box
          borderColor:(NSColor *)border
{
	return [self initWithAttributedString:[[NSAttributedString alloc] initWithString:aString attributes:attribs]
                                textColor:text
                                 boxColor:box
                              borderColor:border];
}

// basic methods that pick up defaults
- (id) initWithAttributedString:(NSAttributedString *)attributedString;
{
	return [self initWithAttributedString:attributedString
                                textColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f]
                                 boxColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]
                              borderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

- (id) initWithString:(NSString *)aString attributes:(NSDictionary *)attribs
{
	return [self initWithAttributedString:[[NSAttributedString alloc] initWithString:aString attributes:attribs]
                                textColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f]
                                 boxColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]
                              borderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

static NSBitmapImageRep* makeBitmap(NSAttributedString *string, CGSize frameSize, CGSize marginSize,
                                    NSColor *boxColor, NSColor *borderColor, NSColor *textColor,
                                    BOOL antialias, float cornerRadius)
{
    NSBitmapImageRep *bitmap;
	NSImage *image = [[NSImage alloc] initWithSize:frameSize];
	[image lockFocus];
    @try {
        [[NSGraphicsContext currentContext] setShouldAntialias:antialias];
        
        if ([boxColor alphaComponent]) { // this should be == 0.0f but need to make sure
            [boxColor set];
            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height) , 0.5, 0.5)
                                                            cornerRadius:cornerRadius];
            [path fill];
        }
        
        if ([borderColor alphaComponent]) {
            [borderColor set];
            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height), 0.5, 0.5)
                                                            cornerRadius:cornerRadius];
            [path setLineWidth:1.0f];
            [path stroke];
        }
        
        [textColor set];
        [string drawAtPoint:NSMakePoint (marginSize.width, marginSize.height)]; // draw at offset position
       bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height)];
    }
    @finally { [image unlockFocus]; }
    return bitmap;
}

static void drawIntoTex(CGSize texSize, CGSize previousSize, int x, int y, NSBitmapImageRep *bitmap, GLuint textureId, BOOL isDecal)
{
    pwPushAttrib(GL_TEXTURE_BIT);
    @try {
		pwBindTexture(isDecal ? GL_TEXTURE_2D : GL_TEXTURE_RECTANGLE_EXT, textureId);
		if (NSEqualSizes(previousSize, texSize)) {
			pwTexSubImage2D(isDecal ? GL_TEXTURE_2D : GL_TEXTURE_RECTANGLE_EXT,
                            0,x,y,texSize.width,texSize.height,
                            [bitmap hasAlpha] ? GL_RGBA : GL_RGB,GL_UNSIGNED_BYTE,[bitmap bitmapData]);
		} else {
			pwTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			pwTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			pwTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, texSize.width, texSize.height, 0,
                         [bitmap hasAlpha] ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
		}
    }
	@finally { pwPopAttrib(); }
}

- (void) genTexture:(GLuint) textureType ; // generates the texture without drawing texture to current context
{
    NSAssert(textureType == GL_TEXTURE_2D || textureType == GL_TEXTURE_RECTANGLE_EXT, @"Unknown texture type %d", textureType);

	if ((NO == _staticFrame) && (0.0f == _frameSize.width) && (0.0f == _frameSize.height)) { // find frame size if we have not already found it
		_frameSize = [_string size]; // current string size
		_frameSize.width += _marginSize.width * 2.0f; // add padding
		_frameSize.height += _marginSize.height * 2.0f;
	}

    NSBitmapImageRep *bitmap = makeBitmap(_string, _frameSize, _marginSize, _boxColor, _borderColor, _textColor, _antialias, _cRadius);

	NSSize previousSize = _texSize;
	_texSize.width = [bitmap pixelsWide];
	_texSize.height = [bitmap pixelsHigh];
    
    if (0 == _textureId) glGenTextures (1, &_textureId);
	if((_cgl_ctx = CGLGetCurrentContext())) { // if we successfully retrieve a current context (required)
        pwPushAttrib(GL_TEXTURE_BIT);
        @try {
            pwBindTexture(textureType, _textureId);
            if (NSEqualSizes(previousSize, _texSize)) {
                pwTexSubImage2D(textureType,
                                0, 0, 0,_texSize.width, _texSize.height,
                                [bitmap hasAlpha] ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
            } else {
                pwTexParameteri(textureType, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                pwTexParameteri(textureType, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                pwTexImage2D(textureType, 0, GL_RGBA, _texSize.width, _texSize.height, 0,
                             [bitmap hasAlpha] ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
            }
        }
        @finally { pwPopAttrib(); }
    } else
		NSLog (@"StringTexture -genTexture: Failure to get current OpenGL context\n");
	
	_requiresUpdate = NO;
}

//-(void)drawIntoTexture:(GLuint)textureId x:(int)x y:(int)y width:(GLuint)texWidth height:(GLuint)texHeight
//{
//    glReportError("drawIntoTexture BEGIN");
//
////    _staticFrame = YES;
////    _frameSize = CGSizeMake(texWidth, texHeight);
////    _texSize   = _frameSize;
//
//    _staticFrame = NO;
//    _texSize = CGSizeMake(texWidth, texHeight);
//    _marginSize = CGSizeZero;
//	if ((NO == _staticFrame) && (0.0f == _frameSize.width) && (0.0f == _frameSize.height)) { // find frame size if we have not already found it
//		_frameSize = [_string size]; // current string size
//		_frameSize.width += _marginSize.width * 2.0f; // add padding
//		_frameSize.height += _marginSize.height * 2.0f;
//	}
//
//	if((_cgl_ctx = CGLGetCurrentContext())) {
//        NSBitmapImageRep *bitmap = makeBitmap(_string, _frameSize, _marginSize, _boxColor, _borderColor, _textColor, _antialias, _cRadius);
//        pwPushAttrib(GL_TEXTURE_BIT);
//        @try {
//            pwBindTexture(GL_TEXTURE_2D, textureId);
//            NSAssert(bitmap.hasAlpha, @"Bitmap needs an alpha channel for RGBA textures");
//            pwTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _frameSize.width, _frameSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
//        }
//        @finally { pwPopAttrib(); }
//    }
//	else
//		NSLog (@"StringTexture -genTexture: Failure to get current OpenGL context\n");
//    
//    glReportError("drawIntoTexture END");
//}

-(GLuint)makeTexture
{
    [self genTexture:GL_TEXTURE_2D];
    GLuint texId = self.textureId;
    _textureId      = 0;    // Free the ID so the string doesn't delete it on exist
    _requiresUpdate = YES;  // Since the texture has been deleted, prompt to regenerate one if it is used again.
    return texId;
}

#pragma mark Accessors

- (void) setTextColor:(NSColor *)color // set default text color
{
	_textColor = color;
	_requiresUpdate = YES;
}


- (void) setBoxColor:(NSColor *)color // set default text color
{
	_boxColor = color;
	_requiresUpdate = YES;
}


- (void) setBorderColor:(NSColor *)color // set default text color
{
	_borderColor = color;
	_requiresUpdate = YES;
}


// these will force the texture to be regenerated at the next draw
- (void) setMargins:(NSSize)size // set offset size and size to fit with offset
{
	_marginSize = size;
	if (NO == _staticFrame) { // ensure dynamic frame sizes will be recalculated
		_frameSize.width = 0.0f;
		_frameSize.height = 0.0f;
	}
	_requiresUpdate = YES;
}


- (void) setAntialias:(BOOL)request
{
	_antialias = request;
	_requiresUpdate = YES;
}


#pragma mark Frame

- (NSSize) frameSize
{
	if ((NO == _staticFrame) && (0.0f == _frameSize.width) && (0.0f == _frameSize.height)) { // find frame size if we have not already found it
		_frameSize = [_string size]; // current string size
		_frameSize.width += _marginSize.width * 2.0f; // add padding
		_frameSize.height += _marginSize.height * 2.0f;
	}
	return _frameSize;
}

- (void) useStaticFrame:(NSSize)size // set static frame size and size to frame
{
	_frameSize = size;
	_staticFrame = YES;
	_requiresUpdate = YES;
}

- (void) useDynamicFrame
{
	if (_staticFrame) { // set to dynamic frame and set to regen texture
		_staticFrame = NO;
		_frameSize.width = 0.0f; // ensure frame sizes will be recalculated
		_frameSize.height = 0.0f;
		_requiresUpdate = YES;
	}
}

#pragma mark String

- (void) setString:(NSAttributedString *)attributedString // set string after initial creation
{
	_string = attributedString;
	if (NO == _staticFrame) { // ensure dynamic frame sizes will be recalculated
		_frameSize.width = 0.0f;
		_frameSize.height = 0.0f;
	}
	_requiresUpdate = YES;
}

- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs; // set string after initial creation
{
	[self setString:[[NSAttributedString alloc] initWithString:aString attributes:attribs]];
}


#pragma mark Drawing

- (void) drawWithBounds:(NSRect)bounds
{
	if (_requiresUpdate)
		[self genTexture:GL_TEXTURE_RECTANGLE_EXT];
	if (_textureId) {
		pwPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT | GL_COLOR_BUFFER_BIT); // GL_COLOR_BUFFER_BIT for glBlendFunc, GL_ENABLE_BIT for glEnable / glDisable
		
		pwDisable (GL_DEPTH_TEST); // ensure text is not remove by depth buffer test.
		pwEnable (GL_BLEND); // for text fading
		pwBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // ditto
		pwEnable (GL_TEXTURE_RECTANGLE_EXT);
		
		pwBindTexture (GL_TEXTURE_RECTANGLE_EXT, _textureId);
		pwBegin (GL_QUADS);
			pwTexCoord2f (0.0f, 0.0f); // draw upper left in world coordinates
			pwVertex2f (bounds.origin.x, bounds.origin.y);
	
			pwTexCoord2f (0.0f, _texSize.height); // draw lower left in world coordinates
			pwVertex2f (bounds.origin.x, bounds.origin.y + bounds.size.height);
	
			pwTexCoord2f (_texSize.width, _texSize.height); // draw upper right in world coordinates
			pwVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
	
			pwTexCoord2f (_texSize.width, 0.0f); // draw lower right in world coordinates
			pwVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y);
		pwEnd ();
		
		pwPopAttrib();
	}
}

- (void) drawAtPoint:(NSPoint)point
{
	if (_requiresUpdate)
		[self genTexture:GL_TEXTURE_RECTANGLE_EXT]; // ensure size is calculated for bounds

	if (_textureId) // if successful
		[self drawWithBounds:NSMakeRect (point.x, point.y, _texSize.width, _texSize.height)];
}


@end

