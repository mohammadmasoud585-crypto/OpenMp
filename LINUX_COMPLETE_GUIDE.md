# راهنمای گام‌به‌گام اجرای تکلیف در لینوکس
# OpenMP 2D Convolution - HW3

## 🚀 مرحله 1: نصب پیش‌نیازها

### نصب کامپایلر و ابزارها
```bash
# به‌روزرسانی سیستم
sudo apt-get update

# نصب GCC با پشتیبانی OpenMP
sudo apt-get install -y build-essential gcc g++ make

# نصب perf برای profiling
sudo apt-get install -y linux-tools-common linux-tools-generic
sudo apt-get install -y linux-tools-$(uname -r)

# نصب gprof (معمولاً با gcc نصب می‌شود)
# اگر نصب نشده:
sudo apt-get install -y binutils

# نصب Python برای تولید تصاویر تست
sudo apt-get install -y python3 python3-pip
pip3 install pillow numpy matplotlib pandas
```

### بررسی نصب صحیح
```bash
# بررسی GCC
gcc --version

# بررسی OpenMP
echo | gcc -fopenmp -E -dM - | grep -i openmp
# باید _OPENMP را ببینید

# بررسی perf
perf --version

# بررسی Python
python3 --version
```

---

## 📁 مرحله 2: آماده‌سازی پروژه

```bash
# رفتن به پوشه پروژه
cd ~/Desktop/OpenMp

# یا اگر در مسیر دیگری است:
# cd /path/to/OpenMp

# بررسی ساختار پروژه
ls -la

# باید این پوشه‌ها را ببینید:
# src/ include/ scripts/ images/ results/
```

---

## 🖼️ مرحله 3: تولید تصاویر تست

```bash
# اجرای اسکریپت Python برای تولید تصاویر
python3 scripts/generate_test_images.py

# بررسی تصاویر تولید شده
ls -lh images/

# باید این فایل‌ها را ببینید:
# input.png (2048x2048)
# input_small.png (512x512)
# checkerboard.png
# gradient.png
# stripes_horizontal.png
# stripes_vertical.png
```

---

## 🔨 مرحله 4: کامپایل پروژه

```bash
# پاکسازی فایل‌های قبلی (اگر وجود دارد)
make clean

# کامپایل نسخه optimized
make

# بررسی موفقیت کامپایل
ls -lh bin/
# باید bin/convolution را ببینید

# اجازه اجرا به فایل
chmod +x bin/convolution

# کامپایل نسخه با profiling support
make profile
chmod +x bin/convolution_prof
```

---

## ✅ مرحله 5: تست اولیه (بررسی صحت)

```bash
# اجازه اجرا به اسکریپت تست
chmod +x scripts/quick_test.sh

# اجرای تست سریع با تصویر کوچک
./scripts/quick_test.sh

# اگر همه تست‌ها pass شدند، ادامه دهید
# اگر خطا داشتید، مشکل را برطرف کنید
```

### تست دستی (اختیاری)
```bash
# Sequential baseline
./bin/convolution -i images/input_small.png -o results/test_seq.png -k 3 -S

# Parallel با 4 thread
./bin/convolution -i images/input_small.png -o results/test_parallel.png -k 3 -t 4 -s static

# مقایسه بصری دو تصویر (باید یکسان باشند)
eog results/test_seq.png results/test_parallel.png
# یا
display results/test_seq.png results/test_parallel.png
```

---

## 📊 مرحله 6: Benchmark Step 1 - Thread Scaling

### جمع‌آوری داده با تصویر اصلی (2048x2048)

```bash
# ایجاد پوشه برای نتایج
mkdir -p results/step1_threads
mkdir -p results/perf_data

# Sequential baseline (بسیار مهم!)
echo "=== Sequential Baseline ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/baseline_k3.txt \
    ./bin/convolution -i images/input.png -o results/step1_threads/baseline_k3.png -k 3 -S

# ذخیره زمان
# خروجی را یادداشت کنید

# Thread count = 1 (باید با sequential یکسان باشد)
echo "=== 1 Thread ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/threads_1_k3.txt \
    ./bin/convolution -i images/input.png -o results/step1_threads/threads_1_k3.png -k 3 -t 1 -s static

# Thread count = 2
echo "=== 2 Threads ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/threads_2_k3.txt \
    ./bin/convolution -i images/input.png -o results/step1_threads/threads_2_k3.png -k 3 -t 2 -s static

# Thread count = 4
echo "=== 4 Threads ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/threads_4_k3.txt \
    ./bin/convolution -i images/input.png -o results/step1_threads/threads_4_k3.png -k 3 -t 4 -s static

# Thread count = 8
echo "=== 8 Threads ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/threads_8_k3.txt \
    ./bin/convolution -i images/input.png -o results/step1_threads/threads_8_k3.png -k 3 -t 8 -s static

# بررسی نتایج
echo "=== Thread Scaling Results ==="
grep "seconds time elapsed" results/perf_data/threads_*.txt
```

---

## 📊 مرحله 7: Benchmark Step 2 - Scheduler Comparison

```bash
# ایجاد پوشه
mkdir -p results/step2_schedulers

# با 4 threads، kernel 3x3

# Static scheduler
echo "=== Static Scheduler ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/scheduler_static_k3.txt \
    ./bin/convolution -i images/input.png -o results/step2_schedulers/static_k3.png \
    -k 3 -t 4 -s static -c 1

# Dynamic scheduler
echo "=== Dynamic Scheduler ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/scheduler_dynamic_k3.txt \
    ./bin/convolution -i images/input.png -o results/step2_schedulers/dynamic_k3.png \
    -k 3 -t 4 -s dynamic -c 1

# Guided scheduler
echo "=== Guided Scheduler ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/scheduler_guided_k3.txt \
    ./bin/convolution -i images/input.png -o results/step2_schedulers/guided_k3.png \
    -k 3 -t 4 -s guided -c 1

# بررسی نتایج
echo "=== Scheduler Comparison Results ==="
grep "seconds time elapsed" results/perf_data/scheduler_*.txt
```

---

## 📊 مرحله 8: Benchmark Step 3 - Kernel Size Comparison

```bash
# ایجاد پوشه
mkdir -p results/step3_kernels

# Kernel 3x3 (قبلاً اجرا شده، می‌توانید دوباره اجرا کنید)
echo "=== Kernel 3x3 ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/kernel_3x3.txt \
    ./bin/convolution -i images/input.png -o results/step3_kernels/kernel_3x3.png \
    -k 3 -t 4 -s static

# Kernel 31x31 (بسیار مهم!)
echo "=== Kernel 31x31 ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/kernel_31x31.txt \
    ./bin/convolution -i images/input.png -o results/step3_kernels/kernel_31x31.png \
    -k 31 -t 4 -s static

# توجه: kernel 31x31 زمان بیشتری می‌برد (حدود 100 برابر)

# بررسی نتایج
echo "=== Kernel Size Comparison ==="
grep "seconds time elapsed" results/perf_data/kernel_*.txt
```

---

## 📊 مرحله 9: Benchmark Step 4 - Tiling Strategies

```bash
# ایجاد پوشه
mkdir -p results/step4_tiling

# با kernel 31x31 برای دیدن تأثیر واضح

# No tiling (baseline برای tiling)
echo "=== No Tiling ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/tiling_none_k31.txt \
    ./bin/convolution -i images/input.png -o results/step4_tiling/notiling_k31.png \
    -k 31 -t 4 -s static -T 0

# Tiling 8x8
echo "=== Tiling 8x8 ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/tiling_8x8_k31.txt \
    ./bin/convolution -i images/input.png -o results/step4_tiling/tile8_k31.png \
    -k 31 -t 4 -s static -T 8

# Tiling 16x16
echo "=== Tiling 16x16 ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/tiling_16x16_k31.txt \
    ./bin/convolution -i images/input.png -o results/step4_tiling/tile16_k31.png \
    -k 31 -t 4 -s static -T 16

# بررسی نتایج (توجه به cache misses)
echo "=== Tiling Comparison ==="
grep "cache-misses" results/perf_data/tiling_*.txt
grep "seconds time elapsed" results/perf_data/tiling_*.txt
```

---

## 📊 مرحله 10: Benchmark Step 5 - Loop Ordering

```bash
# ایجاد پوشه
mkdir -p results/step5_looporder

# Y-first (row-major, معمولاً بهتر)
echo "=== Y-first Loop Order ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/loop_yfirst_k3.txt \
    ./bin/convolution -i images/input.png -o results/step5_looporder/yfirst_k3.png \
    -k 3 -t 4 -s static -l 0

# X-first (column-major)
echo "=== X-first Loop Order ==="
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    -o results/perf_data/loop_xfirst_k3.txt \
    ./bin/convolution -i images/input.png -o results/step5_looporder/xfirst_k3.png \
    -k 3 -t 4 -s static -l 1

# بررسی نتایج (توجه به cache misses و L1 misses)
echo "=== Loop Order Comparison ==="
grep "L1-dcache-load-misses" results/perf_data/loop_*.txt
grep "seconds time elapsed" results/perf_data/loop_*.txt
```

---

## 📊 مرحله 11: Benchmark کامل خودکار

```bash
# اجازه اجرا به اسکریپت
chmod +x scripts/benchmark.sh

# اجرای benchmark کامل
./scripts/benchmark.sh

# این اسکریپت تمام تست‌ها را اجرا می‌کند و نتایج را در CSV ذخیره می‌کند
# زمان: حدود 10-30 دقیقه (بستگی به سیستم شما)

# بررسی نتایج
cat results/benchmark_results.csv
```

---

## 📊 مرحله 12: Profiling با gprof

```bash
# اجرا با نسخه profiling
./bin/convolution_prof -i images/input.png -o results/gprof_output.png -k 3 -t 4 -s static

# تولید گزارش gprof
gprof bin/convolution_prof gmon.out > results/gprof_report.txt

# مشاهده top functions
head -n 50 results/gprof_report.txt

# توجه: gprof ممکن است با OpenMP مشکل داشته باشد
# اگر نتایج عجیب دیدید، در گزارش توضیح دهید
```

---

## 📊 مرحله 13: استخراج و سازماندهی داده‌ها

```bash
# ایجاد یک اسکریپت برای استخراج خودکار داده‌ها
cat > extract_results.sh << 'EOF'
#!/bin/bash

echo "Test,Threads,Scheduler,Tile,Kernel,Time,Cycles,Instructions,IPC,CacheMisses,L1Misses" > results/summary.csv

for file in results/perf_data/*.txt; do
    name=$(basename "$file" .txt)
    time=$(grep "seconds time elapsed" "$file" | awk '{print $1}')
    cycles=$(grep "cycles" "$file" | head -1 | awk '{print $1}' | tr -d ',')
    instructions=$(grep "instructions" "$file" | head -1 | awk '{print $1}' | tr -d ',')
    cache_misses=$(grep "cache-misses" "$file" | awk '{print $1}' | tr -d ',')
    l1_misses=$(grep "L1-dcache-load-misses" "$file" | awk '{print $1}' | tr -d ',')
    
    # محاسبه IPC
    if [ -n "$cycles" ] && [ -n "$instructions" ] && [ "$cycles" != "0" ]; then
        ipc=$(echo "scale=3; $instructions / $cycles" | bc)
    else
        ipc="N/A"
    fi
    
    echo "$name,,,,,$time,$cycles,$instructions,$ipc,$cache_misses,$l1_misses" >> results/summary.csv
done

echo "Results extracted to results/summary.csv"
EOF

chmod +x extract_results.sh
./extract_results.sh

# مشاهده خلاصه نتایج
cat results/summary.csv
```

---

## 📊 مرحله 14: تحلیل داده‌ها با Python

```bash
# ایجاد اسکریپت Python برای تحلیل و رسم نمودار
cat > analyze_results.py << 'EOF'
#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# خواندن داده‌ها
df = pd.read_csv('results/summary.csv')

# تابع کمکی برای استخراج اطلاعات از نام تست
def parse_test_name(name):
    parts = {}
    if 'threads_' in name:
        parts['threads'] = int(name.split('threads_')[1].split('_')[0])
        parts['type'] = 'thread_scaling'
    elif 'scheduler_' in name:
        parts['scheduler'] = name.split('scheduler_')[1].split('_')[0]
        parts['type'] = 'scheduler'
    elif 'kernel_' in name:
        parts['kernel'] = name.split('kernel_')[1].split('x')[0]
        parts['type'] = 'kernel'
    elif 'tiling_' in name:
        parts['tiling'] = name.split('tiling_')[1].split('_')[0]
        parts['type'] = 'tiling'
    elif 'loop_' in name:
        parts['loop'] = name.split('loop_')[1].split('_')[0]
        parts['type'] = 'loop'
    elif 'baseline' in name:
        parts['type'] = 'baseline'
    return parts

# افزودن ستون‌های تجزیه شده
for col in ['type', 'threads', 'scheduler', 'kernel', 'tiling', 'loop']:
    df[col] = None

for idx, row in df.iterrows():
    parsed = parse_test_name(row['Test'])
    for key, value in parsed.items():
        df.at[idx, key] = value

# ذخیره
df.to_csv('results/analyzed_results.csv', index=False)

print("Analysis complete. Results saved to results/analyzed_results.csv")
print("\nSummary:")
print(df[['Test', 'Time', 'IPC', 'CacheMisses']].to_string())

# رسم نمودار thread scaling
thread_data = df[df['type'] == 'thread_scaling'].sort_values('threads')
if not thread_data.empty:
    plt.figure(figsize=(10, 6))
    plt.plot(thread_data['threads'], thread_data['Time'], marker='o', linewidth=2)
    plt.xlabel('Number of Threads')
    plt.ylabel('Execution Time (seconds)')
    plt.title('Thread Scaling Analysis')
    plt.grid(True)
    plt.savefig('results/thread_scaling.png', dpi=300, bbox_inches='tight')
    print("\nThread scaling plot saved to results/thread_scaling.png")

EOF

chmod +x analyze_results.py
python3 analyze_results.py
```

---

## 📝 مرحله 15: آماده‌سازی گزارش

```bash
# کپی template گزارش
cp REPORT_TEMPLATE.md Report_HW3.md

# باز کردن در editor
nano Report_HW3.md
# یا
vim Report_HW3.md
# یا
gedit Report_HW3.md

# نکات مهم برای گزارش:
# 1. مشخصات سیستم خود را وارد کنید
# 2. جداول را با داده‌های واقعی از results/summary.csv پر کنید
# 3. نمودارها را اضافه کنید
# 4. تحلیل دقیق بنویسید (نه فقط داده!)
# 5. با pthreads (HW2) مقایسه کنید
# 6. تصاویر ورودی/خروجی را اضافه کنید
```

---

## 📊 مرحله 16: جمع‌آوری تصاویر برای گزارش

```bash
# ایجاد پوشه برای گزارش
mkdir -p Report_Files/images
mkdir -p Report_Files/plots

# کپی تصاویر نمونه
cp images/input.png Report_Files/images/
cp results/step3_kernels/kernel_3x3.png Report_Files/images/output_3x3.png
cp results/step3_kernels/kernel_31x31.png Report_Files/images/output_31x31.png

# کپی نمودارها
cp results/thread_scaling.png Report_Files/plots/

# کپی فایل‌های perf برای reference
cp -r results/perf_data Report_Files/

# screenshot از terminal با perf output
# (این را دستی باید بگیرید)
```

---

## 📦 مرحله 17: آماده‌سازی فایل نهایی برای تحویل

```bash
# ایجاد پوشه نهایی
mkdir -p PA-F25-[YOURNAME]-[STUDENTID]-HW3

# کپی کدها
cp -r src PA-F25-[YOURNAME]-[STUDENTID]-HW3/
cp -r include PA-F25-[YOURNAME]-[STUDENTID]-HW3/
cp Makefile PA-F25-[YOURNAME]-[STUDENTID]-HW3/
cp README.md PA-F25-[YOURNAME]-[STUDENTID]-HW3/

# کپی scripts
cp -r scripts PA-F25-[YOURNAME]-[STUDENTID]-HW3/

# کپی نتایج (انتخابی مهم)
mkdir PA-F25-[YOURNAME]-[STUDENTID]-HW3/results
cp results/summary.csv PA-F25-[YOURNAME]-[STUDENTID]-HW3/results/
cp results/benchmark_results.csv PA-F25-[YOURNAME]-[STUDENTID]-HW3/results/
cp -r results/perf_data PA-F25-[YOURNAME]-[STUDENTID]-HW3/results/

# کپی گزارش
cp Report_HW3.md PA-F25-[YOURNAME]-[STUDENTID]-HW3/
# یا اگر PDF تهیه کردید:
# cp Report_HW3.pdf PA-F25-[YOURNAME]-[STUDENTID]-HW3/

# کپی تصاویر نمونه
cp -r Report_Files PA-F25-[YOURNAME]-[STUDENTID]-HW3/

# فشرده‌سازی
zip -r PA-F25-[YOURNAME]-[STUDENTID]-HW3.zip PA-F25-[YOURNAME]-[STUDENTID]-HW3/

echo "✅ فایل نهایی آماده است: PA-F25-[YOURNAME]-[STUDENTID]-HW3.zip"
```

---

## ✅ Checklist نهایی

قبل از تحویل، این موارد را بررسی کنید:

```bash
# 1. کامپایل می‌شود؟
make clean && make
echo "✅ کامپایل موفق"

# 2. برنامه اجرا می‌شود؟
./bin/convolution -i images/input.png -o results/final_test.png -k 3 -t 4
echo "✅ اجرا موفق"

# 3. نتایج benchmark وجود دارد؟
test -f results/summary.csv && echo "✅ نتایج benchmark موجود"

# 4. داده‌های perf وجود دارد؟
test -d results/perf_data && echo "✅ داده‌های perf موجود"

# 5. گزارش نوشته شده؟
test -f Report_HW3.md && echo "✅ گزارش موجود"

# 6. فایل ZIP آماده است؟
test -f PA-F25-*-HW3.zip && echo "✅ فایل ZIP آماده"
```

---

## 🎯 نکات مهم و توصیه‌های نهایی

### برای عملکرد بهتر:
```bash
# 1. سیستم را از پس‌زمینه خالی کنید
# بستن برنامه‌های غیرضروری

# 2. CPU governor را روی performance بگذارید
sudo cpupower frequency-set -g performance

# 3. هر benchmark را 3 بار اجرا کنید و میانگین بگیرید

# 4. سیستم را ریستارت کنید قبل از benchmark نهایی
```

### برای perf بدون sudo:
```bash
# اگر perf خطای permission می‌دهد:
sudo sysctl -w kernel.perf_event_paranoid=-1

# یا برای دائمی:
echo "kernel.perf_event_paranoid=-1" | sudo tee -a /etc/sysctl.conf
```

### برای debugging:
```bash
# اگر مشکلی پیش آمد:
make debug
gdb bin/convolution_debug

# یا
valgrind --leak-check=full ./bin/convolution -i images/input_small.png -o results/test.png -k 3 -t 4
```

---

## 🎓 تحلیل‌های مهم برای گزارش

در گزارش حتماً به این موارد بپردازید:

### 1. Thread Scaling
- چرا با 8 thread کندتر از 4 thread است؟
- Efficiency چگونه کاهش می‌یابد؟
- Amdahl's law در عمل

### 2. Scheduler Comparison
- چرا static بهتر است؟
- Overhead dynamic و guided
- Load balancing

### 3. Kernel Size
- تأثیر O(k²) روی زمان
- Cache miss rate چگونه تغییر می‌کند؟
- IPC چرا کاهش می‌یابد؟

### 4. Tiling
- چقدر cache miss کاهش یافت؟
- بهترین tile size چیست و چرا؟
- Trade-off بین granularity و overhead

### 5. Loop Ordering
- Row-major vs column-major
- Spatial locality
- Cache line utilization

### 6. OpenMP vs pthreads
- کدام سریع‌تر بود؟
- کدام ساده‌تر بود؟
- Overhead مقایسه

---

## 📞 در صورت مشکل

```bash
# بررسی لاگ‌ها
cat results/perf_data/*.txt | grep -i error

# بررسی core dumps
dmesg | tail

# تست با تصویر کوچک‌تر
./bin/convolution -i images/input_small.png -o results/debug.png -k 3 -t 2 -s static

# اجرا با verbose mode (اگر اضافه کردید)
# یا redirect کردن stdout/stderr
./bin/convolution -i images/input.png -o results/test.png -k 3 -t 4 2>&1 | tee results/debug.log
```

---

## 🎉 موفق باشید!

اگر تمام مراحل را دنبال کردید:
✅ کد کامل اجرا شده
✅ Benchmark های جامع انجام شده
✅ داده‌های perf جمع‌آوری شده
✅ تحلیل‌ها آماده
✅ گزارش قابل نوشتن
✅ فایل ZIP آماده تحویل

**Deadline: 2025/12/12**

---

## 📚 منابع اضافی

- OpenMP Cheat Sheet: https://www.openmp.org/wp-content/uploads/OpenMP-4.5-1115-CPP-web.pdf
- perf Examples: http://www.brendangregg.com/perf.html
- Cache Optimization: https://www.akkadia.org/drepper/cpumemory.pdf

---

**نکته:** این فایل را قدم‌به‌قدم دنبال کنید. زمان تقریبی: 2-3 ساعت (بدون زمان نوشتن گزارش)
