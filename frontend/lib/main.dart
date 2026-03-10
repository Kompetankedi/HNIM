import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'services/api_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_device_screen.dart';
import 'screens/qr_scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ProxyProvider<SettingsProvider, ApiService>(
          update: (_, settings, __) => ApiService(settingsProvider: settings),
        ),
      ],
      child: const HNIMApp(),
    ),
  );
}

class HNIMApp extends StatelessWidget {
  const HNIMApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HNIM',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF), // Electric Blue/Cyan
          secondary: Color(0xFFB388FF), // Accent Purple
          background: Color(0xFF0F172A), // Deep Midnight
          surface: Color(0xFF1E293B), // Sleek surface
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AppNavigation(),
        '/settings': (context) => SettingsScreen(),
        '/add_device': (context) => AddDeviceScreen(),
        '/qr_scanner': (context) => QRScannerScreen(),
      },
    );
  }
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({Key? key}) : super(key: key);

  @override
  _AppNavigationState createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    DashboardScreen(),
    InventoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    
    if (settings.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
        ],
      ),
    );
  }
}
