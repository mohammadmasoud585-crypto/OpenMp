#!/bin/bash

################################################################################
# Full Test Suite - OpenMP 2D Convolution
# اجرای کامل تمام تست‌ها با گزارش جامع
################################################################################

set -e  # Stop on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  OpenMP 2D Convolution - Full Test Suite                 ║${NC}"
echo -e "${BLUE}║  تست کامل پروژه Convolution با OpenMP                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

################################################################################
# Step 1: Check Dependencies
################################################################################
echo -e "${YELLOW}[1/9] بررسی ابزارهای لازم...${NC}"

MISSING_TOOLS=()

if ! command -v gcc &> /dev/null; then
    MISSING_TOOLS+=("gcc")
fi

if ! command -v make &> /dev/null; then
    MISSING_TOOLS+=("make")
fi

if ! command -v python3 &> /dev/null; then
    MISSING_TOOLS+=("python3")
fi

if ! command -v wget &> /dev/null; then
    MISSING_TOOLS+=("wget")
fi

if ! command -v bc &> /dev/null; then
    MISSING_TOOLS+=("bc")
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "${RED}✗ ابزارهای زیر نصب نیستند:${NC}"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done
    echo ""
    echo "برای نصب:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y gcc make python3 wget bc linux-tools-common"
    exit 1
fi

echo -e "${GREEN}✓ تمام ابزارها نصب شده‌اند${NC}"
echo ""

################################################################################
# Step 2: Download Real STB Libraries
################################################################################
echo -e "${YELLOW}[2/9] دانلود کتابخانه‌های واقعی STB...${NC}"

STB_IMAGE_URL="https://raw.githubusercontent.com/nothings/stb/master/stb_image.h"
STB_IMAGE_WRITE_URL="https://raw.githubusercontent.com/nothings/stb/master/stb_image_write.h"

# Backup old files if they exist
if [ -f "include/stb_image.h" ]; then
    cp include/stb_image.h include/stb_image.h.backup
fi

if [ -f "include/stb_image_write.h" ]; then
    cp include/stb_image_write.h include/stb_image_write.h.backup
fi

# Download
echo "  دانلود stb_image.h..."
if wget -q "$STB_IMAGE_URL" -O include/stb_image.h; then
    echo -e "${GREEN}  ✓ stb_image.h دانلود شد${NC}"
else
    echo -e "${RED}  ✗ خطا در دانلود stb_image.h${NC}"
    exit 1
fi

echo "  دانلود stb_image_write.h..."
if wget -q "$STB_IMAGE_WRITE_URL" -O include/stb_image_write.h; then
    echo -e "${GREEN}  ✓ stb_image_write.h دانلود شد${NC}"
else
    echo -e "${RED}  ✗ خطا در دانلود stb_image_write.h${NC}"
    exit 1
fi

# Verify file sizes (real files should be > 5KB)
STB_IMAGE_SIZE=$(stat -f%z "include/stb_image.h" 2>/dev/null || stat -c%s "include/stb_image.h" 2>/dev/null || echo 0)
STB_IMAGE_WRITE_SIZE=$(stat -f%z "include/stb_image_write.h" 2>/dev/null || stat -c%s "include/stb_image_write.h" 2>/dev/null || echo 0)

if [ "$STB_IMAGE_SIZE" -lt 5000 ] || [ "$STB_IMAGE_WRITE_SIZE" -lt 5000 ]; then
    echo -e "${RED}✗ فایل‌های دانلود شده خیلی کوچک هستند (احتمالاً stub)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ کتابخانه‌های STB دانلود شدند (${STB_IMAGE_SIZE} bytes + ${STB_IMAGE_WRITE_SIZE} bytes)${NC}"
echo ""

################################################################################
# Step 3: Create Directories
################################################################################
echo -e "${YELLOW}[3/9] ساخت پوشه‌ها...${NC}"

mkdir -p images
mkdir -p results
mkdir -p results/data
mkdir -p results/images
mkdir -p bin

echo -e "${GREEN}✓ پوشه‌ها آماده شدند${NC}"
echo ""

################################################################################
# Step 4: Generate Test Images
################################################################################
echo -e "${YELLOW}[4/9] ساخت تصاویر تست...${NC}"

if [ ! -f "scripts/generate_test_images.py" ]; then
    echo -e "${RED}✗ فایل generate_test_images.py وجود ندارد${NC}"
    exit 1
fi

python3 scripts/generate_test_images.py

if [ ! -f "images/input.png" ]; then
    echo -e "${RED}✗ تصویر input.png ساخته نشد${NC}"
    exit 1
fi

IMAGE_SIZE=$(stat -f%z "images/input.png" 2>/dev/null || stat -c%s "images/input.png" 2>/dev/null || echo 0)
echo -e "${GREEN}✓ تصاویر تست ساخته شدند (input.png: ${IMAGE_SIZE} bytes)${NC}"
echo ""

################################################################################
# Step 5: Clean Previous Build
################################################################################
echo -e "${YELLOW}[5/9] پاکسازی build قبلی...${NC}"

make clean > /dev/null 2>&1

echo -e "${GREEN}✓ پاکسازی انجام شد${NC}"
echo ""

################################################################################
# Step 6: Compile Project
################################################################################
echo -e "${YELLOW}[6/9] کامپایل پروژه...${NC}"

if make; then
    echo -e "${GREEN}✓ کامپایل موفق${NC}"
else
    echo -e "${RED}✗ خطا در کامپایل${NC}"
    exit 1
fi

if [ ! -f "bin/convolution" ]; then
    echo -e "${RED}✗ فایل اجرایی ساخته نشد${NC}"
    exit 1
fi

echo ""

################################################################################
# Step 7: Quick Validation Test
################################################################################
echo -e "${YELLOW}[7/9] تست سریع اعتبارسنجی...${NC}"

TEST_START=$(date +%s)
if ./bin/convolution -i images/input.png -o results/test_quick.png -k 3 -t 4; then
    TEST_END=$(date +%s)
    TEST_DURATION=$((TEST_END - TEST_START))
    
    if [ "$TEST_DURATION" -lt 3 ]; then
        echo -e "${RED}✗ تست خیلی سریع اجرا شد ($TEST_DURATION ثانیه) - احتمالاً مشکل دارد!${NC}"
        echo "  فایل‌های STB ممکن است هنوز stub باشند"
        exit 1
    fi
    
    echo -e "${GREEN}✓ تست سریع موفق ($TEST_DURATION ثانیه)${NC}"
else
    echo -e "${RED}✗ تست سریع ناموفق${NC}"
    exit 1
fi

if [ ! -f "results/test_quick.png" ]; then
    echo -e "${RED}✗ تصویر خروجی ساخته نشد${NC}"
    exit 1
fi

echo ""

################################################################################
# Step 8: Full Benchmark Suite
################################################################################
echo -e "${YELLOW}[8/9] اجرای تست‌های کامل benchmark...${NC}"
echo -e "${BLUE}⏳ این مرحله 20-40 دقیقه طول می‌کشد${NC}"
echo ""

BENCH_START=$(date +%s)

if [ -f "scripts/run_complete_tests.sh" ]; then
    chmod +x scripts/run_complete_tests.sh
    if ./scripts/run_complete_tests.sh; then
        BENCH_END=$(date +%s)
        BENCH_DURATION=$((BENCH_END - BENCH_START))
        BENCH_MINUTES=$((BENCH_DURATION / 60))
        BENCH_SECONDS=$((BENCH_DURATION % 60))
        
        echo ""
        echo -e "${GREEN}✓ تست‌های benchmark تمام شدند (${BENCH_MINUTES}m ${BENCH_SECONDS}s)${NC}"
    else
        echo -e "${RED}✗ خطا در اجرای benchmark${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ فایل run_complete_tests.sh وجود ندارد${NC}"
    exit 1
fi

echo ""

################################################################################
# Step 9: Generate Summary Report
################################################################################
echo -e "${YELLOW}[9/9] ساخت گزارش نهایی...${NC}"

REPORT_FILE="results/FULL_TEST_REPORT.txt"

cat > "$REPORT_FILE" << EOF
╔════════════════════════════════════════════════════════════╗
║  OpenMP 2D Convolution - گزارش کامل تست‌ها               ║
╚════════════════════════════════════════════════════════════╝

تاریخ اجرا: $(date '+%Y-%m-%d %H:%M:%S')
مدت زمان کل: ${BENCH_MINUTES}m ${BENCH_SECONDS}s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 فایل‌های نتیجه:

EOF

# List all CSV files
if ls results/data/*.csv 1> /dev/null 2>&1; then
    for csv_file in results/data/*.csv; do
        filename=$(basename "$csv_file")
        filesize=$(stat -f%z "$csv_file" 2>/dev/null || stat -c%s "$csv_file" 2>/dev/null || echo 0)
        lines=$(wc -l < "$csv_file" 2>/dev/null || echo 0)
        echo "  ✓ $filename (${filesize} bytes, ${lines} خط)" >> "$REPORT_FILE"
    done
else
    echo "  ⚠ هیچ فایل CSV یافت نشد!" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🖼️ تصاویر خروجی:

EOF

# List output images
if ls results/images/*.png 1> /dev/null 2>&1; then
    for img_file in results/images/*.png; do
        filename=$(basename "$img_file")
        filesize=$(stat -f%z "$img_file" 2>/dev/null || stat -c%s "$img_file" 2>/dev/null || echo 0)
        echo "  ✓ $filename (${filesize} bytes)" >> "$REPORT_FILE"
    done
else
    echo "  ⚠ هیچ تصویر خروجی یافت نشد!" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 آماره‌های کلی:

EOF

# Count total test runs
TOTAL_TESTS=0
if [ -f "results/data/thread_scaling.csv" ]; then
    TOTAL_TESTS=$((TOTAL_TESTS + $(tail -n +2 results/data/thread_scaling.csv 2>/dev/null | wc -l)))
fi
if [ -f "results/data/scheduler_comparison.csv" ]; then
    TOTAL_TESTS=$((TOTAL_TESTS + $(tail -n +2 results/data/scheduler_comparison.csv 2>/dev/null | wc -l)))
fi

echo "  • تعداد کل تست‌ها: $TOTAL_TESTS" >> "$REPORT_FILE"
echo "  • مدت زمان اجرا: ${BENCH_MINUTES} دقیقه و ${BENCH_SECONDS} ثانیه" >> "$REPORT_FILE"

# Find fastest time
FASTEST_TIME=""
if [ -f "results/data/thread_scaling.csv" ]; then
    FASTEST_TIME=$(tail -n +2 results/data/thread_scaling.csv 2>/dev/null | cut -d',' -f4 | sort -n | head -n1)
    if [ -n "$FASTEST_TIME" ]; then
        echo "  • سریع‌ترین اجرا: ${FASTEST_TIME} ثانیه" >> "$REPORT_FILE"
    fi
fi

cat >> "$REPORT_FILE" << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 مراحل بعدی:

1. بررسی فایل‌های CSV در results/data/
2. ساخت نمودارها با Python/Excel/MATLAB
3. مقایسه با نتایج pthreads (تکلیف 2)
4. تکمیل گزارش نهایی
5. بررسی تصاویر خروجی در results/images/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ تست‌ها با موفقیت تمام شدند!

EOF

echo -e "${GREEN}✓ گزارش نهایی ساخته شد: $REPORT_FILE${NC}"
echo ""

################################################################################
# Final Summary
################################################################################
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    ✅ تمام شد!                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ تمام مراحل با موفقیت انجام شدند${NC}"
echo ""
echo "📁 فایل‌های مهم:"
echo "  • گزارش کامل: results/FULL_TEST_REPORT.txt"
echo "  • داده‌های benchmark: results/data/*.csv"
echo "  • تصاویر خروجی: results/images/*.png"
echo ""
echo "برای مشاهده گزارش:"
echo "  cat results/FULL_TEST_REPORT.txt"
echo ""

# Display report
if [ -f "$REPORT_FILE" ]; then
    cat "$REPORT_FILE"
fi

exit 0
