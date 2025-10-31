import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _reservoirSizeController = TextEditingController();

  String _reservoirUnit = 'L';
  String _temperatureUnit = 'C';
  String _nutrientUnit = 'ms/cm';
  bool _emailNotifications = false;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _deviceId;

  static const List<DropdownMenuItem<String>> _reservoirUnitItems = [
    DropdownMenuItem(
      value: 'L',
      child: Text('Litros (L)'),
    ),
    DropdownMenuItem(
      value: 'gal',
      child: Text('Galones (gal)'),
    ),
  ];

  static const List<DropdownMenuItem<String>> _temperatureUnitItems = [
    DropdownMenuItem(
      value: 'C',
      child: Text('Celsius (C)'),
    ),
    DropdownMenuItem(
      value: 'F',
      child: Text('Fahrenheit (F)'),
    ),
  ];

  static const List<DropdownMenuItem<String>> _nutrientUnitItems = [
    DropdownMenuItem(
      value: 'ms/cm',
      child: Text('mS/cm'),
    ),
    DropdownMenuItem(
      value: 'ppm500',
      child: Text('PPM 500'),
    ),
    DropdownMenuItem(
      value: 'ppm700',
      child: Text('PPM 700'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _reservoirSizeController.dispose();
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
          .from('cultivemos_settings')
          .select(
            'device_id, user_name, reservoir_size, reservoir_size_units, temperature_units, nutrients_units, email_notifications',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      String? deviceId = data?['device_id']?.toString();
      deviceId ??= await _fetchFirstDeviceId(client, user.id);

      final String? userName = data?['user_name'] as String?;
      final dynamic reservoirValue = data?['reservoir_size'];
      final String reservoirSizeText = _formatReservoirSize(reservoirValue);
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
      _reservoirSizeController.text = reservoirSizeText;

      if (!mounted) {
        return;
      }

      setState(() {
        _deviceId = deviceId;
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

  Future<String?> _fetchFirstDeviceId(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      final Map<String, dynamic>? data = await client
          .from('devices')
          .select('device_id')
          .eq('user_id', userId)
          .order('last_seen', ascending: false, nullsFirst: false)
          .limit(1)
          .maybeSingle();
      return data?['device_id']?.toString();
    } catch (_) {
      return null;
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

    final String? deviceId = _deviceId;
    if (deviceId == null || deviceId.isEmpty) {
      _showSnackBar(
        'Necesitas vincular un dispositivo antes de guardar la configuracion.',
      );
      return;
    }

    final String userName = _userNameController.text.trim();
    final String reservoirText = _reservoirSizeController.text.trim();
    final double? reservoirSize = _parseReservoirSize(reservoirText);

    if (reservoirSize == null) {
      _showSnackBar('Ingresa un volumen numerico para el reservorio.');
      return;
    }

    final Map<String, dynamic> row = {
      'user_id': user.id,
      'device_id': deviceId,
      'user_name': userName,
      'reservoir_size': reservoirSize,
      'reservoir_size_units': _reservoirUnit,
      'temperature_units': _temperatureUnit,
      'nutrients_units': _nutrientUnit,
      'email_notifications': _emailNotifications,
    };

    final Map<String, dynamic> payload = {
      'user_id': user.id,
      'user_name': userName,
      'reservoir_size': reservoirSize,
      'reservoir_size_units': _reservoirUnit,
      'temperature_units': _temperatureUnit,
      'nutrients_units': _nutrientUnit,
      'email_notifications': _emailNotifications,
    };

    setState(() {
      _isSaving = true;
    });

    try {
      await client
          .from('cultivemos_settings')
          .upsert(row, onConflict: 'user_id,device_id');

      final String topic = 'devices/$deviceId/settings';

      try {
        await _publishSettings(topic, payload);
        _showSnackBar(
          'Cambios guardados y enviados al dispositivo.',
          color: Colors.green,
        );
      } catch (error) {
        _showSnackBar(
          'Guardamos los cambios pero no pudimos avisar al dispositivo: $error',
          color: Colors.orange,
        );
      }
    } on PostgrestException catch (error) {
      _showSnackBar(
        'No pudimos guardar los cambios: ${error.message}',
      );
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

  Future<void> _publishSettings(
    String topic,
    Map<String, dynamic> payload,
  ) async {
    final SupabaseClient client = Supabase.instance.client;

    final RealtimeChannel channel = client.channel(
      topic,
      opts: const RealtimeChannelConfig(ack: true),
    );

    final Completer<void> completer = Completer<void>();

    void handleStatus(RealtimeSubscribeStatus status, Object? error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        channel
            .sendBroadcastMessage(
          event: 'settings-updated',
          payload: payload,
        )
            .then((_) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        }).catchError((dynamic err, __) {
          if (!completer.isCompleted) {
            completer.completeError(err);
          }
        });
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        if (!completer.isCompleted) {
          completer.completeError(error ?? status.name);
        }
      }
    }

    channel.subscribe(handleStatus);

    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } finally {
      await channel.unsubscribe();
      client.removeChannel(channel);
    }
  }

  void _showSnackBar(String message, {Color color = Colors.redAccent}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    });
  }

  static String _formatReservoirSize(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is num) {
      return value % 1 == 0 ? value.toInt().toString() : value.toString();
    }
    return value.toString();
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
        return 'ms/cm';
    }
  }

  static double? _parseReservoirSize(String input) {
    if (input.isEmpty) {
      return null;
    }
    final normalized = input.replaceAll(',', '.');
    return double.tryParse(normalized);
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
                  if (_deviceId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Dispositivo vinculado: $_deviceId',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No se encontro un dispositivo vinculado.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Text(
                    'Settings Page',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  TextField(
                    controller: _reservoirSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Reservoir size',
                      hintText: 'Escribe el volumen del reservorio',
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
                      subtitle:
                          const Text('Activa o desactiva las notificaciones'),
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
                    'Pulsa "Guardar cambios" para sincronizar estos valores con tu dispositivo.',
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
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
