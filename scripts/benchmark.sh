#!/bin/bash
# Comprehensive benchmark script for OpenMP 2D Convolution
# This script runs various configurations and collects performance data

# Configuration
IMAGE="images/input.png"
KERNEL_SIZES=(3 31)
THREAD_COUNTS=(1 2 4 8)
SCHEDULERS=("static" "dynamic" "guided")
TILE_SIZES=(0 8 16)
LOOP_ORDERS=(0 1)
CHUNK_SIZE=1

RESULTS_DIR="results"
PERF_DIR="$RESULTS_DIR/perf_data"
CSV_FILE="$RESULTS_DIR/benchmark_results.csv"

# Create directories
mkdir -p "$RESULTS_DIR"
mkdir -p "$PERF_DIR"

# Build the project
echo "Building project..."
make clean
make all

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"
echo ""

# Initialize CSV file
echo "Test_ID,Kernel_Size,Threads,Scheduler,Chunk,Tile_Size,Loop_Order,Execution_Time,CPU_Cycles,Instructions,IPC,Cache_Misses,L1_Misses" > "$CSV_FILE"

TEST_ID=0

# Function to run a single test
run_test() {
    local kernel=$1
    local threads=$2
    local scheduler=$3
    local tile=$4
    local loop_order=$5
    local output_name=$6
    
    TEST_ID=$((TEST_ID + 1))
    
    echo "========================================"
    echo "Test $TEST_ID: k=$kernel t=$threads s=$scheduler T=$tile l=$loop_order"
    echo "========================================"
    
    OUTPUT_FILE="$RESULTS_DIR/$output_name"
    PERF_FILE="$PERF_DIR/${output_name%.png}.txt"
    
    # Run with perf (Linux) - Comment out on Windows
    # perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    #     -o "$PERF_FILE" \
    #     bin/convolution -i "$IMAGE" -o "$OUTPUT_FILE" \
    #     -k $kernel -t $threads -s $scheduler -c $CHUNK_SIZE -T $tile -l $loop_order
    
    # For Windows, run without perf and capture timing
    bin/convolution.exe -i "$IMAGE" -o "$OUTPUT_FILE" \
        -k $kernel -t $threads -s $scheduler -c $CHUNK_SIZE -T $tile -l $loop_order \
        > "$PERF_FILE" 2>&1
    
    # Extract timing from output (you'll need to parse the actual output)
    TIME=$(grep -oP "time: \K[0-9.]+" "$PERF_FILE" 2>/dev/null || echo "N/A")
    
    # On Linux, parse perf output
    # CYCLES=$(grep -oP "[\d,]+ cycles" "$PERF_FILE" | tr -d ',' | awk '{print $1}')
    # INSTRUCTIONS=$(grep -oP "[\d,]+ instructions" "$PERF_FILE" | tr -d ',' | awk '{print $1}')
    # etc...
    
    # For now, write placeholder data
    echo "$TEST_ID,$kernel,$threads,$scheduler,$CHUNK_SIZE,$tile,$loop_order,$TIME,N/A,N/A,N/A,N/A,N/A" >> "$CSV_FILE"
    
    echo ""
}

# Benchmark 1: Thread scaling (kernel 3x3, static scheduler)
echo "=== Benchmark 1: Thread Scaling ==="
for threads in "${THREAD_COUNTS[@]}"; do
    run_test 3 $threads "static" 0 0 "bench1_threads_${threads}.png"
done

# Benchmark 2: Scheduler comparison (4 threads, kernel 3x3)
echo "=== Benchmark 2: Scheduler Comparison ==="
for scheduler in "${SCHEDULERS[@]}"; do
    run_test 3 4 "$scheduler" 0 0 "bench2_scheduler_${scheduler}.png"
done

# Benchmark 3: Kernel size comparison (4 threads, static)
echo "=== Benchmark 3: Kernel Size Comparison ==="
for kernel in "${KERNEL_SIZES[@]}"; do
    run_test $kernel 4 "static" 0 0 "bench3_kernel_${kernel}.png"
done

# Benchmark 4: Tiling strategies (kernel 31x31, 4 threads, static)
echo "=== Benchmark 4: Tiling Strategies ==="
for tile in "${TILE_SIZES[@]}"; do
    run_test 31 4 "static" $tile 0 "bench4_tile_${tile}.png"
done

# Benchmark 5: Loop ordering (kernel 3x3, 4 threads, static)
echo "=== Benchmark 5: Loop Ordering ==="
for order in "${LOOP_ORDERS[@]}"; do
    run_test 3 4 "static" 0 $order "bench5_order_${order}.png"
done

# Benchmark 6: Combined optimization (best settings)
echo "=== Benchmark 6: Best Configuration Test ==="
for kernel in "${KERNEL_SIZES[@]}"; do
    for threads in 4 8; do
        for scheduler in "static" "guided"; do
            if [ $kernel -eq 31 ]; then
                # Use tiling for larger kernel
                run_test $kernel $threads "$scheduler" 16 0 "bench6_best_k${kernel}_t${threads}_${scheduler}.png"
            else
                # No tiling for small kernel
                run_test $kernel $threads "$scheduler" 0 0 "bench6_best_k${kernel}_t${threads}_${scheduler}.png"
            fi
        done
    done
done

echo "========================================"
echo "All benchmarks completed!"
echo "Results saved to: $CSV_FILE"
echo "Performance data in: $PERF_DIR"
echo "========================================"
