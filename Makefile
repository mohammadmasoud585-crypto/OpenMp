# Compiler and flags
CC = gcc
CFLAGS = -Wall -O3 -fopenmp -I./include -lm
CFLAGS_DEBUG = -Wall -g -fopenmp -I./include -lm
CFLAGS_PROF = -Wall -O3 -fopenmp -pg -I./include -lm

# Directories
SRC_DIR = src
INC_DIR = include
OBJ_DIR = obj
BIN_DIR = bin
RESULTS_DIR = results

# Source files
SOURCES = $(SRC_DIR)/main.c $(SRC_DIR)/convolution.c $(SRC_DIR)/image_utils.c
OBJECTS = $(OBJ_DIR)/main.o $(OBJ_DIR)/convolution.o $(OBJ_DIR)/image_utils.o

# Target executable
TARGET = $(BIN_DIR)/convolution
TARGET_DEBUG = $(BIN_DIR)/convolution_debug
TARGET_PROF = $(BIN_DIR)/convolution_prof

# Default target
all: directories $(TARGET)

# Create necessary directories
directories:
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(RESULTS_DIR)

# Build optimized version
$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -o $(TARGET) $(CFLAGS)
	@echo Build complete: $(TARGET)

# Build debug version
debug: directories $(TARGET_DEBUG)

$(TARGET_DEBUG): $(SOURCES)
	$(CC) $(SOURCES) -o $(TARGET_DEBUG) $(CFLAGS_DEBUG)
	@echo Debug build complete: $(TARGET_DEBUG)

# Build with profiling support
profile: directories $(TARGET_PROF)

$(TARGET_PROF): $(SOURCES)
	$(CC) $(SOURCES) -o $(TARGET_PROF) $(CFLAGS_PROF)
	@echo Profile build complete: $(TARGET_PROF)

# Compile source files
$(OBJ_DIR)/main.o: $(SRC_DIR)/main.c $(INC_DIR)/convolution.h
	$(CC) -c $(SRC_DIR)/main.c -o $(OBJ_DIR)/main.o $(CFLAGS)

$(OBJ_DIR)/convolution.o: $(SRC_DIR)/convolution.c $(INC_DIR)/convolution.h
	$(CC) -c $(SRC_DIR)/convolution.c -o $(OBJ_DIR)/convolution.o $(CFLAGS)

$(OBJ_DIR)/image_utils.o: $(SRC_DIR)/image_utils.c $(INC_DIR)/convolution.h $(INC_DIR)/stb_image.h $(INC_DIR)/stb_image_write.h
	$(CC) -c $(SRC_DIR)/image_utils.c -o $(OBJ_DIR)/image_utils.o $(CFLAGS)

# Run tests with different configurations
test: $(TARGET)
	@echo Running convolution tests...
	@echo Test 1: Sequential baseline (kernel 3x3)
	$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_seq_k3.png -k 3 -S
	
	@echo Test 2: OpenMP static schedule (2 threads, kernel 3x3)
	$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_omp_static_t2_k3.png -k 3 -t 2 -s static -c 1
	
	@echo Test 3: OpenMP dynamic schedule (4 threads, kernel 3x3)
	$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_omp_dynamic_t4_k3.png -k 3 -t 4 -s dynamic -c 1
	
	@echo Test 4: OpenMP guided schedule (8 threads, kernel 3x3)
	$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_omp_guided_t8_k3.png -k 3 -t 8 -s guided -c 1
	
	@echo Test 5: Tiled convolution 8x8 (4 threads, kernel 31x31)
	$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_tiled_8x8_k31.png -k 31 -t 4 -s static -T 8
	
	@echo Test 6: Tiled convolution 16x16 (4 threads, kernel 31x31)
	$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_tiled_16x16_k31.png -k 31 -t 4 -s static -T 16

# Benchmark different thread counts
bench-threads: $(TARGET)
	@echo "Benchmarking different thread counts..."
	@for t in 1 2 4 8; do \
		echo "Testing with $$t threads..." ; \
		$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_t$$t.png -k 3 -t $$t -s static ; \
	done

# Benchmark different schedulers
bench-schedulers: $(TARGET)
	@echo "Benchmarking different schedulers..."
	@for s in static dynamic guided; do \
		echo "Testing $$s scheduler..." ; \
		$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_$$s.png -k 3 -t 4 -s $$s -c 1 ; \
	done

# Benchmark different kernel sizes
bench-kernels: $(TARGET)
	@echo "Benchmarking different kernel sizes..."
	@for k in 3 31; do \
		echo "Testing kernel size $$k..." ; \
		$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_k$$k.png -k $$k -t 4 -s static ; \
	done

# Benchmark tiling strategies
bench-tiling: $(TARGET)
	@echo "Benchmarking tiling strategies..."
	@echo "No tiling..."
	@$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_notile.png -k 31 -t 4 -s static -T 0
	@echo "Tiling 8x8..."
	@$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_tile8.png -k 31 -t 4 -s static -T 8
	@echo "Tiling 16x16..."
	@$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_tile16.png -k 31 -t 4 -s static -T 16

# Benchmark loop ordering
bench-loop-order: $(TARGET)
	@echo "Benchmarking loop orderings..."
	@echo "Y-first loop order..."
	@$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_loop_y.png -k 3 -t 4 -s static -l 0
	@echo "X-first loop order..."
	@$(TARGET) -i images/input.png -o $(RESULTS_DIR)/output_loop_x.png -k 3 -t 4 -s static -l 1

# Run comprehensive benchmarks
bench-all: bench-threads bench-schedulers bench-kernels bench-tiling bench-loop-order
	@echo All benchmarks completed!

# Clean build artifacts
clean:
	@rm -rf $(OBJ_DIR)
	@rm -rf $(BIN_DIR)
	@rm -f gmon.out
	@echo "Clean complete"

# Clean results
clean-results:
	@rm -f $(RESULTS_DIR)/*.png
	@rm -f $(RESULTS_DIR)/*.jpg
	@rm -f $(RESULTS_DIR)/*.txt
	@echo "Results cleaned"

# Full clean
distclean: clean clean-results
	@echo "Full clean complete"

# Help
help:
	@echo Available targets:
	@echo   all              - Build optimized version (default)
	@echo   debug            - Build debug version
	@echo   profile          - Build with profiling support
	@echo   test             - Run basic tests
	@echo   bench-threads    - Benchmark different thread counts
	@echo   bench-schedulers - Benchmark different schedulers
	@echo   bench-kernels    - Benchmark different kernel sizes
	@echo   bench-tiling     - Benchmark tiling strategies
	@echo   bench-loop-order - Benchmark loop orderings
	@echo   bench-all        - Run all benchmarks
	@echo   clean            - Remove build artifacts
	@echo   clean-results    - Remove result files
	@echo   distclean        - Full clean
	@echo   help             - Show this help message

.PHONY: all directories debug profile test bench-threads bench-schedulers bench-kernels bench-tiling bench-loop-order bench-all clean clean-results distclean help
