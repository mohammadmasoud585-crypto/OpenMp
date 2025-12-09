# دستورالعمل سریع - OpenMP 2D Convolution

## نصب و آماده‌سازی

### Windows (MinGW/TDM-GCC)

1. نصب MinGW یا TDM-GCC:
   - دانلود از: https://jmeubank.github.io/tdm-gcc/ یا https://www.mingw-w64.org/
   - حتماً OpenMP را در زمان نصب انتخاب کنید

2. نصب Make:
   - از MinGW Installation Manager، mingw32-make را نصب کنید
   - یا از chocolatey: `choco install make`

3. نصب Python (برای تولید تصاویر تست):
   ```powershell
   # نصب Python
   # دانلود از python.org
   
   # نصب کتابخانه‌های لازم
   pip install pillow numpy
   ```

### Linux

```bash
# نصب GCC با OpenMP
sudo apt-get install build-essential gcc g++

# نصب perf (اختیاری)
sudo apt-get install linux-tools-common linux-tools-generic

# نصب Python dependencies
pip install pillow numpy
```

## راه‌اندازی سریع

### گام 1: تولید تصاویر تست

```bash
# اجرای اسکریپت Python
python scripts/generate_test_images.py
```

این دستور چندین تصویر تست ایجاد می‌کند:
- `images/input.png` (2048×2048) - تصویر اصلی
- `images/input_small.png` (512×512) - برای تست سریع
- سایر pattern ها

### گام 2: کامپایل

```bash
# Windows
make

# یا با mingw32-make
mingw32-make

# Linux
make
```

### گام 3: تست اولیه

```bash
# اجرای sequential (baseline)
./bin/convolution -i images/input.png -o results/baseline.png -k 3 -S

# اجرای موازی با 4 thread
./bin/convolution -i images/input.png -o results/output.png -k 3 -t 4
```

### گام 4: اجرای Benchmark

#### Windows PowerShell
```powershell
# اجازه اجرای اسکریپت
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# اجرای benchmark
.\scripts\benchmark.ps1
```

#### Linux Bash
```bash
chmod +x scripts/benchmark.sh
./scripts/benchmark.sh
```

## دستورات مفید

### کامپایل

```bash
make              # Build optimized
make debug        # Build debug version
make profile      # Build with gprof support
make clean        # Clean build files
make distclean    # Clean everything
```

### تست‌های سریع

```bash
# تست با تصویر کوچک
./bin/convolution -i images/input_small.png -o results/test.png -k 3 -t 4

# مقایسه schedulerها
./bin/convolution -i images/input.png -o results/static.png -k 3 -t 4 -s static
./bin/convolution -i images/input.png -o results/dynamic.png -k 3 -t 4 -s dynamic
./bin/convolution -i images/input.png -o results/guided.png -k 3 -t 4 -s guided

# تست با kernel بزرگ
./bin/convolution -i images/input.png -o results/k31.png -k 31 -t 4

# تست با tiling
./bin/convolution -i images/input.png -o results/tiled.png -k 31 -t 4 -T 16
```

### Profiling

#### با gprof (همه سیستم‌ها)
```bash
# کامپایل با profiling
make profile

# اجرا
./bin/convolution_prof -i images/input.png -o results/output.png -k 3 -t 4

# مشاهده گزارش
gprof bin/convolution_prof gmon.out > results/profile.txt
```

#### با perf (Linux)
```bash
# جمع‌آوری آمار
perf stat -e cycles,instructions,cache-misses,L1-dcache-load-misses \
    ./bin/convolution -i images/input.png -o results/output.png -k 3 -t 4

# رکورد برای تحلیل دقیق‌تر
perf record -g ./bin/convolution -i images/input.png -o results/output.png -k 3 -t 4

# مشاهده گزارش
perf report
```

## پارامترهای برنامه

```
-i <file>     تصویر ورودی (الزامی)
-o <file>     تصویر خروجی (الزامی)
-k <size>     اندازه kernel: 3 یا 31 (پیش‌فرض: 3)
-t <num>      تعداد thread (پیش‌فرض: 4)
-s <type>     scheduler: static, dynamic, guided (پیش‌فرض: static)
-c <size>     chunk size (پیش‌فرض: 1)
-l <order>    ترتیب حلقه: 0=Y-first, 1=X-first (پیش‌فرض: 0)
-T <size>     tile size: 0, 8, 16 (پیش‌فرض: 0=no tiling)
-f <type>     نوع فیلتر: gaussian, box (پیش‌فرض: gaussian)
-S            اجرای sequential
-h            راهنما
```

## ترتیب انجام تکلیف

### مرحله 1: تست اولیه و بررسی صحت
```bash
# 1. تولید تصاویر
python scripts/generate_test_images.py

# 2. اجرای sequential
./bin/convolution -i images/input_small.png -o results/test_seq.png -k 3 -S

# 3. اجرای موازی
./bin/convolution -i images/input_small.png -o results/test_par.png -k 3 -t 4

# 4. مقایسه بصری تصاویر خروجی
```

### مرحله 2: Thread Scaling
```bash
# اجرا با تعداد thread های مختلف
for t in 1 2 4 8; do
    ./bin/convolution -i images/input.png -o results/threads_$t.png -k 3 -t $t -s static
done
```

### مرحله 3: Scheduler Comparison
```bash
# مقایسه schedulerها
for s in static dynamic guided; do
    ./bin/convolution -i images/input.png -o results/sched_$s.png -k 3 -t 4 -s $s
done
```

### مرحله 4: Kernel Size
```bash
# تست با kernel های مختلف
./bin/convolution -i images/input.png -o results/kernel_3.png -k 3 -t 4
./bin/convolution -i images/input.png -o results/kernel_31.png -k 31 -t 4
```

### مرحله 5: Tiling
```bash
# تست tiling
./bin/convolution -i images/input.png -o results/notile.png -k 31 -t 4 -T 0
./bin/convolution -i images/input.png -o results/tile8.png -k 31 -t 4 -T 8
./bin/convolution -i images/input.png -o results/tile16.png -k 31 -t 4 -T 16
```

### مرحله 6: Loop Ordering
```bash
# تست ترتیب حلقه
./bin/convolution -i images/input.png -o results/loop_y.png -k 3 -t 4 -l 0
./bin/convolution -i images/input.png -o results/loop_x.png -k 3 -t 4 -l 1
```

### مرحله 7: Benchmark کامل
```bash
# اجرای اسکریپت benchmark
# Windows:
.\scripts\benchmark.ps1

# Linux:
./scripts/benchmark.sh
```

### مرحله 8: تحلیل نتایج
```bash
# نتایج در فایل CSV ذخیره می‌شوند
cat results/benchmark_results.csv

# می‌توانید با Excel یا Python تحلیل کنید
```

## عیب‌یابی

### مشکل: OpenMP کار نمی‌کند
```bash
# بررسی پشتیبانی OpenMP
echo | gcc -fopenmp -E -dM - | grep -i openmp

# باید چیزی شبیه این ببینید:
# #define _OPENMP 201511
```

### مشکل: تصویر لود نمی‌شود
- فرمت تصویر را بررسی کنید (PNG، JPG، BMP)
- مسیر فایل را بررسی کنید
- اطمینان حاصل کنید فایل corrupt نیست

### مشکل: عملکرد بسیار پایین
- تعداد thread را با تعداد core های CPU تطبیق دهید
- `-O3` optimization را فعال کنید
- از static scheduling برای workload یکنواخت استفاده کنید

### مشکل: پیغام خطا در کامپایل
```bash
# نصب دوباره با dependencies
# Windows: حتماً OpenMP را در نصب MinGW انتخاب کنید
# Linux: نصب build-essential
sudo apt-get install build-essential
```

## نکات مهم برای گزارش

1. **داده‌های واقعی:** حتماً برنامه را اجرا کنید و نتایج واقعی جمع‌آوری کنید
2. **نمودارها:** از matplotlib یا Excel برای رسم نمودار استفاده کنید
3. **تحلیل:** فقط داده نگذارید، تحلیل و توضیح بدهید
4. **تصاویر:** screenshot های تصاویر ورودی و خروجی را اضافه کنید
5. **مقایسه:** حتماً با پیاده‌سازی pthreads (HW2) مقایسه کنید

## منابع مفید

- OpenMP Tutorial: https://www.openmp.org/resources/tutorials-articles/
- GCC OpenMP: https://gcc.gnu.org/onlinedocs/libgomp/
- perf Tutorial: https://perf.wiki.kernel.org/index.php/Tutorial
- Image Convolution: https://en.wikipedia.org/wiki/Kernel_(image_processing)

## سؤالات متداول

**Q: چند thread استفاده کنم؟**
A: شروع با تعداد physical core های CPU. معمولاً 4-8 thread بهینه است.

**Q: کدام scheduler بهتر است؟**
A: برای convolution که workload یکنواخت دارد، معمولاً static بهتر است.

**Q: آیا باید tiling استفاده کنم؟**
A: برای kernel های بزرگ (31×31)، tiling کمک می‌کند. برای کوچک (3×3) تأثیر کمی دارد.

**Q: چگونه با pthreads مقایسه کنم؟**
A: همان تصویر و kernel را استفاده کنید. زمان اجرا، cache miss و IPC را مقایسه کنید.

**Q: gprof کار نمی‌کند؟**
A: در برخی سیستم‌ها، gprof با OpenMP مشکل دارد. از perf (Linux) یا timing ساده استفاده کنید.
