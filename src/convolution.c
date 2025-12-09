#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include "convolution.h"

// Get current time in seconds
double get_time() {
    return omp_get_wtime();
}

// Sequential convolution (baseline)
void convolve_sequential(Image* input, Image* output, float** kernel, int kernel_size) {
    int width = input->width;
    int height = input->height;
    int channels = input->channels;
    int half_kernel = kernel_size / 2;

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            for (int c = 0; c < channels; c++) {
                float sum = 0.0f;

                for (int ky = 0; ky < kernel_size; ky++) {
                    for (int kx = 0; kx < kernel_size; kx++) {
                        int img_y = y + ky - half_kernel;
                        int img_x = x + kx - half_kernel;

                        // Handle boundaries with zero-padding
                        if (img_y >= 0 && img_y < height && img_x >= 0 && img_x < width) {
                            int idx = (img_y * width + img_x) * channels + c;
                            sum += input->data[idx] * kernel[ky][kx];
                        }
                    }
                }

                int out_idx = (y * width + x) * channels + c;
                output->data[out_idx] = (uint8_t)fmin(fmax(sum, 0.0f), 255.0f);
            }
        }
    }
}

// OpenMP parallel convolution with configurable scheduling
void convolve_openmp(Image* input, Image* output, float** kernel, int kernel_size, ConvConfig* config) {
    int width = input->width;
    int height = input->height;
    int channels = input->channels;
    int half_kernel = kernel_size / 2;

    // Set number of threads
    omp_set_num_threads(config->num_threads);

    // Determine scheduling type
    if (config->loop_order == 0) {
        // Y-first loop order
        if (strcmp(config->schedule_type, "static") == 0) {
            #pragma omp parallel for schedule(static, config->chunk_size) collapse(1)
            for (int y = 0; y < height; y++) {
                for (int x = 0; x < width; x++) {
                    for (int c = 0; c < channels; c++) {
                        float sum = 0.0f;

                        for (int ky = 0; ky < kernel_size; ky++) {
                            for (int kx = 0; kx < kernel_size; kx++) {
                                int img_y = y + ky - half_kernel;
                                int img_x = x + kx - half_kernel;

                                if (img_y >= 0 && img_y < height && img_x >= 0 && img_x < width) {
                                    int idx = (img_y * width + img_x) * channels + c;
                                    sum += input->data[idx] * kernel[ky][kx];
                                }
                            }
                        }

                        int out_idx = (y * width + x) * channels + c;
                        output->data[out_idx] = (uint8_t)fmin(fmax(sum, 0.0f), 255.0f);
                    }
                }
            }
        } else if (strcmp(config->schedule_type, "dynamic") == 0) {
            #pragma omp parallel for schedule(dynamic, config->chunk_size) collapse(1)
            for (int y = 0; y < height; y++) {
                for (int x = 0; x < width; x++) {
                    for (int c = 0; c < channels; c++) {
                        float sum = 0.0f;

                        for (int ky = 0; ky < kernel_size; ky++) {
                            for (int kx = 0; kx < kernel_size; kx++) {
                                int img_y = y + ky - half_kernel;
                                int img_x = x + kx - half_kernel;

                                if (img_y >= 0 && img_y < height && img_x >= 0 && img_x < width) {
                                    int idx = (img_y * width + img_x) * channels + c;
                                    sum += input->data[idx] * kernel[ky][kx];
                                }
                            }
                        }

                        int out_idx = (y * width + x) * channels + c;
                        output->data[out_idx] = (uint8_t)fmin(fmax(sum, 0.0f), 255.0f);
                    }
                }
            }
        } else if (strcmp(config->schedule_type, "guided") == 0) {
            #pragma omp parallel for schedule(guided, config->chunk_size) collapse(1)
            for (int y = 0; y < height; y++) {
                for (int x = 0; x < width; x++) {
                    for (int c = 0; c < channels; c++) {
                        float sum = 0.0f;

                        for (int ky = 0; ky < kernel_size; ky++) {
                            for (int kx = 0; kx < kernel_size; kx++) {
                                int img_y = y + ky - half_kernel;
                                int img_x = x + kx - half_kernel;

                                if (img_y >= 0 && img_y < height && img_x >= 0 && img_x < width) {
                                    int idx = (img_y * width + img_x) * channels + c;
                                    sum += input->data[idx] * kernel[ky][kx];
                                }
                            }
                        }

                        int out_idx = (y * width + x) * channels + c;
                        output->data[out_idx] = (uint8_t)fmin(fmax(sum, 0.0f), 255.0f);
                    }
                }
            }
        }
    } else {
        // X-first loop order
        if (strcmp(config->schedule_type, "static") == 0) {
            #pragma omp parallel for schedule(static, config->chunk_size) collapse(1)
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    for (int c = 0; c < channels; c++) {
                        float sum = 0.0f;

                        for (int ky = 0; ky < kernel_size; ky++) {
                            for (int kx = 0; kx < kernel_size; kx++) {
                                int img_y = y + ky - half_kernel;
                                int img_x = x + kx - half_kernel;

                                if (img_y >= 0 && img_y < height && img_x >= 0 && img_x < width) {
                                    int idx = (img_y * width + img_x) * channels + c;
                                    sum += input->data[idx] * kernel[ky][kx];
                                }
                            }
                        }

                        int out_idx = (y * width + x) * channels + c;
                        output->data[out_idx] = (uint8_t)fmin(fmax(sum, 0.0f), 255.0f);
                    }
                }
            }
        } else if (strcmp(config->schedule_type, "dynamic") == 0) {
            #pragma omp parallel for schedule(dynamic, config->chunk_size) collapse(1)
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    for (int c = 0; c < channels; c++) {
                        float sum = 0.0f;

                        for (int ky = 0; ky < kernel_size; ky++) {
                            for (int kx = 0; kx < kernel_size; kx++) {
                                int img_y = y + ky - half_kernel;
                                int img_x = x + kx - half_kernel;

                                if (img_y >= 0 && img_y < height && img_x >= 0 && img_x < width) {
                                    int idx = (img_y * width + img_x) * channels + c;
                                    sum += input->data[idx] * kernel[ky][kx];
                                }
                            }
                        }

                        int out_idx = (y * width + x) * channels + c;
                        output->data[out_idx] = (uint8_t)fmin(fmax(sum, 0.0f), 255.0f);
                    }
                }
            }
        } else if (strcmp(config->schedule_type, "guided") == 0) {
            #pragma omp parallel for schedule(guided, config->chunk_size) collapse(1)
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    for (int c = 0; c < channels; c++) {
                        float sum = 0.0f;

                        for (int ky = 0; ky < kernel_size; ky++) {
                            for (int kx = 0; kx < kernel_size; kx++) {
                                int img_y = y + ky - half_kernel;
                                int img_x = x + kx - half_kernel;

                                if (img_y >= 0 && img_y < height && img_x >= 0 && img_x < width) {
                                    int idx = (img_y * width + img_x) * channels + c;
                                    sum += input->data[idx] * kernel[ky][kx];
                                }
                            }
                        }

                        int out_idx = (y * width + x) * channels + c;
                        output->data[out_idx] = (uint8_t)fmin(fmax(sum, 0.0f), 255.0f);
                    }
                }
            }
        }
    }
}

// OpenMP parallel convolution with tiling
void convolve_openmp_tiled(Image* input, Image* output, float** kernel, int kernel_size, ConvConfig* config) {
    int width = input->width;
    int height = input->height;
    int channels = input->channels;
    int half_kernel = kernel_size / 2;
    int tile_size = config->tile_size;

    omp_set_num_threads(config->num_threads);

    int num_tiles_y = (height + tile_size - 1) / tile_size;
    int num_tiles_x = (width + tile_size - 1) / tile_size;

    if (strcmp(config->schedule_type, "static") == 0) {
        #pragma omp parallel for schedule(static, config->chunk_size) collapse(2)
        for (int ty = 0; ty < num_tiles_y; ty++) {
            for (int tx = 0; tx < num_tiles_x; tx++) {
                int y_start = ty * tile_size;
                int y_end = (y_start + tile_size < height) ? y_start + tile_size : height;
                int x_start = tx * tile_size;
                int x_end = (x_start + tile_size < width) ? x_start + tile_size : width;

                for (int y = y_start; y < y_end; y++) {
                    for (int x = x_start; x < x_end; x++) {
                        for (int c = 0; c < channels; c++) {
                            float sum = 0.0f;

                            for (int ky = 0; ky < kernel_size; ky++) {
                                for (int kx = 0; kx < kernel_size; kx++) {
                                    int img_y = y + ky - half_kernel;
                                    int img_x = x + kx - half_kernel;

                                    if (img_y >= 0 && img_y < height && img_x >= 0 && img_x < width) {
                                        int idx = (img_y * width + img_x) * channels + c;
                                        sum += input->data[idx] * kernel[ky][kx];
                                    }
                                }
                            }

                            int out_idx = (y * width + x) * channels + c;
                            output->data[out_idx] = (uint8_t)fmin(fmax(sum, 0.0f), 255.0f);
                        }
                    }
                }
            }
        }
    } else if (strcmp(config->schedule_type, "dynamic") == 0) {
        #pragma omp parallel for schedule(dynamic, config->chunk_size) collapse(2)
        for (int ty = 0; ty < num_tiles_y; ty++) {
            for (int tx = 0; tx < num_tiles_x; tx++) {
                int y_start = ty * tile_size;
                int y_end = (y_start + tile_size < height) ? y_start + tile_size : height;
                int x_start = tx * tile_size;
                int x_end = (x_start + tile_size < width) ? x_start + tile_size : width;

                for (int y = y_start; y < y_end; y++) {
                    for (int x = x_start; x < x_end; x++) {
                        for (int c = 0; c < channels; c++) {
                            float sum = 0.0f;

                            for (int ky = 0; ky < kernel_size; ky++) {
                                for (int kx = 0; kx < kernel_size; kx++) {
                                    int img_y = y + ky - half_kernel;
                                    int img_x = x + kx - half_kernel;

                                    if (img_y >= 0 && img_y < height && img_x >= 0 && img_x < width) {
                                        int idx = (img_y * width + img_x) * channels + c;
                                        sum += input->data[idx] * kernel[ky][kx];
                                    }
                                }
                            }

                            int out_idx = (y * width + x) * channels + c;
                            output->data[out_idx] = (uint8_t)fmin(fmax(sum, 0.0f), 255.0f);
                        }
                    }
                }
            }
        }
    } else if (strcmp(config->schedule_type, "guided") == 0) {
        #pragma omp parallel for schedule(guided, config->chunk_size) collapse(2)
        for (int ty = 0; ty < num_tiles_y; ty++) {
            for (int tx = 0; tx < num_tiles_x; tx++) {
                int y_start = ty * tile_size;
                int y_end = (y_start + tile_size < height) ? y_start + tile_size : height;
                int x_start = tx * tile_size;
                int x_end = (x_start + tile_size < width) ? x_start + tile_size : width;

                for (int y = y_start; y < y_end; y++) {
                    for (int x = x_start; x < x_end; x++) {
                        for (int c = 0; c < channels; c++) {
                            float sum = 0.0f;

                            for (int ky = 0; ky < kernel_size; ky++) {
                                for (int kx = 0; kx < kernel_size; kx++) {
                                    int img_y = y + ky - half_kernel;
                                    int img_x = x + kx - half_kernel;

                                    if (img_y >= 0 && img_y < height && img_x >= 0 && img_x < width) {
                                        int idx = (img_y * width + img_x) * channels + c;
                                        sum += input->data[idx] * kernel[ky][kx];
                                    }
                                }
                            }

                            int out_idx = (y * width + x) * channels + c;
                            output->data[out_idx] = (uint8_t)fmin(fmax(sum, 0.0f), 255.0f);
                        }
                    }
                }
            }
        }
    }
}
