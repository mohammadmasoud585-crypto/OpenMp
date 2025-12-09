#!/bin/bash
# اسکریپت دانلود کتابخانه‌های واقعی STB

echo "در حال دانلود کتابخانه‌های STB..."

# دانلود stb_image.h
echo "دانلود stb_image.h..."
wget -q https://raw.githubusercontent.com/nothings/stb/master/stb_image.h -O include/stb_image.h
if [ $? -eq 0 ]; then
    echo "✓ stb_image.h دانلود شد"
else
    echo "✗ خطا در دانلود stb_image.h"
    echo "لطفاً دستی دانلود کنید از: https://github.com/nothings/stb/blob/master/stb_image.h"
fi

# دانلود stb_image_write.h
echo "دانلود stb_image_write.h..."
wget -q https://raw.githubusercontent.com/nothings/stb/master/stb_image_write.h -O include/stb_image_write.h
if [ $? -eq 0 ]; then
    echo "✓ stb_image_write.h دانلود شد"
else
    echo "✗ خطا در دانلود stb_image_write.h"
    echo "لطفاً دستی دانلود کنید از: https://github.com/nothings/stb/blob/master/stb_image_write.h"
fi

echo ""
echo "کتابخانه‌ها دانلود شدند!"
echo "حالا می‌توانید پروژه را کامپایل کنید: make"
