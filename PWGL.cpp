//
//  PWGL.cpp
//  PixelCity
//
//  Created by Patrick Wallace on 10/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWGL.h"
#import <cassert>

void pwBegin(GLenum mode)	{ glBegin(mode); }	// note: glGetError() (hence glReportError()) is not legal inside a glBegin/glEnd pair.
void pwEnd()				{ glEnd();			glReportError("glEnd");		}

void pwNewList(GLint name, GLenum mode) { glNewList(name, mode);	glReportError("glNewList"); }
void pwEndList()						{ glEndList();				glReportError("glEndList"); }

void pwPushMatrix(void)	{ glPushMatrix();	glReportError("pwPushMatrix");	}
void pwPopMatrix(void){	glPopMatrix();	glReportError("pwPopMatrix");	}

void pwPushAttrib(GLbitfield attrs) { glPushAttrib(attrs); glReportError("glPushAttrib"); }
void pwPopAttrib(void) { glPopAttrib(); glReportError("glPopAttrib"); }

void pwEnable (GLenum i) {	glEnable (i);	glReportError("glEnable");  }
void pwDisable(GLenum i) {	glDisable(i);	glReportError("glDisable");  }

void pwMatrixMode(GLenum i)	{ glMatrixMode(i);	glReportError("glMatrixMode"); }
void pwLoadIdentity()		{ glLoadIdentity();	glReportError("glLoadIdentity"); }
void pwDepthMask(GLboolean b) { assert(b == GL_TRUE || b == GL_FALSE); glDepthMask(b); glReportError("glDepthMask"); }
void pwRotatef(GLfloat angle, GLfloat x, GLfloat y, GLfloat z) { glRotatef(angle, x, y, z); glReportError("glRotatef"); }
void pwTranslatef(GLfloat x, GLfloat y, GLfloat z) {  glTranslatef (x, y, z); glReportError("glTranslatef"); }
void pwViewport(GLint x, GLint y, GLsizei w, GLsizei h) { glViewport(x, y, w, h);	glReportError("glViewport"); }
void pwClearColor(GLclampf r, GLclampf g, GLclampf b, GLclampf a) { glClearColor (r, g, b, a);	glReportError("glClearColor"); }
void pwClear(GLbitfield mask) { glClear(mask);	glReportError("glClear"); }
void pwFogf(GLenum name, GLfloat param) { glFogf(name, param); glReportError("glFogf"); }
void pwFogfv(GLenum name, const GLfloat* params) { glFogfv(name, params); glReportError("glFogfv"); }
void pwHint(GLenum target, GLenum mode) {  glHint(target, mode);	glReportError("glHint"); }
void pwShadeModel(GLenum e) { glShadeModel(e);						glReportError("glShadeModel"); }
void pwFogi(GLenum name, GLint mode)    {  glFogi(name, mode);		glReportError("glFogi"); }
void pwDepthFunc(GLenum f)              {  glDepthFunc(f);			glReportError("glDepthFunc"); }
void pwCullFace(GLenum f)				{  glCullFace (f);			glReportError("glCullFace");  }
void pwBlendFunc(GLenum sfactor, GLenum dfactor) { glBlendFunc (sfactor, dfactor);	glReportError("glBlendFunc"); }
void pwBindTexture(GLenum type, GLuint texture) { 	glBindTexture(type, texture);	glReportError("glBindTexture"); }
void pwPolygonMode(GLenum face, GLenum mode) { glPolygonMode(face, mode); glReportError("glPolygonMode");	}
void pwLineWidth(GLfloat f) { glLineWidth(f);	glReportError("glLineWidth"); }
void pwTexImage2D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels)
{ glTexImage2D(target, level, internalformat, width, height, border, format, type, pixels);
	glReportError("glTexImage2D");
}
void pwTexParameteri(GLenum target, GLenum pname, GLenum param) { glTexParameteri(target, pname, param); glReportError("glTexParameteri"); }

void pwCopyTexImage2D(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border)
{	glCopyTexImage2D(target, level, internalformat, x, y, width, height, border);	glReportError("glCopyTexImage2D"); }
void pwGetTexImage(GLenum target, GLint level, GLenum format, GLenum type, GLvoid *pixels) { glGetTexImage(target, level, format, type, pixels); glReportError("glGetTexImage"); }
GLint pwuBuild2DMipmaps( GLenum target, GLint internalFormat, GLsizei width, GLsizei height, GLenum format, GLenum type, const void *data )
{ GLint rv = gluBuild2DMipmaps(target, internalFormat, width, height, format, type, data);	glReportError("gluBuild2DMipmaps");
	return rv;
}
void pwTexSubImage2D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height,
                      GLenum format, GLenum type, const GLvoid *pixels)
{ glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels); glReportError("glTexSubImage2D"); }

// PAW: These are NOT error-checked because glGetError() is not allowed between glBegin()/glEnd()
// so checking for errors is, in itself, an error. (it returns "invalid operation" from glEnd()).

void pwColor3f(GLfloat r, GLfloat g, GLfloat b) { glColor3f(r, g, b); }
void pwCallList(GLuint list) { glCallList(list); }
void pwVertex2f(GLfloat x, GLfloat y) { glVertex2f(x, y); }
void pwTexCoord2f(GLfloat s, GLfloat t) { glTexCoord2f(s, t); }
