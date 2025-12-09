# خلاصه پروژه OpenMP 2D Convolution

## ✅ فایل‌های ایجاد شده

### 📁 ساختار پروژه

```
OpenMp/
├── src/                          # کدهای منبع
│   ├── main.c                    # برنامه اصلی با argument parsing
│   ├── convolution.c             # پیاده‌سازی‌های مختلف convolution
│   └── image_utils.c             # توابع کمکی برای کار با تصویر
│
├── include/                      # Header files
│   ├── convolution.h             # تعاریف و prototype ها
│   ├── stb_image.h              # کتابخانه خواندن تصویر
│   └── stb_image_write.h        # کتابخانه نوشتن تصویر
│
├── scripts/                      # اسکریپت‌های کمکی
│   ├── benchmark.ps1            # بنچمارک کامل (Windows PowerShell)
│   ├── benchmark.sh             # بنچمارک کامل (Linux Bash)
│   ├── quick_test.ps1           # تست سریع (Windows)
│   ├── quick_test.sh            # تست سریع (Linux)
│   └── generate_test_images.py  # تولید تصاویر تست
│
├── images/                       # تصاویر ورودی (باید ایجاد شوند)
├── results/                      # تصاویر خروجی و نتایج
│
├── Makefile                      # اتوماسیون build
├── README.md                     # مستندات کامل
├── QUICKSTART.md                 # راهنمای سریع فارسی
├── REPORT_TEMPLATE.md            # قالب گزارش فارسی
├── .gitignore                    # فایل‌های ignore شده
└── PROJECT_SUMMARY.md            # این فایل
```

## 🎯 ویژگی‌های پیاده‌سازی شده

### 1. پیاده‌سازی‌های مختلف Convolution

#### Sequential (Baseline)
- پیاده‌سازی ساده بدون موازی‌سازی
- برای مقایسه و محاسبه speedup

#### OpenMP Parallel
- موازی‌سازی با `#pragma omp parallel for`
- پشتیبانی از 3 نوع scheduler:
  * **Static**: تخصیص ثابت iterations
  * **Dynamic**: تخصیص پویا در runtime
  * **Guided**: اندازه chunk کاهشی
- قابلیت تنظیم chunk size
- دو ترتیب حلقه: Y-first و X-first

#### OpenMP Tiled
- پیاده‌سازی با tiling برای بهبود cache locality
- پشتیبانی از tile های 8×8 و 16×16
- موازی‌سازی روی tile ها
- collapse(2) برای بهبود load balancing

### 2. ویژگی‌های Image Processing

- **فرمت‌های پشتیبانی شده**: PNG, JPEG, BMP
- **نوع تصاویر**: RGB (3 کانال)
- **اندازه kernel**: 3×3 و 31×31
- **نوع فیلترها**:
  * Gaussian filter (با sigma قابل تنظیم)
  * Box filter (میانگین)
- **Boundary handling**: Zero-padding

### 3. پارامترهای قابل تنظیم

```bash
-i <input>      # فایل تصویر ورودی
-o <output>     # فایل تصویر خروجی
-k <size>       # اندازه kernel (3 یا 31)
-t <threads>    # تعداد thread ها
-s <scheduler>  # نوع scheduler (static/dynamic/guided)
-c <chunk>      # اندازه chunk
-l <order>      # ترتیب حلقه (0=Y-first, 1=X-first)
-T <tile>       # اندازه tile (0/8/16)
-f <filter>     # نوع فیلتر (gaussian/box)
-S              # اجرای sequential
```

## 🔧 Makefile Targets

```bash
make                  # Build optimized version
make debug            # Build debug version
make profile          # Build with gprof
make test             # Run basic tests
make bench-threads    # Benchmark thread scaling
make bench-schedulers # Benchmark schedulers
make bench-kernels    # Benchmark kernel sizes
make bench-tiling     # Benchmark tiling
make bench-all        # Run all benchmarks
make clean            # Clean build files
```

## 📊 Benchmark Scripts

### PowerShell Script (benchmark.ps1)
- اجرای خودکار تمام تست‌ها
- ذخیره نتایج در CSV
- محاسبه speedup نسبت به baseline
- تولید گزارش خلاصه
- رنگ‌آمیزی خروجی

### Bash Script (benchmark.sh)
- مشابه PowerShell
- سازگار با Linux
- قابلیت پروفایلینگ با perf

### تست‌های انجام شده:
1. Thread scaling (1, 2, 4, 8 threads)
2. Scheduler comparison (static, dynamic, guided)
3. Kernel size comparison (3×3 vs 31×31)
4. Tiling strategies (no tiling, 8×8, 16×16)
5. Loop ordering (Y-first vs X-first)
6. Combined optimizations

## 📈 معیارهای Performance

برنامه این معیارها را اندازه‌گیری می‌کند:
- **Execution Time**: زمان اجرا (wall-clock)
- **Speedup**: نسبت زمان sequential به موازی
- **Efficiency**: Speedup / تعداد thread
- **CPU Cycles**: با perf (Linux)
- **Instructions**: با perf (Linux)
- **IPC**: Instructions Per Cycle
- **Cache Misses**: تعداد cache miss ها
- **L1 Data Cache Misses**: با perf (Linux)

## 🚀 نحوه استفاده

### گام 1: تولید تصاویر تست
```bash
python scripts/generate_test_images.py
```

### گام 2: کامپایل
```bash
make
```

### گام 3: تست سریع
```bash
# Windows
.\scripts\quick_test.ps1

# Linux
./scripts/quick_test.sh
```

### گام 4: بنچمارک کامل
```bash
# Windows
.\scripts\benchmark.ps1

# Linux
./scripts/benchmark.sh
```

### گام 5: تحلیل نتایج
- نتایج در `results/benchmark_results.csv`
- تصاویر خروجی در `results/`
- داده‌های perf در `results/perf_data/`

## 📝 نوشتن گزارش

1. از template `REPORT_TEMPLATE.md` استفاده کنید
2. نتایج benchmark را در جداول قرار دهید
3. نمودارها را رسم کنید (Excel یا Python/matplotlib)
4. تحلیل کنید (فقط داده نگذارید!)
5. با pthreads مقایسه کنید
6. screenshot تصاویر را اضافه کنید

### بخش‌های مهم گزارش:
- ✅ توضیح Makefile و automation
- ✅ دستورالعمل compile و اجرا
- ✅ تحلیل thread scaling
- ✅ مقایسه scheduler ها
- ✅ تأثیر kernel size
- ✅ تأثیر tiling
- ✅ تأثیر loop ordering
- ✅ مقایسه OpenMP vs pthreads
- ✅ تصاویر ورودی/خروجی

## 🔍 نکات مهم

### برای عملکرد بهتر:
1. از **static scheduler** برای convolution استفاده کنید
2. **تعداد thread** را با physical core های CPU تطبیق دهید
3. برای kernel بزرگ (31×31)، **tiling** را فعال کنید
4. **Y-first loop** معمولاً بهتر است (row-major memory)
5. **-O3 optimization** را فعال کنید

### برای debugging:
1. ابتدا با تصویر کوچک تست کنید
2. از `make debug` استفاده کنید
3. sequential و parallel را مقایسه کنید
4. تصاویر خروجی را بررسی کنید

### برای profiling:
1. **Linux**: از perf استفاده کنید (بهترین گزینه)
2. **همه سیستم‌ها**: از gprof استفاده کنید (اگر کار کند)
3. **همه سیستم‌ها**: حداقل timing را اندازه بگیرید

## 🐛 مشکلات رایج و راه‌حل

### مشکل: OpenMP فعال نیست
```bash
# بررسی
echo | gcc -fopenmp -E -dM - | grep -i openmp

# راه‌حل: نصب GCC با OpenMP support
```

### مشکل: تصویر لود نمی‌شود
- فرمت را بررسی کنید (PNG, JPG, BMP)
- مسیر فایل را چک کنید
- سایز فایل را بررسی کنید

### مشکل: عملکرد خیلی پایین
- `-O3` را فعال کنید
- تعداد thread را تنظیم کنید
- از static scheduler استفاده کنید

## 📚 منابع و مراجع

### مستندات
- [README.md](README.md): مستندات کامل انگلیسی
- [QUICKSTART.md](QUICKSTART.md): راهنمای سریع فارسی
- [REPORT_TEMPLATE.md](REPORT_TEMPLATE.md): قالب گزارش فارسی

### لینک‌های مفید
- OpenMP API: https://www.openmp.org/
- GCC OpenMP: https://gcc.gnu.org/onlinedocs/libgomp/
- perf Tutorial: https://perf.wiki.kernel.org/
- STB Libraries: https://github.com/nothings/stb

## ✨ ویژگی‌های پیشرفته

### 1. First-touch Initialization
- Output array با calloc مقداردهی می‌شود
- Memory به درستی توزیع می‌شود

### 2. Collapse Directive
- در tiled version از `collapse(2)` استفاده شده
- بهبود load balancing

### 3. Smart Boundary Handling
- Zero-padding برای pixel های خارج از مرز
- بدون overhead اضافی

### 4. Cache-Friendly Memory Layout
- Row-major order
- Contiguous memory access
- Optimized for spatial locality

## 🎓 یادگیری‌ها

این پروژه شامل این مفاهیم است:
- ✅ OpenMP directives و clauses
- ✅ Thread management و scheduling
- ✅ Load balancing strategies
- ✅ Cache optimization
- ✅ Performance profiling
- ✅ Parallel algorithm design
- ✅ Image processing basics
- ✅ Benchmark methodology

## 📦 فایل‌های لازم برای تحویل

```
PA-F25-[نام]-[شماره]-HW3.zip
├── src/
├── include/
├── scripts/
├── Makefile
├── README.md
├── گزارش.pdf (یا .docx)
└── تصاویر/ (screenshots و نمودارها)
```

## ⏰ Deadline

**تاریخ تحویل:** 2025/12/12

## 👨‍🏫 اطلاعات درس

- **درس:** Parallel Algorithms
- **استاد:** Prof. Farshad Khunjush
- **دستیاران:** AmirMohammad Kamalinia, Amirreza Rezvani
- **تکلیف:** HW3 - OpenMP 2D Convolution

## ✅ Checklist نهایی

قبل از تحویل:
- [ ] کد کامپایل می‌شود بدون خطا
- [ ] تمام تست‌ها pass می‌شوند
- [ ] Benchmark اجرا شده و نتایج جمع‌آوری شده
- [ ] نمودارها رسم شده‌اند
- [ ] گزارش کامل نوشته شده
- [ ] با pthreads مقایسه شده
- [ ] تصاویر ورودی/خروجی اضافه شده
- [ ] فایل ZIP آماده است
- [ ] نام و شماره دانشجویی درست است

## 💡 نکته پایانی

این پروژه یک پیاده‌سازی کامل و حرفه‌ای است که:
- ✨ کد تمیز و documented
- 🚀 عملکرد بهینه
- 📊 قابلیت benchmark کامل
- 🔧 پیکربندی آسان
- 📚 مستندات جامع
- 🧪 قابل تست

موفق باشید! 🎉
