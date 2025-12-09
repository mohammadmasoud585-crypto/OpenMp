# PowerShell Quick Test Script
# Verifies that the OpenMP convolution program works correctly

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "OpenMP Convolution - Quick Test" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if build exists
$exe = "bin/convolution.exe"
if (-not (Test-Path $exe)) {
    Write-Host "Building project..." -ForegroundColor Yellow
    make clean
    make
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Build successful!" -ForegroundColor Green
    Write-Host ""
}

# Generate test image if needed
if (-not (Test-Path "images/input_small.png")) {
    Write-Host "Generating test images..." -ForegroundColor Yellow
    if (Get-Command python -ErrorAction SilentlyContinue) {
        python scripts/generate_test_images.py
    } elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
        python3 scripts/generate_test_images.py
    } else {
        Write-Host "WARNING: Python not found. Please create test images manually." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

# Create results directory if needed
if (-not (Test-Path "results")) {
    New-Item -ItemType Directory -Path "results" | Out-Null
}

$testsPassed = 0
$testsFailed = 0

# Test 1: Sequential
Write-Host "Test 1: Sequential (baseline)" -ForegroundColor Yellow
Write-Host "------------------------------" -ForegroundColor Yellow
& $exe -i images/input_small.png -o results/test_seq.png -k 3 -S
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Sequential test passed" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ Sequential test failed" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 2: OpenMP with 2 threads
Write-Host "Test 2: OpenMP (2 threads, static)" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Yellow
& $exe -i images/input_small.png -o results/test_omp_2.png -k 3 -t 2 -s static
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ OpenMP test passed" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ OpenMP test failed" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 3: OpenMP with 4 threads
Write-Host "Test 3: OpenMP (4 threads, dynamic)" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Yellow
& $exe -i images/input_small.png -o results/test_omp_4.png -k 3 -t 4 -s dynamic
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ OpenMP test passed" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ OpenMP test failed" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 4: Large kernel
Write-Host "Test 4: Large kernel (31x31)" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Yellow
& $exe -i images/input_small.png -o results/test_k31.png -k 31 -t 4 -s static
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Large kernel test passed" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ Large kernel test failed" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 5: Tiling
Write-Host "Test 5: Tiling (16x16)" -ForegroundColor Yellow
Write-Host "----------------------" -ForegroundColor Yellow
& $exe -i images/input_small.png -o results/test_tiled.png -k 31 -t 4 -T 16
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Tiling test passed" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ Tiling test failed" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Test Summary:" -ForegroundColor Cyan
Write-Host "  Passed: $testsPassed" -ForegroundColor Green
Write-Host "  Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Check results/ directory for output images" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

if ($testsFailed -gt 0) {
    exit 1
}
