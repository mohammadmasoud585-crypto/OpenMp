#!/bin/bash

################################################################################
# Simple Complete Benchmark - OpenMP 2D Convolution
# یک دستور - همه تست‌ها
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           OpenMP Benchmark - Complete Tests               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Go to project root
cd "$(dirname "$0")/.."

# Create results directory
mkdir -p results/data results/images

START_TIME=$(date +%s)

################################################################################
# Test 1: Thread Scaling (kernel 3x3)
################################################################################
echo -e "${YELLOW}[1/4] Thread Scaling Test (k=3)...${NC}"
echo "Threads,Time,Speedup" > results/data/thread_scaling_k3.csv

# Baseline
echo "  Measuring baseline (1 thread)..."
baseline=$(./bin/convolution -i images/input.png -o results/images/baseline_k3.png -k 3 -t 1 2>&1 | grep "Parallel time:" | awk '{print $3}')
echo "1,$baseline,1.00" >> results/data/thread_scaling_k3.csv

# Test with different threads
for t in 2 4 8; do
  echo "  Testing $t threads..."
  time=$(./bin/convolution -i images/input.png -o results/images/scaling_k3_t${t}.png -k 3 -t $t 2>&1 | grep "Parallel time:" | awk '{print $3}')
  speedup=$(echo "scale=2; $baseline / $time" | bc)
  echo "$t,$time,$speedup" >> results/data/thread_scaling_k3.csv
done

echo -e "${GREEN}✓ Thread scaling (k=3) completed${NC}"
echo ""

################################################################################
# Test 2: Thread Scaling (kernel 31x31)
################################################################################
echo -e "${YELLOW}[2/4] Thread Scaling Test (k=31)...${NC}"
echo "Threads,Time,Speedup" > results/data/thread_scaling_k31.csv

# Baseline
echo "  Measuring baseline (1 thread)..."
baseline31=$(./bin/convolution -i images/input.png -o results/images/baseline_k31.png -k 31 -t 1 2>&1 | grep "Parallel time:" | awk '{print $3}')
echo "1,$baseline31,1.00" >> results/data/thread_scaling_k31.csv

# Test with different threads
for t in 2 4 8; do
  echo "  Testing $t threads..."
  time=$(./bin/convolution -i images/input.png -o results/images/scaling_k31_t${t}.png -k 31 -t $t 2>&1 | grep "Parallel time:" | awk '{print $3}')
  speedup=$(echo "scale=2; $baseline31 / $time" | bc)
  echo "$t,$time,$speedup" >> results/data/thread_scaling_k31.csv
done

echo -e "${GREEN}✓ Thread scaling (k=31) completed${NC}"
echo ""

################################################################################
# Test 3: Scheduler Comparison (k=3, 4 threads)
################################################################################
echo -e "${YELLOW}[3/4] Scheduler Comparison Test...${NC}"
echo "Scheduler,Time" > results/data/scheduler_comparison.csv

for sched in static dynamic guided; do
  echo "  Testing scheduler: $sched..."
  time=$(./bin/convolution -i images/input.png -o results/images/sched_${sched}.png -k 3 -t 4 --schedule $sched 2>&1 | grep "Parallel time:" | awk '{print $3}')
  echo "$sched,$time" >> results/data/scheduler_comparison.csv
done

echo -e "${GREEN}✓ Scheduler comparison completed${NC}"
echo ""

################################################################################
# Test 4: Kernel Size Comparison (4 threads)
################################################################################
echo -e "${YELLOW}[4/4] Kernel Size Comparison...${NC}"
echo "KernelSize,Time" > results/data/kernel_comparison.csv

for k in 3 5 7 11 15 21 31; do
  echo "  Testing kernel size: ${k}x${k}..."
  time=$(./bin/convolution -i images/input.png -o results/images/kernel_${k}.png -k $k -t 4 2>&1 | grep "Parallel time:" | awk '{print $3}')
  echo "$k,$time" >> results/data/kernel_comparison.csv
done

echo -e "${GREEN}✓ Kernel size comparison completed${NC}"
echo ""

################################################################################
# Generate Summary Report
################################################################################
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

REPORT="results/BENCHMARK_REPORT.txt"

cat > "$REPORT" << EOF
╔════════════════════════════════════════════════════════════╗
║          OpenMP 2D Convolution - Benchmark Report         ║
╚════════════════════════════════════════════════════════════╝

Date: $(date '+%Y-%m-%d %H:%M:%S')
Duration: ${MINUTES}m ${SECONDS}s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 THREAD SCALING (Kernel 3x3):

EOF

column -t -s',' results/data/thread_scaling_k3.csv >> "$REPORT"

cat >> "$REPORT" << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 THREAD SCALING (Kernel 31x31):

EOF

column -t -s',' results/data/thread_scaling_k31.csv >> "$REPORT"

cat >> "$REPORT" << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚙️ SCHEDULER COMPARISON (4 threads, kernel 3x3):

EOF

column -t -s',' results/data/scheduler_comparison.csv >> "$REPORT"

cat >> "$REPORT" << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 KERNEL SIZE COMPARISON (4 threads):

EOF

column -t -s',' results/data/kernel_comparison.csv >> "$REPORT"

cat >> "$REPORT" << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Files Generated:
  • CSV Data: results/data/*.csv
  • Images: results/images/*.png
  • Report: results/BENCHMARK_REPORT.txt

✅ All benchmarks completed successfully!
EOF

################################################################################
# Display Results
################################################################################
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    ✅ ALL DONE!                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Total time: ${MINUTES}m ${SECONDS}s${NC}"
echo ""
echo "📊 Results saved to:"
echo "  • results/data/thread_scaling_k3.csv"
echo "  • results/data/thread_scaling_k31.csv"
echo "  • results/data/scheduler_comparison.csv"
echo "  • results/data/kernel_comparison.csv"
echo ""
echo "📝 Report:"
echo "  • results/BENCHMARK_REPORT.txt"
echo ""
echo "To view report:"
echo "  cat results/BENCHMARK_REPORT.txt"
echo ""

# Display report
cat "$REPORT"

exit 0
