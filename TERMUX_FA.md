# راهنمای فارسی: انتشار MergeMint 2048 با Termux و GitHub

## ۱) آماده‌سازی فایل‌ها
1. فایل ZIP پروژه را در پوشه Download گوشی ذخیره و از حالت فشرده خارج کن؛ پوشه داخل آن `mm` است.
2. Termux را باز کن و این دستورها را اجرا کن:

```bash
termux-setup-storage
pkg update
pkg install git unzip openjdk-17
```

3. اگر فایل را در Download گذاشتی:

```bash
cd /storage/emulated/0/Download
unzip -o MergeMint2048_Termux_Ready.zip
```

## ۲) کپی پروژه در مخزن GitHub
اگر مخزن `2048` از قبل وجود دارد، آن را کلون کن:

```bash
cd ~
git clone https://github.com/hesameghbalei1393-cyber/2048.git MergeMint2048
cp -r /storage/emulated/0/Download/mm/. ~/MergeMint2048/
cd ~/MergeMint2048
```

اگر پوشه استخراج‌شده اسم دیگری دارد، فقط مسیر `.../Download/mm/` را با مسیر واقعی پوشه عوض کن.

سپس:

```bash
git add .
git commit -m "Update MergeMint 2048 app and Android build"
git push
```

اگر GitHub نام کاربری و رمز خواست، رمز معمولی حساب کار نمی‌کند؛ باید از Personal Access Token استفاده کنی. توکن را داخل فایل پروژه یا پیام عمومی نگذار.

## ۳) ساخت کلید امضای دائمی (خیلی مهم برای آپدیت مایکت)
این مرحله را فقط یک بار انجام بده و فایل کلید را گم نکن. هر نسخه‌ای که برای آپدیت منتشر می‌کنی باید با همان کلید امضا شود.

```bash
mkdir -p ~/mergemint-signing
keytool -genkeypair -v -keystore ~/mergemint-signing/mergemint-release.jks -alias mergemint2048 -keyalg RSA -keysize 2048 -validity 10000
```

برای رمزها، یک رمز قوی بگذار و در جای امن نگه‌دار. بعد رشتهٔ Base64 را بساز:

```bash
base64 ~/mergemint-signing/mergemint-release.jks | tr -d '\n'
```

خروجی طولانی را کپی کن. در GitHub برو به مخزن `2048` → **Settings** → **Secrets and variables** → **Actions** → **New repository secret** و این ۴ Secret را بساز:

- `KEYSTORE_BASE64` : کل خروجی Base64
- `KEYSTORE_PASSWORD` : رمز keystore
- `KEY_PASSWORD` : رمز کلید (اگر در keytool همان رمز را انتخاب کردی، همان را وارد کن)
- `KEY_ALIAS` : مقدار `mergemint2048`

**فایل `.jks`، رمزها یا Base64 را در GitHub داخل کدها commit نکن.** فقط در قسمت Secrets بگذار. این کلید خصوصی است.

## ۴) ساخت APK در GitHub
1. در مخزن GitHub بخش **Actions** را باز کن.
2. گردش‌کار **Build signed release APK** را انتخاب کن.
3. روی **Run workflow** بزن و اجرای آن را باز کن.
4. وقتی سبز و موفق شد، پایین صفحهٔ همان اجرا بخش **Artifacts** را پیدا کن و `MergeMint-2048-release` را دانلود کن.
5. ZIP دانلودشده را باز کن؛ فایل `app-release.apk` داخل آن است.

اگر Build شکست خورد، وارد همان اجرای قرمز شو و متن اولین خطای واقعی را بفرست.

## نکته‌ها
- شناسهٔ برنامه `studio.eight8.mergemint2048` است؛ بعد از انتشار عوضش نکن.
- کلید امضای دائمی را در چند جای امن نگه‌دار. اگر آن را از دست بدهی، ممکن است نتوانی APK جدید را به‌عنوان آپدیت همان برنامه در مایکت منتشر کنی.
- خود Termux برای این روش فقط مدیریت فایل و Git را انجام می‌دهد؛ ساخت APK روی سرورهای GitHub Actions انجام می‌شود.
