import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bluetooth, size: 64, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'No hay dispositivos OLEO registrados en la app.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Utiliza el asistente para escanear y provisionar cuando necesites configurar uno nuevo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const _AddDeviceButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDeviceButton extends StatelessWidget {
  const _AddDeviceButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () => Navigator.pushNamed(context, AppRoutes.addDevice),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Añadir dispositivo', style: TextStyle(color: Colors.white)),
    );
  }
}
