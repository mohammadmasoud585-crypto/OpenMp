# OpenMP 2D Image Convolution

This project implements parallel 2D image convolution using OpenMP directives. It explores various parallelization strategies including different scheduling policies, thread counts, loop orderings, and tiling approaches.

## Project Structure

```
OpenMp/
├── src/
│   ├── main.c              # Main program entry point
│   ├── convolution.c       # Convolution implementations
│   └── image_utils.c       # Image I/O and utility functions
├── include/
│   ├── convolution.h       # Header file for convolution functions
│   ├── stb_image.h         # STB image loading library
│   └── stb_image_write.h   # STB image writing library
├── images/                 # Input images directory
├── results/                # Output images and benchmark results
├── scripts/
│   ├── benchmark.sh        # Linux benchmark script
│   └── benchmark.ps1       # Windows PowerShell benchmark script
├── Makefile               # Build automation
└── README.md              # This file
```

## Features

- **Multiple Scheduling Policies**: Static, Dynamic, and Guided
- **Configurable Thread Count**: Test with 1, 2, 4, 8 threads
- **Tiling Support**: 8x8 and 16x16 tile sizes for improved cache locality
- **Loop Ordering**: Y-first and X-first loop orderings
- **Multiple Kernel Sizes**: 3x3 and 31x31 convolution kernels
- **Filter Types**: Gaussian and Box (average) filters
- **Sequential Baseline**: For performance comparison

## Prerequisites

### Linux
- GCC with OpenMP support (`gcc` version 4.2 or later)
- Make
- `perf` tool for profiling (optional but recommended)

### Windows
- MinGW-w64 or TDM-GCC with OpenMP support
- Make (can use MinGW32-make)
- Windows Performance Toolkit (optional)

## Installation

1. Clone or download this repository
2. Navigate to the project directory
3. Place your input image in the `images/` directory

## Building the Project

### Standard Build (Optimized)
```bash
make
```

### Debug Build
```bash
make debug
```

### Build with Profiling Support (gprof)
```bash
make profile
```

### Clean Build Artifacts
```bash
make clean
```

### Clean All (including results)
```bash
make distclean
```

## Usage

### Basic Usage

```bash
./bin/convolution -i <input_image> -o <output_image> [options]
```

### Options

- `-i <file>` : Input image file (required)
- `-o <file>` : Output image file (required)
- `-k <size>` : Kernel size (3 or 31, default: 3)
- `-t <num>` : Number of threads (default: 4)
- `-s <type>` : Schedule type: static, dynamic, guided (default: static)
- `-c <size>` : Chunk size (default: 1)
- `-l <order>` : Loop order: 0=Y-first, 1=X-first (default: 0)
- `-T <size>` : Tile size: 0=no tiling, 8, 16 (default: 0)
- `-f <type>` : Filter type: gaussian, box (default: gaussian)
- `-S` : Run sequential (baseline) version
- `-h` : Show help message

### Example Commands

**Run sequential baseline:**
```bash
./bin/convolution -i images/input.png -o results/output_seq.png -k 3 -S
```

**Run with 4 threads, static scheduling:**
```bash
./bin/convolution -i images/input.png -o results/output.png -k 3 -t 4 -s static
```

**Run with 8 threads, dynamic scheduling, 31x31 kernel:**
```bash
./bin/convolution -i images/input.png -o results/output.png -k 31 -t 8 -s dynamic
```

**Run with tiling (16x16 tiles), 4 threads:**
```bash
./bin/convolution -i images/input.png -o results/output.png -k 31 -t 4 -T 16
```

## Running Benchmarks

### Using Makefile Targets

```bash
# Run all basic tests
make test

# Benchmark different thread counts
make bench-threads

# Benchmark different schedulers
make bench-schedulers

# Benchmark different kernel sizes
make bench-kernels

# Benchmark tiling strategies
make bench-tiling

# Benchmark loop orderings
make bench-loop-order

# Run all benchmarks
make bench-all
```

### Using Benchmark Scripts

**Linux:**
```bash
chmod +x scripts/benchmark.sh
./scripts/benchmark.sh
```

**Windows PowerShell:**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\benchmark.ps1
```

The benchmark scripts will:
1. Build the project
2. Run comprehensive tests with various configurations
3. Collect performance data
4. Save results to CSV file
5. Generate performance reports

## Profiling

### Using gprof

1. Build with profiling support:
```bash
make profile
```

2. Run the program:
```bash
./bin/convolution_prof -i images/input.png -o results/output.png -k 3 -t 4
```

3. Generate profile report:
```bash
gprof bin/convolution_prof gmon.out > results/profile.txt
```

### Using perf (Linux)

```bash
# Record performance events
perf record -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    ./bin/convolution -i images/input.png -o results/output.png -k 3 -t 4

# View report
perf report

# Get statistics
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    ./bin/convolution -i images/input.png -o results/output.png -k 3 -t 4
```

### Key Metrics to Analyze

1. **Execution Time**: Total wall-clock time
2. **CPU Cycles**: Number of CPU cycles consumed
3. **Instructions**: Number of instructions executed
4. **IPC (Instructions Per Cycle)**: Instructions / Cycles
5. **Cache Misses**: Total cache misses
6. **L1 Data Cache Misses**: L1 cache load misses
7. **Speedup**: Baseline time / Parallel time

## Performance Analysis Guide

### Thread Scaling Analysis

Test with different thread counts (1, 2, 4, 8) to measure:
- Scalability of the implementation
- Overhead of thread creation and synchronization
- Optimal thread count for your system

### Scheduler Comparison

Compare static, dynamic, and guided schedulers:
- **Static**: Fixed chunk assignment, low overhead, good for uniform workload
- **Dynamic**: Runtime chunk assignment, higher overhead, good for non-uniform workload
- **Guided**: Decreasing chunk sizes, balance between static and dynamic

### Tiling Strategy

Test different tile sizes (no tiling, 8x8, 16x16):
- Improved cache locality
- Reduced cache misses
- Trade-off between granularity and overhead

### Loop Ordering

Compare Y-first vs X-first:
- Memory access patterns
- Cache line utilization
- Spatial locality effects

## Expected Results

For a 2048x2048 image:

### Thread Scaling (3x3 kernel)
- 1 thread: Baseline
- 2 threads: ~1.8x speedup
- 4 threads: ~3.2x speedup
- 8 threads: ~5.5x speedup

### Scheduler Performance (4 threads, 3x3 kernel)
- Static: Best performance for uniform workload
- Dynamic: Slightly higher overhead
- Guided: Good balance for varying workload

### Tiling Benefits (31x31 kernel)
- No tiling: Baseline
- 8x8 tiles: 5-10% improvement
- 16x16 tiles: 10-20% improvement

## Troubleshooting

### Common Issues

**Error: "Failed to load image"**
- Ensure the image file exists
- Check file format (PNG, JPEG, BMP supported)
- Verify file path

**Slow Performance**
- Check if OpenMP is properly enabled (`-fopenmp` flag)
- Verify thread count matches CPU cores
- Test different scheduling policies

**Compilation Errors**
- Ensure GCC supports OpenMP (version 4.2+)
- Check that all source files are present
- Verify include paths are correct

### Performance Tips

1. Use static scheduling for uniform workloads
2. Enable tiling for large kernels (31x31)
3. Match thread count to physical cores
4. Use O3 optimization level
5. Test Y-first loop order for better cache locality

## Implementation Details

### Convolution Algorithm

The convolution operation is implemented as:

```
For each pixel (x, y) in the image:
    For each channel c:
        sum = 0
        For each kernel element (kx, ky):
            img_x = x + kx - kernel_center
            img_y = y + ky - kernel_center
            if valid_coordinates(img_x, img_y):
                sum += image[img_y][img_x][c] * kernel[ky][kx]
        output[y][x][c] = clamp(sum, 0, 255)
```

### Parallelization Strategy

- **Outer Loop Parallelization**: The outer loop (Y or X dimension) is parallelized
- **Work Distribution**: OpenMP automatically distributes iterations across threads
- **Synchronization**: Implicit barrier at the end of parallel region
- **Data Sharing**: Input image and kernel are shared, output is written without conflicts

### Memory Layout

- Images stored in row-major order: `data[y][x][channel]`
- Index calculation: `index = (y * width + x) * channels + c`
- Contiguous memory for cache-friendly access

## OpenMP vs pthreads Comparison

### Advantages of OpenMP

1. **Ease of Use**: Simple pragma directives vs explicit thread management
2. **Less Code**: Fewer lines of code, less error-prone
3. **Automatic Load Balancing**: Built-in scheduling policies
4. **Portability**: Works across different platforms
5. **Maintenance**: Easier to modify and maintain

### Advantages of pthreads

1. **Fine Control**: Explicit control over thread behavior
2. **Lower Overhead**: Potentially less runtime overhead
3. **Advanced Synchronization**: More synchronization primitives
4. **Custom Scheduling**: Implement custom work distribution

### Performance Comparison

Expected results (varies by system):
- Similar peak performance for both approaches
- OpenMP typically 2-5% overhead due to runtime
- pthreads requires more careful tuning
- OpenMP easier to optimize with different schedules

## References

- OpenMP API Specification: https://www.openmp.org/specifications/
- STB Image Libraries: https://github.com/nothings/stb
- Performance Analysis Tools: `perf`, `gprof`

## License

This project is for educational purposes as part of the Parallel Algorithms course.

## Authors

- Student Name: [Your Name]
- Student Number: [Your Student Number]
- Course: Parallel Algorithms
- Instructor: Prof. Farshad Khunjush
- Assignment: HW3 - OpenMP 2D Convolution
