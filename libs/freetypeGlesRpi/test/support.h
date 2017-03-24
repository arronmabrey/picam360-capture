//#include <linux/types.h>

#include <EGL/egl.h>
#include <GLES2/gl2.h>

#include <stdbool.h>


enum shaderLocationType { shaderAttrib, shaderUniform };
GLuint getShaderLocation(int type, GLuint prog, const char *name);
char *file_read(const char *filename);
GLuint create_shader(const char *filename, GLenum type);
void print_log(GLuint object);
int loadPNG(const char *filename);
int makeContext();
void closeContext();
void initGlPrint(int w, int h);
void glPrintf(float x, float y, const char *fmt, ...);
void swapBuffers();
int getDisplayWidth();
int getDisplayHeight();
void initSprite(int w, int h);
void drawSprite(float x, float y, float w, float h, float a, int tex);
float rand_range(float min,float max);


