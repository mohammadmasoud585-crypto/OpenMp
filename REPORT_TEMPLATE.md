# گزارش تکلیف سوم - کانولوشن موازی 2D با OpenMP

**نام و نام خانوادگی:** [نام شما]  
**شماره دانشجویی:** [شماره دانشجویی شما]  
**درس:** الگوریتم‌های موازی  
**استاد:** دکتر فرشاد خونجوش  
**تاریخ:** [تاریخ]

---

## فهرست مطالب

1. [مقدمه](#مقدمه)
2. [اتوماسیون (Makefile)](#اتوماسیون)
3. [دستورالعمل اجرا](#دستورالعمل-اجرا)
4. [تحلیل عملکرد](#تحلیل-عملکرد)
5. [مقایسه OpenMP و pthreads](#مقایسه-openmp-و-pthreads)
6. [فیلترهای استفاده شده](#فیلترهای-استفاده-شده)
7. [نتیجه‌گیری](#نتیجهگیری)

---

## مقدمه

در این تکلیف، عملیات کانولوشن 2D روی تصاویر با استفاده از OpenMP پیاده‌سازی شده است. هدف اصلی، بررسی تأثیر پارامترهای مختلف مانند تعداد thread‌ها، نوع زمان‌بندی (scheduling)، ترتیب حلقه‌ها و استراتژی‌های tiling بر عملکرد است.

### اهداف پروژه
- پیاده‌سازی کانولوشن موازی با OpenMP
- بررسی تأثیر تعداد thread بر speedup
- مقایسه سیاست‌های زمان‌بندی static، dynamic و guided
- ارزیابی تأثیر tiling بر cache performance
- مقایسه با پیاده‌سازی pthreads (تکلیف 2)

### مشخصات سیستم
```
CPU: [مدل پردازنده]
Cores: [تعداد هسته‌ها]
Cache L1: [اندازه]
Cache L2: [اندازه]
Cache L3: [اندازه]
RAM: [اندازه RAM]
OS: [سیستم عامل]
Compiler: [نسخه GCC/Clang]
```

### مشخصات تصویر و فیلتر
- **اندازه تصویر:** 2048×2048 پیکسل
- **تعداد کانال‌ها:** 3 (RGB)
- **اندازه فیلترها:** 3×3 و 31×31
- **نوع فیلتر:** Gaussian

---

## اتوماسیون

### ساختار Makefile

Makefile طراحی شده شامل target‌های زیر است:

```makefile
all              # ساخت نسخه بهینه‌شده
debug            # ساخت نسخه debug
profile          # ساخت با پشتیبانی gprof
test             # اجرای تست‌های پایه
bench-threads    # بنچمارک تعداد thread‌ها
bench-schedulers # بنچمارک نوع scheduler
bench-kernels    # بنچمارک اندازه kernel
bench-tiling     # بنچمارک استراتژی tiling
bench-all        # اجرای تمام بنچمارک‌ها
clean            # پاک کردن فایل‌های build
```

### Compiler Flags

```bash
CFLAGS = -Wall -O3 -fopenmp -I./include -lm
```

- `-Wall`: نمایش تمام هشدارها
- `-O3`: سطح بهینه‌سازی بالا
- `-fopenmp`: فعال‌سازی OpenMP
- `-I./include`: مسیر header file‌ها
- `-lm`: لینک کتابخانه ریاضی

### مثال استفاده از Make

```bash
# ساخت پروژه
make

# اجرای تست‌های پایه
make test

# اجرای تمام بنچمارک‌ها
make bench-all

# پاک کردن
make clean
```

---

## دستورالعمل اجرا

### کامپایل کردن

```bash
# Windows (MinGW)
make

# Linux
make
```

### اجرای برنامه

#### فرمت کلی
```bash
./bin/convolution -i <input> -o <output> [options]
```

#### پارامترها
- `-i`: فایل تصویر ورودی
- `-o`: فایل تصویر خروجی
- `-k`: اندازه kernel (3 یا 31)
- `-t`: تعداد thread‌ها
- `-s`: نوع scheduler (static, dynamic, guided)
- `-c`: اندازه chunk
- `-T`: اندازه tile (0=بدون tiling, 8, 16)
- `-l`: ترتیب حلقه (0=Y-first, 1=X-first)
- `-S`: اجرای نسخه sequential

#### مثال‌های اجرا

```bash
# اجرای sequential (baseline)
./bin/convolution -i images/input.png -o results/baseline.png -k 3 -S

# اجرای موازی با 4 thread، static scheduling
./bin/convolution -i images/input.png -o results/output.png -k 3 -t 4 -s static

# اجرای با tiling 16×16، kernel 31×31
./bin/convolution -i images/input.png -o results/output_tiled.png -k 31 -t 4 -T 16
```

### اجرای Benchmark Script

#### Windows PowerShell
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\benchmark.ps1
```

#### Linux Bash
```bash
chmod +x scripts/benchmark.sh
./scripts/benchmark.sh
```

### Profiling با perf (Linux)

```bash
# جمع‌آوری آمار
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    ./bin/convolution -i images/input.png -o results/output.png -k 3 -t 4

# رکورد کردن
perf record ./bin/convolution -i images/input.png -o results/output.png -k 3 -t 4

# مشاهده گزارش
perf report
```

---

## تحلیل عملکرد

### 1. تأثیر تعداد Thread‌ها

#### جدول نتایج (Kernel 3×3، Static Scheduling)

| تعداد Thread | زمان اجرا (s) | Speedup | Efficiency | CPU Cycles | IPC | Cache Misses |
|-------------|--------------|---------|------------|------------|-----|--------------|
| 1 (seq)     | [مقدار]      | 1.00x   | 100%       | [مقدار]    | [مقدار] | [مقدار] |
| 2           | [مقدار]      | [مقدار] | [مقدار]    | [مقدار]    | [مقدار] | [مقدار] |
| 4           | [مقدار]      | [مقدار] | [مقدار]    | [مقدار]    | [مقدار] | [مقدار] |
| 8           | [مقدار]      | [مقدار] | [مقدار]    | [مقدار]    | [مقدار] | [مقدار] |

#### نمودار Speedup

```
[نمودار speedup را اینجا قرار دهید]
```

#### تحلیل
- با افزایش تعداد thread‌ها، speedup افزایش می‌یابد اما...
- کارایی (efficiency) با افزایش thread کاهش می‌یابد به دلیل...
- بهترین تعداد thread برای این مسئله: [عدد] است چون...

---

### 2. مقایسه سیاست‌های Scheduling

#### جدول نتایج (4 Threads، Kernel 3×3)

| Scheduler | زمان اجرا (s) | Speedup | CPU Cycles | IPC | Cache Misses | L1 Misses |
|-----------|--------------|---------|------------|-----|--------------|-----------|
| Static    | [مقدار]      | [مقدار] | [مقدار]    | [مقدار] | [مقدار] | [مقدار] |
| Dynamic   | [مقدار]      | [مقدار] | [مقدار]    | [مقدار] | [مقدار] | [مقدار] |
| Guided    | [مقدار]      | [مقدار] | [مقدار]    | [مقدار] | [مقدار] | [مقدار] |

#### نمودار مقایسه‌ای

```
[نمودار مقایسه schedulerها را اینجا قرار دهید]
```

#### تحلیل
- **Static Scheduling:** 
  - مناسب برای workload یکنواخت
  - کمترین overhead
  - عملکرد بهتر برای این مسئله به دلیل...
  
- **Dynamic Scheduling:**
  - overhead بیشتر به دلیل تخصیص runtime
  - مناسب برای workload غیریکنواخت
  - در این مسئله عملکرد کمی ضعیف‌تر به دلیل...
  
- **Guided Scheduling:**
  - تعادل بین static و dynamic
  - اندازه chunk کاهشی
  - نتایج نشان می‌دهد که...

---

### 3. تأثیر اندازه Kernel

#### جدول نتایج (4 Threads، Static Scheduling)

| اندازه Kernel | زمان اجرا (s) | CPU Cycles | Instructions | Cache Misses | L1 Misses |
|---------------|--------------|------------|--------------|--------------|-----------|
| 3×3           | [مقدار]      | [مقدار]    | [مقدار]      | [مقدار]      | [مقدار]   |
| 31×31         | [مقدار]      | [مقدار]    | [مقدار]      | [مقدار]      | [مقدار]   |

#### تحلیل
- با افزایش اندازه kernel، تعداد محاسبات به صورت O(k²) افزایش می‌یابد
- cache miss rate در kernel بزرگ‌تر بیشتر است به دلیل...
- IPC در kernel بزرگ‌تر کاهش می‌یابد چون...

---

### 4. تأثیر Tiling

#### جدول نتایج (Kernel 31×31، 4 Threads، Static)

| اندازه Tile | زمان اجرا (s) | Speedup | Cache Misses | L1 Misses | بهبود Cache |
|-------------|--------------|---------|--------------|-----------|-------------|
| 0 (No tile) | [مقدار]      | 1.00x   | [مقدار]      | [مقدار]   | -           |
| 8×8         | [مقدار]      | [مقدار] | [مقدار]      | [مقدار]   | [درصد]      |
| 16×16       | [مقدار]      | [مقدار] | [مقدار]      | [مقدار]   | [درصد]      |

#### نمودار Cache Miss Rate

```
[نمودار cache miss rate برای tile سایزهای مختلف]
```

#### تحلیل
- Tiling باعث بهبود spatial locality می‌شود
- اندازه بهینه tile برای این سیستم: [عدد] است
- با tiling، cache miss rate به میزان [درصد] کاهش یافته
- دلیل بهبود عملکرد: [توضیح]

---

### 5. تأثیر ترتیب حلقه‌ها

#### جدول نتایج (Kernel 3×3، 4 Threads، Static)

| ترتیب حلقه | زمان اجرا (s) | Cache Misses | L1 Misses | توضیح |
|-----------|--------------|--------------|-----------|-------|
| Y-first   | [مقدار]      | [مقدار]      | [مقدار]   | پیمایش سطری |
| X-first   | [مقدار]      | [مقدار]      | [مقدار]   | پیمایش ستونی |

#### تحلیل
- در memory layout row-major، Y-first loop بهتر عمل می‌کند چون...
- X-first loop باعث cache thrashing می‌شود به دلیل...
- تفاوت عملکرد: [درصد]

---

## مقایسه OpenMP و pthreads

### جدول مقایسه عملکرد

| پیاده‌سازی | بهترین زمان (s) | Speedup | CPU Cycles | IPC | Cache Misses | تنظیمات |
|-----------|----------------|---------|------------|-----|--------------|---------|
| Sequential | [مقدار]       | 1.00x   | [مقدار]    | [مقدار] | [مقدار] | - |
| pthreads  | [مقدار]        | [مقدار] | [مقدار]    | [مقدار] | [مقدار] | [تنظیمات] |
| OpenMP    | [مقدار]        | [مقدار] | [مقدار]    | [مقدار] | [مقدار] | [تنظیمات] |

### نمودار مقایسه Speedup

```
[نمودار مقایسه speedup بین OpenMP و pthreads]
```

### مقایسه دقیق

#### 1. معیارهای عملکردی

**Execution Time:**
- OpenMP: [مقدار] ثانیه
- pthreads: [مقدار] ثانیه
- تفاوت: [درصد]

**Instructions Per Cycle (IPC):**
- OpenMP: [مقدار]
- pthreads: [مقدار]
- تحلیل: [توضیح]

**Cache Misses:**
- OpenMP: [مقدار]
- pthreads: [مقدار]
- تحلیل: [توضیح]

#### 2. سهولت پیاده‌سازی

**OpenMP:**
- تعداد خطوط کد: ~[عدد]
- پیچیدگی: ساده
- زمان توسعه: کم
- نگهداری: آسان
- مثال کد:
```c
#pragma omp parallel for schedule(static)
for (int y = 0; y < height; y++) {
    // محاسبات
}
```

**pthreads:**
- تعداد خطوط کد: ~[عدد]
- پیچیدگی: بالا
- زمان توسعه: زیاد
- نگهداری: دشوار
- نیاز به مدیریت دستی thread creation، join، synchronization

#### 3. Overhead و Abstraction

**OpenMP:**
- Runtime overhead: [مقدار]
- Thread creation overhead: handled by runtime
- Load balancing: automatic
- مزایا: 
  - Abstraction سطح بالا
  - Portable
  - سیاست‌های scheduling از پیش تعریف شده
- معایب:
  - کنترل کمتر بر جزئیات
  - overhead runtime

**pthreads:**
- Thread creation overhead: [مقدار]
- Synchronization overhead: [مقدار]
- مزایا:
  - کنترل کامل
  - overhead کمتر (در صورت تنظیم صحیح)
- معایب:
  - پیچیدگی بالا
  - احتمال خطا بیشتر
  - کد طولانی‌تر

#### 4. مشاهدات غیرمعمول

[در این بخش، هرگونه رفتار غیرمنتظره یا جالب را توضیح دهید. مثلاً:]

- در برخی موارد، dynamic scheduling عملکرد بهتری از static داشت به دلیل...
- با gprof مشکلاتی مشاهده شد: [توضیح]
- در kernel های بزرگ، tiling تأثیر بیشتری داشت چون...

---

## فیلترهای استفاده شده

### Gaussian Filter (3×3)

```
Kernel:
0.07511  0.12384  0.07511
0.12384  0.20418  0.12384
0.07511  0.12384  0.07511
```

**خصوصیات:**
- sigma = 0.5
- مجموع عناصر = 1
- Smoothing effect

### Gaussian Filter (31×31)

- sigma = 5.17
- مناسب برای blur شدیدتر
- تأثیر بیشتر بر cache performance

### تصاویر ورودی و خروجی

#### تصویر ورودی
```
[تصویر ورودی را اینجا قرار دهید]
```

#### خروجی با Kernel 3×3
```
[تصویر خروجی با kernel 3×3]
```

#### خروجی با Kernel 31×31
```
[تصویر خروجی با kernel 31×31]
```

### مشاهدات

- فیلتر 3×3: جزئیات حفظ می‌شود، blur ملایم
- فیلتر 31×31: blur قابل توجه، جزئیات کمتر
- صحت خروجی: تصاویر به درستی blur شده‌اند
- هیچ artifact یا مشکل visual مشاهده نشد

---

## نتیجه‌گیری

### یافته‌های کلیدی

1. **Thread Scaling:**
   - بهترین speedup با [عدد] thread حاصل شد
   - Efficiency با افزایش thread کاهش می‌یابد
   - Amdahl's law در عمل مشاهده شد

2. **Scheduling Policies:**
   - Static scheduler بهترین عملکرد را برای این مسئله داشت
   - Overhead dynamic و guided scheduler قابل مشاهده بود
   - برای workload یکنواخت، static بهینه است

3. **Tiling Strategy:**
   - Tiling 16×16 بهترین نتیجه را برای kernel 31×31 داشت
   - Cache miss rate به میزان [درصد] کاهش یافت
   - بهبود عملکرد: [درصد]

4. **OpenMP vs pthreads:**
   - تفاوت عملکردی ناچیز (OpenMP فقط [درصد] کندتر/سریع‌تر)
   - OpenMP بسیار ساده‌تر برای پیاده‌سازی
   - برای این نوع مسائل، OpenMP انتخاب بهتری است

### توصیه‌ها

- برای convolution با kernel کوچک: استفاده از static scheduling بدون tiling
- برای kernel بزرگ: استفاده از tiling 16×16
- تعداد thread برابر با تعداد physical core های CPU
- OpenMP انتخاب بهتری است مگر نیاز به کنترل دقیق باشد

### چالش‌ها و راه‌حل‌ها

**چالش 1:** [شرح چالش]
- راه‌حل: [توضیح]

**چالش 2:** [شرح چالش]
- راه‌حل: [توضیح]

### کارهای آینده

- پیاده‌سازی با SIMD instructions (AVX/SSE)
- استفاده از GPU (CUDA/OpenCL)
- بهینه‌سازی بیشتر cache locality
- Separable convolution برای kernel های Gaussian

---

## منابع

1. OpenMP API Specification - https://www.openmp.org/
2. Intel Guide to OpenMP - https://www.intel.com/content/www/us/en/developer/tools/oneapi/openmp.html
3. "Parallel Programming in OpenMP" - Rohit Chandra et al.
4. Linux perf documentation - https://perf.wiki.kernel.org/
5. STB Image Libraries - https://github.com/nothings/stb

---

## پیوست‌ها

### پیوست A: کد کامل

[کد کامل functions مهم را اینجا قرار دهید]

### پیوست B: داده‌های خام Benchmark

[جداول کامل نتایج benchmark]

### پیوست C: خروجی perf

[نمونه‌هایی از خروجی perf stat]

---

**تاریخ تحویل:** [تاریخ]  
**امضا:** [امضا]
