import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/routes/app_routes.dart';
import '../modify/modify_page.dart';
import '../devices/devices_page.dart';
import '../history/history_page.dart';
import '../settings/settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [];
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _userEmail = Supabase.instance.client.auth.currentUser?.email;
    _pages.addAll([
      _buildDashboardPage(),
      const ModifyPage(),
      const SettingsPage(),
      const HistoryPage(),
      const DevicesPage(),
    ]);
  }

  Future<void> _onLogout() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  Widget _buildDashboardPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Dashboard Principal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenido${_userEmail != null ? ' ${_userEmail!}' : ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _onLogout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  final List<String> _titles = [
    'Dashboard',
    'Modify',
    'Settings',
    'History',
    'Devices',
  ];

  final List<String> _icons = [
    'assets/icons/dashboard.png',
    'assets/icons/edit.png',
    'assets/icons/configuraciones.png',
    'assets/icons/history.png',
    'assets/icons/devices.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: List.generate(_titles.length, (index) {
          return BottomNavigationBarItem(
            icon: Image.asset(
              _icons[index],
              width: 24,
              height: 24,
              color: _currentIndex == index ? Colors.blueAccent : Colors.grey,
            ),
            label: _titles[index],
          );
        }),
      ),
    );
  }
}
