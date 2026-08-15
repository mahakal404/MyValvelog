import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/entry_provider.dart';
import 'providers/settings_provider.dart';

import 'screens/splash_screen.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const HeartValveApp());
}

class HeartValveApp extends StatelessWidget {
  const HeartValveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => EntryProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          final primaryColor = settings.primaryColor;
          const backgroundColor = Color(0xFFF5F7FA);

          return MaterialApp(
            title: 'MYValve Log',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: primaryColor,
              scaffoldBackgroundColor: backgroundColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.light,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.dark,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
