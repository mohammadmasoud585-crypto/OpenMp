#!/bin/bash
# Quick test script to verify the installation works

echo "======================================"
echo "OpenMP Convolution - Quick Test"
echo "======================================"
echo ""

# Check if build exists
if [ ! -f "bin/convolution" ] && [ ! -f "bin/convolution.exe" ]; then
    echo "Building project..."
    make clean
    make
    if [ $? -ne 0 ]; then
        echo "ERROR: Build failed!"
        exit 1
    fi
    echo "Build successful!"
    echo ""
fi

# Generate test image if needed
if [ ! -f "images/input_small.png" ]; then
    echo "Generating test images..."
    if command -v python3 &> /dev/null; then
        python3 scripts/generate_test_images.py
    elif command -v python &> /dev/null; then
        python scripts/generate_test_images.py
    else
        echo "WARNING: Python not found. Please create test images manually."
        exit 1
    fi
    echo ""
fi

# Detect executable name
if [ -f "bin/convolution.exe" ]; then
    EXE="bin/convolution.exe"
else
    EXE="bin/convolution"
fi

# Test 1: Sequential
echo "Test 1: Sequential (baseline)"
echo "------------------------------"
$EXE -i images/input_small.png -o results/test_seq.png -k 3 -S
if [ $? -eq 0 ]; then
    echo "✓ Sequential test passed"
else
    echo "✗ Sequential test failed"
fi
echo ""

# Test 2: OpenMP with 2 threads
echo "Test 2: OpenMP (2 threads, static)"
echo "-----------------------------------"
$EXE -i images/input_small.png -o results/test_omp_2.png -k 3 -t 2 -s static
if [ $? -eq 0 ]; then
    echo "✓ OpenMP test passed"
else
    echo "✗ OpenMP test failed"
fi
echo ""

# Test 3: OpenMP with 4 threads
echo "Test 3: OpenMP (4 threads, dynamic)"
echo "------------------------------------"
$EXE -i images/input_small.png -o results/test_omp_4.png -k 3 -t 4 -s dynamic
if [ $? -eq 0 ]; then
    echo "✓ OpenMP test passed"
else
    echo "✗ OpenMP test failed"
fi
echo ""

# Test 4: Large kernel
echo "Test 4: Large kernel (31x31)"
echo "----------------------------"
$EXE -i images/input_small.png -o results/test_k31.png -k 31 -t 4 -s static
if [ $? -eq 0 ]; then
    echo "✓ Large kernel test passed"
else
    echo "✗ Large kernel test failed"
fi
echo ""

# Test 5: Tiling
echo "Test 5: Tiling (16x16)"
echo "----------------------"
$EXE -i images/input_small.png -o results/test_tiled.png -k 31 -t 4 -T 16
if [ $? -eq 0 ]; then
    echo "✓ Tiling test passed"
else
    echo "✗ Tiling test failed"
fi
echo ""

echo "======================================"
echo "All tests completed!"
echo "Check results/ directory for output images"
echo "======================================"
