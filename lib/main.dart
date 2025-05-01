import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zonemanager/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 로깅 설정
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  final log = Logger('main');
  
  try {
    log.info('Firebase 초기화 시작...');
    final options = FirebaseOptions(
      apiKey: "AIzaSyBTpUB-Xx-kHVRzsezlMa9f_SoftDRGhfo",
      appId: "1:1022783132438:ios:ff788daed528e63060b637",
      messagingSenderId: "1022783132438",
      projectId: "zonemanager-2ccd4",
      databaseURL: "https://zonemanager-2ccd4-default-rtdb.asia-southeast1.firebasedatabase.app",
      storageBucket: "zonemanager-2ccd4.firebasestorage.app",
      iosBundleId: "com.example.zonemanager",
    );
    await Firebase.initializeApp(options: options);
    log.info('Firebase 초기화 성공');
  } catch (e, stackTrace) {
    log.severe('Firebase 초기화 실패', e, stackTrace);
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Firebase 초기화 중 오류가 발생했습니다.'),
        ),
      ),
    ));
    return;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '주차 관리자',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.notoSansKrTextTheme(),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
