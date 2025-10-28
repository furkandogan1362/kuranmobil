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

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final savedThemeMode = await ThemeService.getThemeMode();
    setState(() {
      _themeMode = ThemeService.stringToThemeMode(savedThemeMode);
    });
  }

  void _updateThemeMode(String themeMode) {
    setState(() {
      _themeMode = ThemeService.stringToThemeMode(themeMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kur\'an-ı Kerim',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeService.getLightTheme(),
      darkTheme: ThemeService.getDarkTheme(),
      home: HomeScreen(onThemeChanged: _updateThemeMode),
    );
  }
}
