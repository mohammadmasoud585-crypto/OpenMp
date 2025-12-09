#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include "convolution.h"

void print_usage(const char* prog_name) {
    printf("Usage: %s [options]\n", prog_name);
    printf("Options:\n");
    printf("  -i <input>        Input image file (required)\n");
    printf("  -o <output>       Output image file (required)\n");
    printf("  -k <size>         Kernel size (3 or 31, default: 3)\n");
    printf("  -t <threads>      Number of threads (default: 4)\n");
    printf("  -s <schedule>     Schedule type: static, dynamic, guided (default: static)\n");
    printf("  -c <chunk>        Chunk size (default: 1)\n");
    printf("  -l <order>        Loop order: 0=Y-first, 1=X-first (default: 0)\n");
    printf("  -T <tile>         Tile size: 0=no tiling, 8, 16 (default: 0)\n");
    printf("  -f <filter>       Filter type: gaussian, box (default: gaussian)\n");
    printf("  -S                Run sequential (baseline) version\n");
    printf("  -h                Show this help message\n");
}

int main(int argc, char** argv) {
    // Default parameters
    char* input_file = NULL;
    char* output_file = NULL;
    int kernel_size = 3;
    int sequential = 0;
    char filter_type[16] = "gaussian";
    
    ConvConfig config = {
        .num_threads = 4,
        .schedule_type = "static",
        .chunk_size = 1,
        .tile_size = 0,
        .loop_order = 0
    };

    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-i") == 0 && i + 1 < argc) {
            input_file = argv[++i];
        } else if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
            output_file = argv[++i];
        } else if (strcmp(argv[i], "-k") == 0 && i + 1 < argc) {
            kernel_size = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-t") == 0 && i + 1 < argc) {
            config.num_threads = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-s") == 0 && i + 1 < argc) {
            strncpy(config.schedule_type, argv[++i], sizeof(config.schedule_type) - 1);
        } else if (strcmp(argv[i], "-c") == 0 && i + 1 < argc) {
            config.chunk_size = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-l") == 0 && i + 1 < argc) {
            config.loop_order = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-T") == 0 && i + 1 < argc) {
            config.tile_size = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-f") == 0 && i + 1 < argc) {
            strncpy(filter_type, argv[++i], sizeof(filter_type) - 1);
        } else if (strcmp(argv[i], "-S") == 0) {
            sequential = 1;
        } else if (strcmp(argv[i], "-h") == 0) {
            print_usage(argv[0]);
            return 0;
        }
    }

    // Validate required arguments
    if (!input_file || !output_file) {
        fprintf(stderr, "Error: Input and output files are required\n");
        print_usage(argv[0]);
        return 1;
    }

    // Validate kernel size
    if (kernel_size != 3 && kernel_size != 31) {
        fprintf(stderr, "Error: Kernel size must be 3 or 31\n");
        return 1;
    }

    printf("=== 2D Convolution with OpenMP ===\n\n");

    // Load input image
    printf("Loading input image...\n");
    Image* input = load_image(input_file);
    if (!input) {
        fprintf(stderr, "Failed to load input image\n");
        return 1;
    }

    // Create output image
    Image* output = create_image(input->width, input->height, input->channels);
    if (!output) {
        fprintf(stderr, "Failed to create output image\n");
        free_image(input);
        return 1;
    }

    // Create kernel
    printf("Creating %dx%d %s kernel...\n", kernel_size, kernel_size, filter_type);
    float** kernel;
    if (strcmp(filter_type, "gaussian") == 0) {
        float sigma = kernel_size / 6.0f;
        kernel = create_gaussian_kernel(kernel_size, sigma);
    } else if (strcmp(filter_type, "box") == 0) {
        kernel = create_box_kernel(kernel_size);
    } else {
        fprintf(stderr, "Unknown filter type: %s\n", filter_type);
        free_image(input);
        free_image(output);
        return 1;
    }

    if (!kernel) {
        fprintf(stderr, "Failed to create kernel\n");
        free_image(input);
        free_image(output);
        return 1;
    }

    // Print kernel (only for small kernels)
    if (kernel_size <= 5) {
        print_kernel(kernel, kernel_size);
    }

    // Perform convolution
    double start_time, end_time;

    if (sequential) {
        printf("\nRunning sequential convolution...\n");
        start_time = get_time();
        convolve_sequential(input, output, kernel, kernel_size);
        end_time = get_time();
        printf("Sequential time: %.6f seconds\n", end_time - start_time);
    } else {
        printf("\nRunning OpenMP parallel convolution...\n");
        print_config(&config);
        printf("\n");

        start_time = get_time();
        if (config.tile_size > 0) {
            convolve_openmp_tiled(input, output, kernel, kernel_size, &config);
        } else {
            convolve_openmp(input, output, kernel, kernel_size, &config);
        }
        end_time = get_time();

        double elapsed = end_time - start_time;
        printf("Parallel time: %.6f seconds\n", elapsed);
        
        // Calculate theoretical speedup info
        printf("Threads used: %d\n", config.num_threads);
    }

    // Save output image
    printf("\nSaving output image...\n");
    if (!save_image(output_file, output)) {
        fprintf(stderr, "Failed to save output image\n");
        free_kernel(kernel, kernel_size);
        free_image(input);
        free_image(output);
        return 1;
    }

    // Cleanup
    free_kernel(kernel, kernel_size);
    free_image(input);
    free_image(output);

    printf("\nConvolution completed successfully!\n");
    return 0;
}
