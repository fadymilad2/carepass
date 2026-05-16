import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ملف فايربيز اللي نزلته
import 'core/router/app_router.dart';
import 'core/di/service_locator.dart'; // مسار ملف الـ GetIt

void main() async {
  // 1. التأكد من تهيئة فلاتر قبل تشغيل أي كود خارجي
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة فايربيز
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. تهيئة حقن الاعتماديات (GetIt)
  await setupDependencies(); // أو اسم الدالة اللي عاملها في service_locator.dart

  runApp(const CarePass());
}

class CarePass extends StatelessWidget {
  const CarePass({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدمنا MaterialApp.router عشان نربطه بـ GoRouter
    return MaterialApp.router(
      title: 'CarePass',
      debugShowCheckedModeBanner: false,
      // theme: AppTheme.lightTheme, // فعلها لو ظبطت ملف الثيم
      routerConfig: AppRouter.router, // استدعاء الراوتر بتاعنا
    );
  }
}