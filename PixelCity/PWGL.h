//
//  PWGL.h
//  PixelCity
//
//  Created by Patrick Wallace on 10/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//  Released under the GNU GPL v3. See file COPYING for details.

#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

// Define long types (OpenGL doesn't seem to have these).
typedef unsigned long GLulong;
typedef long GLlong;

#ifdef __cplusplus
extern "C" {
#endif

    // If OpenGL had errors, report them. Where indicates where the first error was found.
void glReportError(const char* where);

#ifdef PW_DEBUG_OPENGL

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
    void pwDeleteLists(GLuint lists, GLsizei range);
    void pwNewList(GLint name, GLenum mode);
    void pwEndList();
    void pwLineWidth(GLfloat f);
    void pwBindTexture(GLenum type, GLuint texture);
    void pwPolygonMode(GLenum face, GLenum mode);
    void pwPushAttrib (GLbitfield mask);
    void pwPopAttrib (void);
    void pwGenTextures(GLsizei n, GLuint *textures);
    void pwGetIntegerv(GLenum pname, GLint *params);
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
        // These don't report errors, because calling glGetError() inside a glBegin()/glEnd() generates an error.
    void pwColor3f(GLfloat r, GLfloat g, GLfloat b);
    void pwCallList(GLuint list);
    void pwVertex2f(GLfloat x, GLfloat y);
    void pwVertex3f(GLfloat x, GLfloat y, GLfloat z);
    void pwTexCoord2f(GLfloat x, GLfloat y);

#else
    // Release mode - Just replace with the default opengl function.
    
#define pwEnable       glEnable
#define pwDisable      glDisable
#define pwMatrixMode   glMatrixMode
#define pwLoadIdentity glLoadIdentity
#define pwDepthMask    glDepthMask
#define pwRotatef      glRotatef
#define pwTranslatef   glTranslatef
#define pwHint         glHint
#define pwShadeModel   glShadeModel
#define pwFogi         glFogi
#define pwDepthFunc    glDepthFunc
#define pwCullFace     glCullFace
#define pwBlendFunc    glBlendFunc
#define pwViewport     glViewport
#define pwClearColor   glClearColor
#define pwClear        glClear
#define pwFogf         glFogf
#define pwFogfv        glFogfv
#define pwBegin        glBegin
#define pwEnd          glEnd
#define pwDeleteLists     glDeleteLists
#define pwNewList         glNewList
#define pwEndList         glEndList
#define pwLineWidth       glLineWidth
#define pwBindTexture     glBindTexture
#define pwPolygonMode     glPolygonMode
#define pwPushAttrib      glPushAttrib
#define pwPopAttrib       glPopAttrib
#define pwGenTextures     glGenTextures
#define pwGetIntegerv     glGetIntegerv
#define pwTexImage2D      glTexImage2D
#define pwTexParameteri   glTexParameteri
#define pwCopyTexImage2D  glCopyTexImage2D
#define pwGetTexImage     glGetTexImage
#define pwuBuild2DMipmaps gluBuild2DMipmaps
#define pwTexSubImage2D   glTexSubImage2D
#define pwPushMatrix glPushMatrix
#define pwPopMatrix  glPopMatrix
#define pwColor3f    glColor3f
#define pwCallList   glCallList
#define pwVertex2f   glVertex2f
#define pwVertex3f   glVertex3f
#define pwTexCoord2f glTexCoord2f

#endif

#ifdef __cplusplus
}
#endif


