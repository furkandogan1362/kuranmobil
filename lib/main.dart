import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/theme_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Sistem UI ayarları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  // GlobalKey ile MaterialApp'i yeniden build etmek için
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final savedThemeMode = await ThemeService.getThemeMode();
    if (mounted) {
      setState(() {
        _themeMode = ThemeService.stringToThemeMode(savedThemeMode);
      });
    }
  }

  void _updateThemeMode(String themeMode) {
    print('🔄 main.dart: Tema güncelleniyor: $themeMode');
    if (mounted) {
      setState(() {
        _themeMode = ThemeService.stringToThemeMode(themeMode);
      });
      print('✅ main.dart: setState çağrıldı, yeni tema: $_themeMode');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Kur\'an-ı Kerim',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeService.getLightTheme(),
      darkTheme: ThemeService.getDarkTheme(),
      home: HomeScreen(onThemeChanged: _updateThemeMode),
    );
  }
}
