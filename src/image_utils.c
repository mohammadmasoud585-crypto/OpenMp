#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "convolution.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// Load image from file
Image* load_image(const char* filename) {
    Image* img = (Image*)malloc(sizeof(Image));
    if (!img) {
        fprintf(stderr, "Failed to allocate memory for image structure\n");
        return NULL;
    }

    img->data = stbi_load(filename, &img->width, &img->height, &img->channels, 0);
    
    if (!img->data) {
        fprintf(stderr, "Failed to load image: %s\n", filename);
        fprintf(stderr, "STB Error: %s\n", stbi_failure_reason());
        free(img);
        return NULL;
    }

    printf("Loaded image: %s (%dx%d, %d channels)\n", 
           filename, img->width, img->height, img->channels);
    
    return img;
}

// Save image to file
int save_image(const char* filename, Image* img) {
    if (!img || !img->data) {
        fprintf(stderr, "Invalid image for saving\n");
        return 0;
    }

    int result = 0;
    const char* ext = strrchr(filename, '.');
    
    if (ext) {
        if (strcmp(ext, ".png") == 0 || strcmp(ext, ".PNG") == 0) {
            result = stbi_write_png(filename, img->width, img->height, 
                                   img->channels, img->data, 
                                   img->width * img->channels);
        } else if (strcmp(ext, ".jpg") == 0 || strcmp(ext, ".JPG") == 0 ||
                   strcmp(ext, ".jpeg") == 0 || strcmp(ext, ".JPEG") == 0) {
            result = stbi_write_jpg(filename, img->width, img->height, 
                                   img->channels, img->data, 90);
        } else if (strcmp(ext, ".bmp") == 0 || strcmp(ext, ".BMP") == 0) {
            result = stbi_write_bmp(filename, img->width, img->height, 
                                   img->channels, img->data);
        } else {
            fprintf(stderr, "Unsupported file format: %s\n", ext);
            return 0;
        }
    }

    if (result) {
        printf("Saved image: %s\n", filename);
    } else {
        fprintf(stderr, "Failed to save image: %s\n", filename);
    }

    return result;
}

// Free image memory
void free_image(Image* img) {
    if (img) {
        if (img->data) {
            stbi_image_free(img->data);
        }
        free(img);
    }
}

// Create empty image
Image* create_image(int width, int height, int channels) {
    Image* img = (Image*)malloc(sizeof(Image));
    if (!img) {
        fprintf(stderr, "Failed to allocate memory for image structure\n");
        return NULL;
    }

    img->width = width;
    img->height = height;
    img->channels = channels;
    img->data = (uint8_t*)calloc(width * height * channels, sizeof(uint8_t));

    if (!img->data) {
        fprintf(stderr, "Failed to allocate memory for image data\n");
        free(img);
        return NULL;
    }

    return img;
}

// Create kernel matrix
float** create_kernel(int size) {
    float** kernel = (float**)malloc(size * sizeof(float*));
    if (!kernel) {
        fprintf(stderr, "Failed to allocate memory for kernel\n");
        return NULL;
    }

    for (int i = 0; i < size; i++) {
        kernel[i] = (float*)calloc(size, sizeof(float));
        if (!kernel[i]) {
            fprintf(stderr, "Failed to allocate memory for kernel row %d\n", i);
            for (int j = 0; j < i; j++) {
                free(kernel[j]);
            }
            free(kernel);
            return NULL;
        }
    }

    return kernel;
}

// Free kernel memory
void free_kernel(float** kernel, int size) {
    if (kernel) {
        for (int i = 0; i < size; i++) {
            free(kernel[i]);
        }
        free(kernel);
    }
}

// Create Gaussian kernel
float** create_gaussian_kernel(int size, float sigma) {
    float** kernel = create_kernel(size);
    if (!kernel) return NULL;

    float sum = 0.0f;
    int center = size / 2;

    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            int x = i - center;
            int y = j - center;
            float value = exp(-(x*x + y*y) / (2.0f * sigma * sigma));
            kernel[i][j] = value;
            sum += value;
        }
    }

    // Normalize kernel
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            kernel[i][j] /= sum;
        }
    }

    return kernel;
}

// Create box (average) kernel
float** create_box_kernel(int size) {
    float** kernel = create_kernel(size);
    if (!kernel) return NULL;

    float value = 1.0f / (size * size);

    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            kernel[i][j] = value;
        }
    }

    return kernel;
}

// Print kernel values
void print_kernel(float** kernel, int size) {
    printf("Kernel (%dx%d):\n", size, size);
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            printf("%8.5f ", kernel[i][j]);
        }
        printf("\n");
    }
}

// Print configuration
void print_config(ConvConfig* config) {
    printf("Configuration:\n");
    printf("  Threads: %d\n", config->num_threads);
    printf("  Schedule: %s\n", config->schedule_type);
    printf("  Chunk size: %d\n", config->chunk_size);
    printf("  Tile size: %d%s\n", config->tile_size, 
           config->tile_size == 0 ? " (no tiling)" : "");
    printf("  Loop order: %s\n", config->loop_order == 0 ? "Y-first" : "X-first");
}
