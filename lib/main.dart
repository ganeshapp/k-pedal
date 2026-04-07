import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/passport_provider.dart';
import 'providers/paths_provider.dart';
import 'providers/ride_recorder_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Only Hive init and passport (fast local ops) block startup.
  // Path data loads async after the UI is shown.
  await Hive.initFlutter();
  final passport = PassportProvider();
  await passport.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final p = PathsProvider();
          p.load(); // fire-and-forget; HomeScreen shows spinner until ready
          return p;
        }),
        ChangeNotifierProvider.value(value: passport),
        ChangeNotifierProvider(create: (_) => RideRecorderProvider()),
      ],
      child: const KPedalApp(),
    ),
  );
}

class KPedalApp extends StatelessWidget {
  const KPedalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Pedal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1117),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
