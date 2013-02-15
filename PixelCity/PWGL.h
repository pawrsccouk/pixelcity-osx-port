//
//  PWGL.h
//  PixelCity
//
//  Created by Patrick Wallace on 10/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#ifndef PixelCity_PWGL_h
#define PixelCity_PWGL_h

#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#ifdef __cplusplus
extern "C" {
#endif

    // Replacements for OpenGL calls that report errors.
void pwEnable (GLenum i);
void pwDisable(GLenum i);
void pwMatrixMode(GLenum i);
void pwLoadIdentity();
void pwDepthMask(GLboolean b);
void pwRotatef(GLfloat angle, GLfloat x, GLfloat y, GLfloat z);
void pwTranslatef(GLfloat x, GLfloat y, GLfloat z);
void pwHint(GLenum target, GLenum mode);
void pwShadeModel(GLenum e);
void pwFogi(GLenum name, GLint mode);
void pwDepthFunc(GLenum f);
void pwCullFace(GLenum f);
void pwBlendFunc(GLenum sfactor, GLenum dfactor);
void pwViewport(GLint x, GLint y, GLsizei w, GLsizei h);
void pwClearColor(GLclampf r, GLclampf g, GLclampf b, GLclampf a);
void pwClear(GLbitfield mask);
void pwFogf(GLenum name, GLfloat param);
void pwFogfv(GLenum name, const GLfloat* params);
void pwBegin(GLenum mode);
void pwEnd();
void pwNewList(GLint name, GLenum mode);
void pwEndList();
void pwLineWidth(GLfloat f);
void pwBindTexture(GLenum type, GLuint texture);
void pwPolygonMode(GLenum face, GLenum mode);
void pwPushAttrib (GLbitfield mask);
void pwPopAttrib (void);

void pwTexImage2D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
void pwTexParameteri(GLenum target, GLenum pname, GLenum param);
void pwCopyTexImage2D(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
void pwGetTexImage(GLenum target, GLint level, GLenum format, GLenum type, GLvoid *pixels);
GLint pwuBuild2DMipmaps( GLenum target, GLint internalFormat, GLsizei width, GLsizei height, GLenum format, GLenum type, const void *data );
void pwTexSubImage2D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height,
                      GLenum format, GLenum type, const GLvoid *pixels);

    // Replacements for glPush/PopMatrix that track and debug.
void pwPushMatrix(void);
void pwPopMatrix(void);

    // If OpenGL had errors, report them. Where indicates where the first error was found.
void glReportError(const char* where);
void pwColor3f(GLfloat r, GLfloat g, GLfloat b);
void pwCallList(GLuint list);
void pwVertex2f(GLfloat x, GLfloat y);
void pwTexCoord2f(GLfloat x, GLfloat y);

#ifdef __cplusplus
}
#endif


#endif
