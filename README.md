# Pomodoro Video - Flutter Project

ملف مشروع Flutter لتطبيق Pomodoro احترافي مع هذه الميزات:
- خلفية فيديو: تحميل ملف من الجهاز أو إدخال رابط فيديو (network).
- إعدادات مدة العمل، الاستراحة القصيرة والطويلة، ودورات قبل الاستراحة الطويلة.
- إشعارات محلية وصوت إشعار باستخدام `flutter_local_notifications`.
- حفظ الإعدادات باستخدام `shared_preferences`.
- أمثلة لاختصارات التشغيل/إيقاف وإعادة التعيين.
- ملف GitHub Actions جاهز لبناء APK تلقائيًا.

---

## خطوات لتثبيت وبناء APK محليًا (على جهازك)

1. ثبّت Flutter (اتبع https://flutter.dev).
2. افتح سطر الأوامر في مجلد المشروع:
   ```bash
   cd pomodoro_video_project
   flutter pub get
   flutter build apk --release
   ```
   سيُنتِج الملف `build/app/outputs/flutter-apk/app-release.apk`

3. أو للتجربة السريعة أثناء التطوير:
   ```bash
   flutter run
   ```

---

## بناء APK تلقائيًا باستخدام GitHub Actions
يوجد ملف `.github/workflows/build_apk.yml` مرفق. قم بتحميل المشروع على مستودع GitHub وقم بتفعيل Actions لبناء APK تلقائيًا عند كل `push`.

---

## ملاحظات مهمة
- لا يمكنني بناء APK داخل هذا البيئة نيابةً عنك (يتطلب Android SDK وبيئة بناء). ما فعلته هنا هو تجهيز مشروع كامل يمكنك تحميله وبناؤه محليًا أو عبر GitHub Actions.
- إذا تبي، أقدملك ملف APK مبنيًا — لكني سأحتاج منك رفع مفتاح التوقيع أو أن أستخدم خدمة بناء خارجية (أرشِح GitHub Actions أو Codemagic) — أخبرني إذا تبي أشرح خطوة بخطوة لرفع المشروع على GitHub وتشغيل البناء الأتوماتيكي.

