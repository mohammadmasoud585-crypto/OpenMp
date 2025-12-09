# ⚠️ مشکل کتابخانه‌های STB - راه‌حل

## مشکل:

کتابخانه‌های `stb_image.h` و `stb_image_write.h` که در پروژه هستند **stub** (ساختگی) هستند و واقعاً تصویر را load/save نمی‌کنند!

به همین دلیل:
- برنامه خیلی سریع اجرا می‌شود (چند ثانیه)
- روی داده خالی کار می‌کند
- نتایج معنادار نیستند

## ✅ راه‌حل:

### روش 1: دانلود خودکار (Linux)

```bash
# اجرای اسکریپت دانلود
chmod +x scripts/download_stb.sh
./scripts/download_stb.sh
```

### روش 2: دانلود دستی

#### 1. دانلود stb_image.h
```bash
wget https://raw.githubusercontent.com/nothings/stb/master/stb_image.h -O include/stb_image.h

# یا با curl:
curl https://raw.githubusercontent.com/nothings/stb/master/stb_image.h -o include/stb_image.h
```

#### 2. دانلود stb_image_write.h
```bash
wget https://raw.githubusercontent.com/nothings/stb/master/stb_image_write.h -O include/stb_image_write.h

# یا با curl:
curl https://raw.githubusercontent.com/nothings/stb/master/stb_image_write.h -o include/stb_image_write.h
```

### روش 3: دانلود از مرورگر

1. باز کنید: https://github.com/nothings/stb
2. دانلود کنید:
   - `stb_image.h`
   - `stb_image_write.h`
3. کپی کنید به پوشه `include/`

## بعد از دانلود:

```bash
# پاکسازی
make clean

# کامپایل مجدد
make

# تست
./bin/convolution -i images/input.png -o results/test.png -k 3 -t 4
```

## چگونه بفهمیم کار کرد؟

### قبل از اصلاح (STUB):
- زمان اجرا: 1-3 ثانیه ⚡ (خیلی سریع - اشتباه!)
- تصویر خروجی: خالی یا سیاه
- محاسبات معنادار نیست

### بعد از اصلاح (واقعی):
- زمان اجرا: 
  - Sequential (k=3, 2048×2048): 10-20 ثانیه ✅
  - Parallel (k=3, 4 threads): 3-7 ثانیه ✅
  - Kernel 31×31: چند دقیقه! ✅
- تصویر خروجی: blur شده و قابل مشاهده ✅
- محاسبات معنادار ✅

## تست سریع:

```bash
# بعد از دانلود کتابخانه‌های واقعی
time ./bin/convolution -i images/input.png -o results/test.png -k 3 -S

# اگر بیشتر از 10 ثانیه طول کشید → درست کار می‌کند ✅
# اگر زیر 3 ثانیه بود → هنوز مشکل دارد ❌
```

## لینک‌های مفید:

- STB GitHub: https://github.com/nothings/stb
- stb_image.h: https://raw.githubusercontent.com/nothings/stb/master/stb_image.h
- stb_image_write.h: https://raw.githubusercontent.com/nothings/stb/master/stb_image_write.h

---

**⚠️ بدون کتابخانه‌های واقعی STB، نتایج benchmark معنادار نیستند!**
