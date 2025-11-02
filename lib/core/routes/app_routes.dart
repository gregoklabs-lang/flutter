import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/devices/add_device_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/modify/ph_balance_page.dart';
import '../../features/modify/manual_dosing_page.dart';
import '../../features/modify/smart_dosing_page.dart';
import '../../features/modify/flush_page.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const addDevice = '/add-device';
  static const login = '/login';
  static const register = '/register';
  static const phBalance = '/modify/ph-balance';
  static const manualDosing = '/modify/manual-dosing';
  static const smartDosing = '/modify/smart-dosing';
  static const flush = '/modify/flush';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    addDevice: (context) => const AddDevicePage(),
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    phBalance: (context) => const PhBalancePage(),
    manualDosing: (context) => const ManualDosingPage(),
    smartDosing: (context) => const SmartDosingPage(),
    flush: (context) => const FlushPage(),
  };
}
