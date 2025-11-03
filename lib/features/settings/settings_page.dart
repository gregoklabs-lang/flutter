import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _userNameController = TextEditingController();

  String _reservoirUnit = 'L';
  String _temperatureUnit = 'C';
  String _nutrientUnit = 'mS/cm';
  bool _emailNotifications = false;

  bool _isLoading = true;
  bool _isSaving = false;

  static const List<DropdownMenuItem<String>> _reservoirUnitItems = [
    DropdownMenuItem(value: 'L', child: Text('Litros (L)')),
    DropdownMenuItem(value: 'gal', child: Text('Galones (gal)')),
  ];

  static const List<DropdownMenuItem<String>> _temperatureUnitItems = [
    DropdownMenuItem(value: 'C', child: Text('Celsius (C)')),
    DropdownMenuItem(value: 'F', child: Text('Fahrenheit (F)')),
  ];

  static const List<DropdownMenuItem<String>> _nutrientUnitItems = [
    DropdownMenuItem(value: 'mS/cm', child: Text('mS/cm')),
    DropdownMenuItem(value: 'ppm500', child: Text('PPM 500')),
    DropdownMenuItem(value: 'ppm700', child: Text('PPM 700')),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final SupabaseClient client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('No encontramos la sesion activa.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic>? data = await client
          .from('user_settings')
          .select(
            'user_name, reservoir_size_units, temperature_units, nutrients_units, email_notifications',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      final String? userName = data?['user_name'] as String?;
      final String reservoirUnit = _normalizeReservoirUnit(
        data?['reservoir_size_units'] as String?,
      );
      final String temperatureUnit = _normalizeTemperatureUnit(
        data?['temperature_units'] as String?,
      );
      final String nutrientUnit = _normalizeNutrientUnit(
        data?['nutrients_units'] as String?,
      );
      final bool emailNotifications =
          (data?['email_notifications'] as bool?) ?? false;

      _userNameController.text = userName ?? '';

      if (!mounted) {
        return;
      }

      setState(() {
        _reservoirUnit = reservoirUnit;
        _temperatureUnit = temperatureUnit;
        _nutrientUnit = nutrientUnit;
        _emailNotifications = emailNotifications;
        _isLoading = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('No pudimos cargar tus ajustes: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error inesperado al cargar ajustes: $error');
    }
  }

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();

    final SupabaseClient client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      _showSnackBar('No encontramos la sesion activa.');
      return;
    }

    final String userName = _userNameController.text.trim();
    final Map<String, dynamic> row = {
      'user_id': user.id,
      'user_name': userName,
      'reservoir_size_units': _reservoirUnit,
      'temperature_units': _temperatureUnit,
      'nutrients_units': _nutrientUnit,
      'email_notifications': _emailNotifications,
    };

    setState(() {
      _isSaving = true;
    });

    try {
      await client.from('user_settings').upsert(row, onConflict: 'user_id');

      _showSnackBar('Cambios guardados correctamente.', color: Colors.green);
    } on PostgrestException catch (error) {
      _showSnackBar('No pudimos guardar los cambios: ${error.message}');
    } catch (error) {
      _showSnackBar('Error inesperado: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {Color color = Colors.redAccent}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    });
  }

  static String _normalizeReservoirUnit(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'l':
      case 'litro':
      case 'litros':
        return 'L';
      case 'gal':
      case 'galon':
      case 'galones':
      case 'gallon':
      case 'gallons':
        return 'gal';
      default:
        return 'L';
    }
  }

  static String _normalizeTemperatureUnit(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'F':
      case 'FAHRENHEIT':
        return 'F';
      case 'C':
      case 'CELSIUS':
      default:
        return 'C';
    }
  }

  static String _normalizeNutrientUnit(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'ppm700':
        return 'ppm700';
      case 'ppm500':
        return 'ppm500';
      case 'ms/cm':
      default:
        return 'mS/cm';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuración general',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Estos ajustes se aplican a toda tu cuenta.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _userNameController,
                    decoration: const InputDecoration(
                      labelText: 'User name',
                      hintText: 'Ingresa un nombre para tu app',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: ValueKey('reservoir-$_reservoirUnit'),
                    initialValue: _reservoirUnit,
                    decoration: const InputDecoration(
                      labelText: 'Reservoir size units',
                      border: OutlineInputBorder(),
                    ),
                    items: _reservoirUnitItems,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _reservoirUnit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: ValueKey('temp-$_temperatureUnit'),
                    initialValue: _temperatureUnit,
                    decoration: const InputDecoration(
                      labelText: 'Temperature units',
                      border: OutlineInputBorder(),
                    ),
                    items: _temperatureUnitItems,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _temperatureUnit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: ValueKey('nutrients-$_nutrientUnit'),
                    initialValue: _nutrientUnit,
                    decoration: const InputDecoration(
                      labelText: 'Nutrients units',
                      border: OutlineInputBorder(),
                    ),
                    items: _nutrientUnitItems,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _nutrientUnit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SwitchListTile(
                      title: const Text('Email notifications'),
                      subtitle: const Text(
                        'Activa o desactiva las notificaciones',
                      ),
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pulsa "Guardar cambios" para actualizar tus preferencias.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
