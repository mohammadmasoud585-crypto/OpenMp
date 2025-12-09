/* stb_image - v2.28 - public domain image loader - http://nothings.org/stb
   
   برای استفاده از نسخه کامل:
   1. این فایل را از اینجا دانلود کنید:
      https://raw.githubusercontent.com/nothings/stb/master/stb_image.h
   
   2. این فایل stub را جایگزین کنید
   
   یا به صورت خودکار:
   wget https://raw.githubusercontent.com/nothings/stb/master/stb_image.h -O include/stb_image.h
*/

#ifndef STBI_INCLUDE_STB_IMAGE_H
#define STBI_INCLUDE_STB_IMAGE_H

#warning "This is a STUB version of stb_image.h - Download the real version from https://github.com/nothings/stb/blob/master/stb_image.h"

typedef unsigned char stbi_uc;

#ifdef __cplusplus
extern "C" {
#endif

stbi_uc *stbi_load(char const *filename, int *x, int *y, int *channels_in_file, int desired_channels);
void stbi_image_free(void *retval_from_stbi_load);
const char *stbi_failure_reason(void);

#ifdef __cplusplus
}
#endif

#endif // STBI_INCLUDE_STB_IMAGE_H

// DOCUMENTATION
//
// Limitations:
//    - no 12-bit-per-channel JPEG
//    - no JPEGs with arithmetic coding
//    - GIF always returns *comp=4
//
// Basic usage (see HDR discussion below for HDR usage):
//    int x,y,n;
//    unsigned char *data = stbi_load(filename, &x, &y, &n, 0);
//    // ... process data if not NULL ...
//    // ... x = width, y = height, n = # 8-bit components per pixel ...
//    // ... replace '0' with '1'..'4' to force that many components per pixel
//    // ... but 'n' will always be the number that it would have been if you said 0
//    stbi_image_free(data);

#ifndef STBIDEF
#ifdef STB_IMAGE_STATIC
#define STBIDEF static
#else
#define STBIDEF extern
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned char stbi_uc;
typedef unsigned short stbi_us;

STBIDEF stbi_uc *stbi_load(char const *filename, int *x, int *y, int *channels_in_file, int desired_channels);
STBIDEF stbi_uc *stbi_load_from_memory(stbi_uc const *buffer, int len, int *x, int *y, int *channels_in_file, int desired_channels);
STBIDEF void stbi_image_free(void *retval_from_stbi_load);
STBIDEF const char *stbi_failure_reason(void);

#ifdef __cplusplus
}
#endif

//
//
////   end header file   /////////////////////////////////////////////////////
#endif // STBI_INCLUDE_STB_IMAGE_H

#ifdef STB_IMAGE_IMPLEMENTATION

#include <stdarg.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#ifndef STBI_NO_STDIO
#include <stdio.h>
#endif

#ifndef STBI_ASSERT
#include <assert.h>
#define STBI_ASSERT(x) assert(x)
#endif

#ifdef __cplusplus
#define STBI_EXTERN extern "C"
#else
#define STBI_EXTERN extern
#endif

#ifndef _MSC_VER
   #ifdef __cplusplus
   #define stbi_inline inline
   #else
   #define stbi_inline
   #endif
#else
   #define stbi_inline __forceinline
#endif

#ifndef STBI_NO_THREAD_LOCALS
   #if defined(__cplusplus) &&  __cplusplus >= 201103L
      #define STBI__THREAD_LOCAL thread_local
   #elif defined(__GNUC__) && __GNUC__ < 5
      #define STBI__THREAD_LOCAL __thread
   #elif defined(_MSC_VER)
      #define STBI__THREAD_LOCAL __declspec(thread)
   #elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L && !defined(__STDC_NO_THREADS__)
      #define STBI__THREAD_LOCAL _Thread_local
   #endif

   #ifndef STBI__THREAD_LOCAL
      #if defined(__GNUC__)
         #define STBI__THREAD_LOCAL __thread
      #endif
   #endif
#endif

typedef unsigned char  stbi__uint8;
typedef unsigned short stbi__uint16;
typedef   signed short stbi__int16;
typedef unsigned int   stbi__uint32;
typedef   signed int   stbi__int32;

#ifdef _MSC_VER
typedef unsigned __int64 stbi__uint64;
#else
typedef unsigned long long stbi__uint64;
#endif

typedef struct
{
   stbi__uint32 img_x, img_y;
   int img_n, img_out_n;

   void *io_user_data;

   int read_from_callbacks;
   int buflen;
   stbi__uint8 buffer_start[128];
   int callback_already_read;

   stbi__uint8 *img_buffer, *img_buffer_end;
   stbi__uint8 *img_buffer_original, *img_buffer_original_end;
} stbi__context;

static void stbi__refill_buffer(stbi__context *s);

static void stbi__start_mem(stbi__context *s, stbi__uint8 const *buffer, int len)
{
   s->io_user_data = NULL;
   s->read_from_callbacks = 0;
   s->callback_already_read = 0;
   s->img_buffer = s->img_buffer_original = (stbi__uint8 *) buffer;
   s->img_buffer_end = s->img_buffer_original_end = (stbi__uint8 *) buffer+len;
}

#ifndef STBI_NO_STDIO

static FILE *stbi__fopen(char const *filename, char const *mode)
{
   FILE *f;
#if defined(_WIN32) && defined(STBI_WINDOWS_UTF8)
   wchar_t wMode[64];
   wchar_t wFilename[1024];
   if (0 == MultiByteToWideChar(65001 /* UTF8 */, 0, filename, -1, wFilename, sizeof(wFilename)/sizeof(*wFilename)))
      return 0;

   if (0 == MultiByteToWideChar(65001 /* UTF8 */, 0, mode, -1, wMode, sizeof(wMode)/sizeof(*wMode)))
      return 0;

#if defined(_MSC_VER) && _MSC_VER >= 1400
   if (0 != _wfopen_s(&f, wFilename, wMode))
      f = 0;
#else
   f = _wfopen(wFilename, wMode);
#endif

#elif defined(_MSC_VER) && _MSC_VER >= 1400
   if (0 != fopen_s(&f, filename, mode))
      f=0;
#else
   f = fopen(filename, mode);
#endif
   return f;
}


STBIDEF stbi_uc *stbi_load(char const *filename, int *x, int *y, int *comp, int req_comp)
{
   FILE *f = stbi__fopen(filename, "rb");
   unsigned char *result;
   if (!f) return NULL;
   result = (unsigned char *)malloc((*x) * (*y) * 4);  // Simplified stub
   fclose(f);
   return result;
}
#endif

STBIDEF void stbi_image_free(void *retval_from_stbi_load)
{
   free(retval_from_stbi_load);
}

STBIDEF stbi_uc *stbi_load_from_memory(stbi_uc const *buffer, int len, int *x, int *y, int *comp, int req_comp)
{
   stbi__context s;
   stbi__start_mem(&s,buffer,len);
   return (unsigned char *)malloc((*x) * (*y) * 4);  // Simplified stub
}

static char *stbi__g_failure_reason;

STBIDEF const char *stbi_failure_reason(void)
{
   return stbi__g_failure_reason;
}

#endif // STB_IMAGE_IMPLEMENTATION
