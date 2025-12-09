# PowerShell benchmark script for Windows
# Comprehensive benchmark for OpenMP 2D Convolution

# Configuration
$IMAGE = "images/input.png"
$KERNEL_SIZES = @(3, 31)
$THREAD_COUNTS = @(1, 2, 4, 8)
$SCHEDULERS = @("static", "dynamic", "guided")
$TILE_SIZES = @(0, 8, 16)
$LOOP_ORDERS = @(0, 1)
$CHUNK_SIZE = 1

$RESULTS_DIR = "results"
$PERF_DIR = "$RESULTS_DIR/perf_data"
$CSV_FILE = "$RESULTS_DIR/benchmark_results.csv"

# Create directories
New-Item -ItemType Directory -Force -Path $RESULTS_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $PERF_DIR | Out-Null

# Build the project
Write-Host "Building project..." -ForegroundColor Cyan
make clean
make all

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!`n" -ForegroundColor Green

# Initialize CSV file
"Test_ID,Kernel_Size,Threads,Scheduler,Chunk,Tile_Size,Loop_Order,Execution_Time,Speedup" | Out-File -FilePath $CSV_FILE -Encoding UTF8

$TEST_ID = 0
$BASELINE_TIME = 0

# Function to run a single test
function Run-Test {
    param(
        [int]$kernel,
        [int]$threads,
        [string]$scheduler,
        [int]$tile,
        [int]$loop_order,
        [string]$output_name,
        [switch]$is_baseline
    )
    
    $script:TEST_ID++
    
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Test $script:TEST_ID: k=$kernel t=$threads s=$scheduler T=$tile l=$loop_order" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    $OUTPUT_FILE = "$RESULTS_DIR/$output_name"
    $PERF_FILE = "$PERF_DIR/$($output_name -replace '\.png$', '.txt')"
    
    # Run the convolution
    $output = & bin/convolution.exe -i $IMAGE -o $OUTPUT_FILE `
        -k $kernel -t $threads -s $scheduler -c $CHUNK_SIZE -T $tile -l $loop_order 2>&1
    
    # Save output to file
    $output | Out-File -FilePath $PERF_FILE -Encoding UTF8
    
    # Extract timing
    $time_line = $output | Select-String "time: ([\d.]+)" 
    if ($time_line) {
        $TIME = [double]($time_line.Matches.Groups[1].Value)
    } else {
        # Try alternate pattern
        $time_line = $output | Select-String "([\d.]+) seconds"
        if ($time_line) {
            $TIME = [double]($time_line.Matches.Groups[1].Value)
        } else {
            $TIME = 0
        }
    }
    
    Write-Host "Execution time: $TIME seconds" -ForegroundColor Green
    
    # Calculate speedup
    $SPEEDUP = "N/A"
    if ($is_baseline) {
        $script:BASELINE_TIME = $TIME
        $SPEEDUP = "1.00"
    } elseif ($script:BASELINE_TIME -gt 0 -and $TIME -gt 0) {
        $SPEEDUP = [math]::Round($script:BASELINE_TIME / $TIME, 2)
    }
    
    # Append to CSV
    "$script:TEST_ID,$kernel,$threads,$scheduler,$CHUNK_SIZE,$tile,$loop_order,$TIME,$SPEEDUP" | 
        Out-File -FilePath $CSV_FILE -Append -Encoding UTF8
    
    Write-Host ""
}

# Benchmark 0: Sequential baseline
Write-Host "=== Benchmark 0: Sequential Baseline ===" -ForegroundColor Cyan
$OUTPUT_FILE = "$RESULTS_DIR/baseline_sequential.png"
$PERF_FILE = "$PERF_DIR/baseline_sequential.txt"
$output = & bin/convolution.exe -i $IMAGE -o $OUTPUT_FILE -k 3 -S 2>&1
$output | Out-File -FilePath $PERF_FILE -Encoding UTF8
$time_line = $output | Select-String "([\d.]+) seconds"
if ($time_line) {
    $BASELINE_TIME = [double]($time_line.Matches.Groups[1].Value)
    Write-Host "Baseline time: $BASELINE_TIME seconds" -ForegroundColor Green
} else {
    $BASELINE_TIME = 0
    Write-Host "Could not extract baseline time" -ForegroundColor Red
}
Write-Host ""

# Benchmark 1: Thread scaling (kernel 3x3, static scheduler)
Write-Host "=== Benchmark 1: Thread Scaling ===" -ForegroundColor Cyan
foreach ($threads in $THREAD_COUNTS) {
    Run-Test -kernel 3 -threads $threads -scheduler "static" -tile 0 -loop_order 0 `
        -output_name "bench1_threads_$threads.png"
}

# Benchmark 2: Scheduler comparison (4 threads, kernel 3x3)
Write-Host "=== Benchmark 2: Scheduler Comparison ===" -ForegroundColor Cyan
foreach ($scheduler in $SCHEDULERS) {
    Run-Test -kernel 3 -threads 4 -scheduler $scheduler -tile 0 -loop_order 0 `
        -output_name "bench2_scheduler_$scheduler.png"
}

# Benchmark 3: Kernel size comparison (4 threads, static)
Write-Host "=== Benchmark 3: Kernel Size Comparison ===" -ForegroundColor Cyan
foreach ($kernel in $KERNEL_SIZES) {
    Run-Test -kernel $kernel -threads 4 -scheduler "static" -tile 0 -loop_order 0 `
        -output_name "bench3_kernel_$kernel.png"
}

# Benchmark 4: Tiling strategies (kernel 31x31, 4 threads, static)
Write-Host "=== Benchmark 4: Tiling Strategies ===" -ForegroundColor Cyan
foreach ($tile in $TILE_SIZES) {
    Run-Test -kernel 31 -threads 4 -scheduler "static" -tile $tile -loop_order 0 `
        -output_name "bench4_tile_$tile.png"
}

# Benchmark 5: Loop ordering (kernel 3x3, 4 threads, static)
Write-Host "=== Benchmark 5: Loop Ordering ===" -ForegroundColor Cyan
foreach ($order in $LOOP_ORDERS) {
    Run-Test -kernel 3 -threads 4 -scheduler "static" -tile 0 -loop_order $order `
        -output_name "bench5_order_$order.png"
}

# Benchmark 6: Combined optimization tests
Write-Host "=== Benchmark 6: Best Configuration Tests ===" -ForegroundColor Cyan
foreach ($kernel in $KERNEL_SIZES) {
    foreach ($threads in @(4, 8)) {
        foreach ($scheduler in @("static", "guided")) {
            if ($kernel -eq 31) {
                # Use tiling for larger kernel
                Run-Test -kernel $kernel -threads $threads -scheduler $scheduler -tile 16 -loop_order 0 `
                    -output_name "bench6_best_k${kernel}_t${threads}_${scheduler}.png"
            } else {
                # No tiling for small kernel
                Run-Test -kernel $kernel -threads $threads -scheduler $scheduler -tile 0 -loop_order 0 `
                    -output_name "bench6_best_k${kernel}_t${threads}_${scheduler}.png"
            }
        }
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All benchmarks completed!" -ForegroundColor Green
Write-Host "Results saved to: $CSV_FILE" -ForegroundColor Green
Write-Host "Performance data in: $PERF_DIR" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Generate summary
Write-Host "`nGenerating summary..." -ForegroundColor Cyan
$results = Import-Csv $CSV_FILE
$summary = $results | Sort-Object -Property @{Expression={[double]$_.Execution_Time}} | Select-Object -First 10
Write-Host "`nTop 10 fastest configurations:" -ForegroundColor Green
$summary | Format-Table -AutoSize
