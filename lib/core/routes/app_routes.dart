import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/devices/add_device_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const addDevice = '/add-device';
  static const login = '/login';
  static const register = '/register';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        home: (context) => const HomeScreen(),
        addDevice: (context) => const AddDevicePage(),
        login: (context) => const LoginPage(),
        register: (context) => const RegisterPage(),
      };
}
