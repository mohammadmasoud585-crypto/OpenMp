#ifndef CONVOLUTION_H
#define CONVOLUTION_H

#include <stdint.h>

// Image structure
typedef struct {
    int width;
    int height;
    int channels;
    uint8_t *data;
} Image;

// Convolution configuration
typedef struct {
    int num_threads;
    char schedule_type[16];  // "static", "dynamic", "guided"
    int chunk_size;
    int tile_size;           // 0 for no tiling, 8 for 8x8, 16 for 16x16
    int loop_order;          // 0 for Y-first, 1 for X-first
} ConvConfig;

// Function prototypes
Image* load_image(const char* filename);
int save_image(const char* filename, Image* img);
void free_image(Image* img);

Image* create_image(int width, int height, int channels);
float** create_kernel(int size);
void free_kernel(float** kernel, int size);
float** create_gaussian_kernel(int size, float sigma);
float** create_box_kernel(int size);

// Convolution functions
void convolve_openmp(Image* input, Image* output, float** kernel, int kernel_size, ConvConfig* config);
void convolve_openmp_tiled(Image* input, Image* output, float** kernel, int kernel_size, ConvConfig* config);
void convolve_sequential(Image* input, Image* output, float** kernel, int kernel_size);

// Utility functions
double get_time();
void print_config(ConvConfig* config);
void print_kernel(float** kernel, int size);

#endif // CONVOLUTION_H
