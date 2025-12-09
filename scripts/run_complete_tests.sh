#!/bin/bash
# اسکریپت تست کامل و جمع‌آوری نتایج برای گزارش
# OpenMP 2D Convolution - Complete Testing Script

set -e  # خروج در صورت خطا

# رنگ‌ها برای خروجی
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# تابع چاپ پیام
print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# بررسی وجود دایرکتوری‌ها
check_directories() {
    print_header "بررسی ساختار پروژه"
    
    if [ ! -d "src" ] || [ ! -d "include" ]; then
        print_error "پوشه‌های src یا include یافت نشد!"
        echo "لطفاً این اسکریپت را از ریشه پروژه اجرا کنید."
        exit 1
    fi
    
    print_success "ساختار پروژه صحیح است"
}

# پاکسازی و ایجاد دایرکتوری‌ها
setup_directories() {
    print_header "آماده‌سازی دایرکتوری‌ها"
    
    mkdir -p results/{perf_data,images,plots,data}
    mkdir -p images
    
    print_success "دایرکتوری‌ها آماده شدند"
}

# بررسی و نصب dependencies
check_dependencies() {
    print_header "بررسی ابزارهای مورد نیاز"
    
    # بررسی GCC
    if ! command -v gcc &> /dev/null; then
        print_error "GCC یافت نشد! لطفاً نصب کنید: sudo apt-get install build-essential"
        exit 1
    fi
    print_success "GCC: $(gcc --version | head -1)"
    
    # بررسی OpenMP
    if echo | gcc -fopenmp -E -dM - 2>/dev/null | grep -q "_OPENMP"; then
        print_success "OpenMP پشتیبانی می‌شود"
    else
        print_error "OpenMP پشتیبانی نمی‌شود!"
        exit 1
    fi
    
    # بررسی perf (اختیاری)
    if command -v perf &> /dev/null; then
        print_success "perf موجود است"
        HAS_PERF=1
    else
        print_info "perf یافت نشد (اختیاری، برای profiling دقیق‌تر)"
        print_info "نصب: sudo apt-get install linux-tools-generic"
        HAS_PERF=0
    fi
    
    # بررسی Python
    if command -v python3 &> /dev/null; then
        print_success "Python3: $(python3 --version)"
        HAS_PYTHON=1
    else
        print_info "Python3 یافت نشد (برای تولید تصاویر تست)"
        HAS_PYTHON=0
    fi
}

# کامپایل پروژه
compile_project() {
    print_header "کامپایل پروژه"
    
    make clean > /dev/null 2>&1 || true
    
    echo "در حال کامپایل..."
    if make > /dev/null 2>&1; then
        print_success "کامپایل موفقیت‌آمیز"
    else
        print_error "خطا در کامپایل!"
        make  # نمایش خطاها
        exit 1
    fi
    
    if [ -f "bin/convolution" ]; then
        chmod +x bin/convolution
        print_success "فایل اجرایی آماده: bin/convolution"
    else
        print_error "فایل اجرایی ساخته نشد!"
        exit 1
    fi
}

# تولید تصاویر تست
generate_test_images() {
    print_header "تولید تصاویر تست"
    
    if [ $HAS_PYTHON -eq 1 ] && [ -f "scripts/generate_test_images.py" ]; then
        echo "در حال تولید تصاویر..."
        if python3 scripts/generate_test_images.py > /dev/null 2>&1; then
            print_success "تصاویر تست تولید شدند"
        else
            print_info "خطا در تولید تصاویر، از تصاویر موجود استفاده می‌شود"
        fi
    else
        print_info "Python یا اسکریپت تولید تصویر یافت نشد"
    fi
    
    # بررسی وجود حداقل یک تصویر
    if [ ! -f "images/input.png" ] && [ ! -f "images/input_small.png" ]; then
        print_error "هیچ تصویر تستی یافت نشد!"
        echo "لطفاً یک تصویر PNG با نام input.png در پوشه images قرار دهید"
        exit 1
    fi
    
    # انتخاب تصویر بر اساس اندازه
    if [ -f "images/input.png" ]; then
        TEST_IMAGE="images/input.png"
        print_success "استفاده از تصویر: images/input.png"
    else
        TEST_IMAGE="images/input_small.png"
        print_info "استفاده از تصویر کوچک: images/input_small.png"
    fi
}

# تست صحت (Sequential vs Parallel)
test_correctness() {
    print_header "تست صحت عملکرد"
    
    echo "اجرای sequential..."
    ./bin/convolution -i "$TEST_IMAGE" -o results/test_sequential.png -k 3 -S > /dev/null 2>&1
    
    echo "اجرای parallel (4 threads)..."
    ./bin/convolution -i "$TEST_IMAGE" -o results/test_parallel.png -k 3 -t 4 -s static > /dev/null 2>&1
    
    if [ -f "results/test_sequential.png" ] && [ -f "results/test_parallel.png" ]; then
        print_success "تصاویر خروجی تولید شدند"
        print_info "لطفاً تصاویر را مقایسه کنید: results/test_sequential.png و results/test_parallel.png"
    else
        print_error "خطا در تولید تصاویر خروجی!"
        exit 1
    fi
}

# تابع اجرای تست با perf
run_with_perf() {
    local name=$1
    local output=$2
    shift 2
    local args="$@"
    
    if [ $HAS_PERF -eq 1 ]; then
        perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
            -o "results/perf_data/${name}.txt" \
            ./bin/convolution $args > /dev/null 2>&1
        
        # استخراج زمان
        time=$(grep "seconds time elapsed" "results/perf_data/${name}.txt" | awk '{print $1}')
    else
        # بدون perf، فقط زمان را اندازه بگیریم
        start=$(date +%s.%N)
        ./bin/convolution $args > /dev/null 2>&1
        end=$(date +%s.%N)
        time=$(echo "$end - $start" | bc)
        
        # ذخیره در فایل
        echo "Time elapsed: $time seconds" > "results/perf_data/${name}.txt"
    fi
    
    echo "$time"
}

# Benchmark 1: Thread Scaling
benchmark_thread_scaling() {
    print_header "Benchmark 1: Thread Scaling"
    
    echo "Test,Threads,Kernel,Time,Speedup" > results/data/thread_scaling.csv
    
    # Sequential baseline
    echo -n "Sequential baseline... "
    baseline_time=$(run_with_perf "baseline_k3" "results/images/baseline_k3.png" \
        -i "$TEST_IMAGE" -o results/images/baseline_k3.png -k 3 -S)
    echo "$baseline_time sec"
    echo "Baseline,1,3,$baseline_time,1.00" >> results/data/thread_scaling.csv
    
    # Thread counts
    for threads in 1 2 4 8; do
        echo -n "Testing $threads threads... "
        time=$(run_with_perf "threads_${threads}_k3" "results/images/threads_${threads}_k3.png" \
            -i "$TEST_IMAGE" -o results/images/threads_${threads}_k3.png -k 3 -t $threads -s static)
        
        speedup=$(echo "scale=2; $baseline_time / $time" | bc)
        echo "$time sec (speedup: ${speedup}x)"
        echo "Parallel,$threads,3,$time,$speedup" >> results/data/thread_scaling.csv
    done
    
    print_success "Thread scaling benchmark کامل شد"
}

# Benchmark 2: Scheduler Comparison
benchmark_schedulers() {
    print_header "Benchmark 2: Scheduler Comparison"
    
    echo "Scheduler,Time,Speedup" > results/data/schedulers.csv
    
    if [ -z "$baseline_time" ]; then
        baseline_time=$(grep "^Baseline," results/data/thread_scaling.csv | cut -d',' -f4)
    fi
    
    for scheduler in static dynamic guided; do
        echo -n "Testing $scheduler scheduler... "
        time=$(run_with_perf "scheduler_${scheduler}" "results/images/scheduler_${scheduler}.png" \
            -i "$TEST_IMAGE" -o results/images/scheduler_${scheduler}.png -k 3 -t 4 -s $scheduler)
        
        speedup=$(echo "scale=2; $baseline_time / $time" | bc)
        echo "$time sec (speedup: ${speedup}x)"
        echo "$scheduler,$time,$speedup" >> results/data/schedulers.csv
    done
    
    print_success "Scheduler comparison کامل شد"
}

# Benchmark 3: Kernel Size Comparison
benchmark_kernel_sizes() {
    print_header "Benchmark 3: Kernel Size Comparison"
    
    echo "Kernel_Size,Time,Ratio" > results/data/kernel_sizes.csv
    
    # Kernel 3x3
    echo -n "Testing kernel 3x3... "
    time_k3=$(run_with_perf "kernel_3x3" "results/images/kernel_3x3.png" \
        -i "$TEST_IMAGE" -o results/images/kernel_3x3.png -k 3 -t 4 -s static)
    echo "$time_k3 sec"
    echo "3,$time_k3,1.00" >> results/data/kernel_sizes.csv
    
    # Kernel 31x31
    echo -n "Testing kernel 31x31 (این ممکن است طولانی شود)... "
    time_k31=$(run_with_perf "kernel_31x31" "results/images/kernel_31x31.png" \
        -i "$TEST_IMAGE" -o results/images/kernel_31x31.png -k 31 -t 4 -s static)
    
    ratio=$(echo "scale=2; $time_k31 / $time_k3" | bc)
    echo "$time_k31 sec (${ratio}x slower)"
    echo "31,$time_k31,$ratio" >> results/data/kernel_sizes.csv
    
    print_success "Kernel size comparison کامل شد"
}

# Benchmark 4: Tiling Strategies
benchmark_tiling() {
    print_header "Benchmark 4: Tiling Strategies"
    
    echo "Tile_Size,Time,Speedup" > results/data/tiling.csv
    
    # No tiling
    echo -n "Testing without tiling... "
    time_notile=$(run_with_perf "tiling_none" "results/images/tiling_none.png" \
        -i "$TEST_IMAGE" -o results/images/tiling_none.png -k 31 -t 4 -s static -T 0)
    echo "$time_notile sec"
    echo "No_Tiling,$time_notile,1.00" >> results/data/tiling.csv
    
    # Tiling 8x8
    echo -n "Testing tiling 8x8... "
    time_tile8=$(run_with_perf "tiling_8x8" "results/images/tiling_8x8.png" \
        -i "$TEST_IMAGE" -o results/images/tiling_8x8.png -k 31 -t 4 -s static -T 8)
    speedup8=$(echo "scale=2; $time_notile / $time_tile8" | bc)
    echo "$time_tile8 sec (speedup: ${speedup8}x)"
    echo "8x8,$time_tile8,$speedup8" >> results/data/tiling.csv
    
    # Tiling 16x16
    echo -n "Testing tiling 16x16... "
    time_tile16=$(run_with_perf "tiling_16x16" "results/images/tiling_16x16.png" \
        -i "$TEST_IMAGE" -o results/images/tiling_16x16.png -k 31 -t 4 -s static -T 16)
    speedup16=$(echo "scale=2; $time_notile / $time_tile16" | bc)
    echo "$time_tile16 sec (speedup: ${speedup16}x)"
    echo "16x16,$time_tile16,$speedup16" >> results/data/tiling.csv
    
    print_success "Tiling strategies benchmark کامل شد"
}

# Benchmark 5: Loop Ordering
benchmark_loop_ordering() {
    print_header "Benchmark 5: Loop Ordering"
    
    echo "Loop_Order,Time,Difference" > results/data/loop_ordering.csv
    
    # Y-first
    echo -n "Testing Y-first loop order... "
    time_yfirst=$(run_with_perf "loop_yfirst" "results/images/loop_yfirst.png" \
        -i "$TEST_IMAGE" -o results/images/loop_yfirst.png -k 3 -t 4 -s static -l 0)
    echo "$time_yfirst sec"
    echo "Y-first,$time_yfirst,0.00" >> results/data/loop_ordering.csv
    
    # X-first
    echo -n "Testing X-first loop order... "
    time_xfirst=$(run_with_perf "loop_xfirst" "results/images/loop_xfirst.png" \
        -i "$TEST_IMAGE" -o results/images/loop_xfirst.png -k 3 -t 4 -s static -l 1)
    diff=$(echo "scale=2; (($time_xfirst - $time_yfirst) / $time_yfirst) * 100" | bc)
    echo "$time_xfirst sec (${diff}% difference)"
    echo "X-first,$time_xfirst,$diff" >> results/data/loop_ordering.csv
    
    print_success "Loop ordering benchmark کامل شد"
}

# استخراج metrics از perf
extract_perf_metrics() {
    print_header "استخراج Metrics از فایل‌های perf"
    
    if [ $HAS_PERF -eq 0 ]; then
        print_info "perf موجود نیست، این مرحله رد می‌شود"
        return
    fi
    
    echo "Test_Name,Time,Cycles,Instructions,IPC,Cache_Misses,L1_Misses" > results/data/perf_metrics.csv
    
    for file in results/perf_data/*.txt; do
        if [ -f "$file" ]; then
            name=$(basename "$file" .txt)
            time=$(grep "seconds time elapsed" "$file" 2>/dev/null | awk '{print $1}' 2>/dev/null || echo "N/A")
            cycles=$(grep "cycles" "$file" 2>/dev/null | head -1 | awk '{print $1}' 2>/dev/null | tr -d ',' 2>/dev/null || echo "0")
            instructions=$(grep "instructions" "$file" 2>/dev/null | head -1 | awk '{print $1}' 2>/dev/null | tr -d ',' 2>/dev/null || echo "0")
            cache_misses=$(grep "cache-misses" "$file" 2>/dev/null | awk '{print $1}' 2>/dev/null | tr -d ',' 2>/dev/null || echo "0")
            l1_misses=$(grep "L1-dcache-load-misses" "$file" 2>/dev/null | awk '{print $1}' 2>/dev/null | tr -d ',' 2>/dev/null || echo "0")
            
            # محاسبه IPC
            ipc="N/A"
            if [ -n "$cycles" ] && [ "$cycles" != "0" ] && [ "$cycles" != "N/A" ] && [ -n "$instructions" ] && [ "$instructions" != "0" ]; then
                if command -v bc &> /dev/null; then
                    ipc=$(echo "scale=3; $instructions / $cycles" | bc 2>/dev/null || echo "N/A")
                fi
            fi
            
            echo "$name,$time,$cycles,$instructions,$ipc,$cache_misses,$l1_misses" >> results/data/perf_metrics.csv
        fi
    done
    
    print_success "Metrics استخراج شدند: results/data/perf_metrics.csv"
}

# تولید گزارش خلاصه
generate_summary_report() {
    print_header "تولید گزارش خلاصه"
    
    report_file="results/SUMMARY_REPORT.txt"
    
    cat > "$report_file" << EOF
====================================
خلاصه نتایج Benchmark
OpenMP 2D Convolution
تاریخ: $(date '+%Y-%m-%d %H:%M:%S')
====================================

سیستم:
  CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
  Cores: $(nproc)
  Memory: $(free -h | grep Mem | awk '{print $2}')
  Kernel: $(uname -r)
  GCC: $(gcc --version | head -1)

تصویر تست:
  فایل: $TEST_IMAGE
  اندازه: $(identify -format "%wx%h" "$TEST_IMAGE" 2>/dev/null || echo "نامشخص")

====================================
1. Thread Scaling
====================================

EOF
    
    if [ -f "results/data/thread_scaling.csv" ]; then
        echo "نتایج:" >> "$report_file"
        column -t -s',' results/data/thread_scaling.csv >> "$report_file"
        echo "" >> "$report_file"
        
        # محاسبه بهترین تعداد thread
        best_threads=$(tail -n +2 results/data/thread_scaling.csv | grep "Parallel" | sort -t',' -k5 -rn | head -1 | cut -d',' -f2)
        best_speedup=$(tail -n +2 results/data/thread_scaling.csv | grep "Parallel" | sort -t',' -k5 -rn | head -1 | cut -d',' -f5)
        echo "بهترین تعداد thread: $best_threads (speedup: ${best_speedup}x)" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

====================================
2. Scheduler Comparison
====================================

EOF
    
    if [ -f "results/data/schedulers.csv" ]; then
        echo "نتایج:" >> "$report_file"
        column -t -s',' results/data/schedulers.csv >> "$report_file"
        echo "" >> "$report_file"
        
        # بهترین scheduler
        best_scheduler=$(tail -n +2 results/data/schedulers.csv | sort -t',' -k2 -n | head -1 | cut -d',' -f1)
        echo "بهترین scheduler: $best_scheduler" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

====================================
3. Kernel Size Comparison
====================================

EOF
    
    if [ -f "results/data/kernel_sizes.csv" ]; then
        echo "نتایج:" >> "$report_file"
        column -t -s',' results/data/kernel_sizes.csv >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

====================================
4. Tiling Strategies
====================================

EOF
    
    if [ -f "results/data/tiling.csv" ]; then
        echo "نتایج:" >> "$report_file"
        column -t -s',' results/data/tiling.csv >> "$report_file"
        echo "" >> "$report_file"
        
        # بهترین tile size
        best_tile=$(tail -n +2 results/data/tiling.csv | sort -t',' -k3 -rn | head -1 | cut -d',' -f1)
        echo "بهترین tile size: $best_tile" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

====================================
5. Loop Ordering
====================================

EOF
    
    if [ -f "results/data/loop_ordering.csv" ]; then
        echo "نتایج:" >> "$report_file"
        column -t -s',' results/data/loop_ordering.csv >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    if [ $HAS_PERF -eq 1 ] && [ -f "results/data/perf_metrics.csv" ]; then
        cat >> "$report_file" << EOF

====================================
Performance Metrics (از perf)
====================================

توجه: برای جزئیات بیشتر، فایل results/data/perf_metrics.csv را ببینید

EOF
        echo "نمونه metrics (5 تست اول):" >> "$report_file"
        head -6 results/data/perf_metrics.csv | column -t -s',' >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

====================================
فایل‌های تولید شده:
====================================

داده‌ها:
  - results/data/thread_scaling.csv
  - results/data/schedulers.csv
  - results/data/kernel_sizes.csv
  - results/data/tiling.csv
  - results/data/loop_ordering.csv
  - results/data/perf_metrics.csv

تصاویر:
  - results/images/*.png

perf data:
  - results/perf_data/*.txt

====================================
مراحل بعدی:
====================================

1. مشاهده گزارش خلاصه:
   cat results/SUMMARY_REPORT.txt

2. تحلیل داده‌ها با Python/Excel:
   استفاده از فایل‌های CSV در results/data/

3. رسم نمودارها:
   می‌توانید از matplotlib یا Excel استفاده کنید

4. مقایسه تصاویر:
   eog results/images/*.png

5. نوشتن گزارش:
   از template REPORT_TEMPLATE.md استفاده کنید

====================================
تمام شد!
====================================
EOF
    
    print_success "گزارش خلاصه ذخیره شد: $report_file"
}

# Main execution
main() {
    clear
    
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║                                                    ║"
    echo "║     OpenMP 2D Convolution - اسکریپت تست کامل      ║"
    echo "║                                                    ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    # مراحل اجرا
    check_directories
    check_dependencies
    setup_directories
    compile_project
    generate_test_images
    test_correctness
    
    # اخطار زمان
    print_info "هشدار: Benchmark کامل ممکن است 10-30 دقیقه طول بکشد"
    read -p "آیا ادامه می‌دهید؟ (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "لغو شد توسط کاربر"
        exit 0
    fi
    
    # شروع زمان‌سنج کل
    total_start=$(date +%s)
    
    # اجرای benchmark ها
    benchmark_thread_scaling
    benchmark_schedulers
    benchmark_kernel_sizes
    benchmark_tiling
    benchmark_loop_ordering
    
    # استخراج metrics
    extract_perf_metrics
    
    # تولید گزارش
    generate_summary_report
    
    # محاسبه زمان کل
    total_end=$(date +%s)
    total_time=$((total_end - total_start))
    minutes=$((total_time / 60))
    seconds=$((total_time % 60))
    
    # پیام نهایی
    print_header "تست کامل به پایان رسید! 🎉"
    
    echo -e "${GREEN}"
    echo "زمان کل: ${minutes} دقیقه و ${seconds} ثانیه"
    echo ""
    echo "نتایج ذخیره شدند در:"
    echo "  📊 داده‌ها: results/data/"
    echo "  🖼️  تصاویر: results/images/"
    echo "  📈 perf: results/perf_data/"
    echo "  📝 گزارش: results/SUMMARY_REPORT.txt"
    echo ""
    echo "برای مشاهده گزارش خلاصه:"
    echo "  cat results/SUMMARY_REPORT.txt"
    echo ""
    echo -e "${NC}"
    
    print_success "همه چیز آماده است برای نوشتن گزارش نهایی!"
}

# اجرای برنامه اصلی
main "$@"
