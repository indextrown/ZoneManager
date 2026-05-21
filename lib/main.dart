import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zonemanager/screens/home_screen.dart';
import 'package:zonemanager/repositories/firebase_room_repository.dart';
import 'package:zonemanager/repositories/local_user_repository.dart';
import 'package:zonemanager/repositories/room_repository.dart';
import 'package:zonemanager/repositories/user_repository.dart';
import 'package:zonemanager/services/firebase_service.dart';
import 'package:zonemanager/services/user_service.dart';
import 'package:zonemanager/viewmodels/theme_view_model.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 화면 방향을 세로 모드로 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 로깅 설정
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  final log = Logger('main');
  
  try {
    log.info('Firebase 초기화 시작...');
    final options = DefaultFirebaseOptions.maybeCurrentPlatform;
    if (options != null) {
      await Firebase.initializeApp(options: options);
      log.info('Dart define 기반 Firebase 설정 사용');
    } else {
      await Firebase.initializeApp();
      log.info('플랫폼 기본 Firebase 설정 파일 사용');
    }
    log.info('Firebase 초기화 성공');
  } catch (e, stackTrace) {
    final errorMessage = 'Firebase 초기화 실패: $e';
    log.severe(errorMessage, e, stackTrace);
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$errorMessage\n\n'
              'iOS는 GoogleService-Info.plist, '
              'Android는 --dart-define-from-file=config/firebase.json '
              '또는 google-services.json 설정을 확인해 주세요.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
    return;
  }
  
  final themeViewModel = ThemeViewModel();
  await themeViewModel.loadTheme();
  final roomRepository = FirebaseRoomRepository(
    firebaseService: FirebaseService(),
  );
  final userRepository = LocalUserRepository(
    userService: await UserService.getInstance(),
  );
  
  runApp(
    MultiProvider(
      providers: [
        Provider<RoomRepository>.value(value: roomRepository),
        Provider<UserRepository>.value(value: userRepository),
        ChangeNotifierProvider<ThemeViewModel>.value(value: themeViewModel),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.notoSansKrTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeViewModel, child) {
        return MaterialApp(
          title: 'Zone Manager',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeViewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}
