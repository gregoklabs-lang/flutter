import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';

class ModifyPage extends StatelessWidget {
  const ModifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _modifyOptions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1,
            child: Column(
              children: List.generate(options.length, (index) {
                final option = options[index];
                return Column(
                  children: [
                    ListTile(
                      onTap: () => Navigator.pushNamed(context, option.route),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (option.statusLabel != null)
                            Text(
                              option.statusLabel!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    option.statusColor ??
                                    theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      subtitle: option.subtitle == null
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                option.subtitle!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    if (index < options.length - 1)
                      const Divider(height: 0, indent: 16, endIndent: 16),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<_ModifyOption> _modifyOptions() {
    return const [
      _ModifyOption(
        title: 'pH balance',
        statusLabel: '(Active)',
        statusColor: Color(0xFF2E7D32),
        subtitle: 'Target pH Range 5.6 - 6.0',
        route: AppRoutes.phBalance,
      ),
      _ModifyOption(
        title: 'Manual dosing',
        subtitle: 'Configura los ciclos de dosificación manual',
        route: AppRoutes.manualDosing,
      ),
      _ModifyOption(
        title: 'Smart dosing',
        statusLabel: '(Active)',
        statusColor: Color(0xFF2E7D32),
        subtitle: 'Target EC Range 1.4 - 1.8 mS/cm',
        route: AppRoutes.smartDosing,
      ),
      _ModifyOption(
        title: 'Flush',
        subtitle: 'Gestiona los ciclos de limpieza del sistema',
        route: AppRoutes.flush,
      ),
    ];
  }
}

class _ModifyOption {
  const _ModifyOption({
    required this.title,
    required this.route,
    this.subtitle,
    this.statusLabel,
    this.statusColor,
  });

  final String title;
  final String route;
  final String? subtitle;
  final String? statusLabel;
  final Color? statusColor;
}
