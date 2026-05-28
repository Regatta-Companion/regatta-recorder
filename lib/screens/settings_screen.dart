// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    return settingsAsync.when(
      data: (settings) => _SettingsBody(settings: settings),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Fout: $e'))),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final AppSettings settings;
  const _SettingsBody({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final loggedIn = settings.authToken?.isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Instellingen')),
      body: ListView(
        children: [
          // ── Account ──
          _Section('Account', [
            if (loggedIn) ...[
              ListTile(
                leading: const Icon(Icons.account_circle_outlined, color: AppColors.teal),
                title: const Text('Ingelogd als'),
                subtitle: Text(settings.authEmail ?? ''),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.red),
                title: const Text('Uitloggen'),
                onTap: () => notifier.logout(),
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.login, color: AppColors.teal),
                title: const Text('Inloggen / Registreren'),
                subtitle: const Text('Verplicht voor uploaden naar server'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
          ]),

          // ── Wedstrijdcode ──
          _Section('Wedstrijd', [
            ListTile(
              leading: const Icon(Icons.tag, color: AppColors.teal),
              title: const Text('Deelnamecode'),
              subtitle: Text(
                settings.raceCode?.isNotEmpty == true
                    ? '${settings.raceCode} — ${settings.raceLabel ?? ""}'
                    : 'Niet ingesteld',
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
              onTap: () => _showCodeDialog(context, ref, settings),
            ),
          ]),

          // ── Boot profiel ──
          _Section('Boot profiel', [
            _EditableTile(
              icon: Icons.directions_boat,
              label: 'Boottype',
              value: settings.boatType ?? '',
              hint: 'Bijv. Solo, Laser, Randmeer...',
              onSave: (v) => notifier.updateBoatProfile(boatType: v),
            ),
            _EditableTile(
              icon: Icons.edit_note,
              label: 'Bootnaam',
              value: settings.boatName ?? '',
              hint: 'Bijv. De Zilvermeeuw',
              onSave: (v) => notifier.updateBoatProfile(boatName: v),
            ),
            _EditableTile(
              icon: Icons.group,
              label: 'Teamnaam',
              value: settings.teamName ?? '',
              hint: 'Bijv. Team Westeinder',
              onSave: (v) => notifier.updateBoatProfile(teamName: v),
            ),
          ]),

          // ── Timer ──
          _Section('Timer', [
            _DropdownTile<TimerPreset>(
              icon: Icons.timer,
              label: 'Afteltimer',
              value: settings.timerPreset,
              items: TimerPreset.values,
              itemLabel: (p) => p.label,
              onChanged: (p) => notifier.setTimerPreset(p),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Zet op "Uit" om alleen als recorder te gebruiken (geen aftellen).',
                style: TextStyle(fontSize: 13, color: AppColors.grey),
              ),
            ),
          ]),

          // ── Versie ──
          const _VersionTile(),
        ],
      ),
    );
  }

  void _showCodeDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final controller = TextEditingController(text: settings.raceCode ?? '');
    final notifier = ref.read(settingsProvider.notifier);
    final api = ref.read(apiServiceProvider);
    final token = settings.authToken;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deelnamecode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Bijv. ABC123',
                labelText: 'Code',
              ),
            ),
            if (token == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Je moet ingelogd zijn om een code te valideren.',
                  style: TextStyle(color: AppColors.amber, fontSize: 13),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              notifier.setRaceCode('', '');
              Navigator.pop(ctx);
            },
            child: const Text('Verwijderen'),
          ),
          TextButton(
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.isEmpty || token == null) {
                notifier.setRaceCode(code, '');
                Navigator.pop(ctx);
                return;
              }
              try {
                final info = await api.lookupCode(token, code);
                final label = info['race_name'] as String? ??
                    info['class_name'] as String? ??
                    code;
                notifier.setRaceCode(code, label);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Code ongeldig: $e'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
                return;
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }
}

class _EditableTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final void Function(String) onSave;

  const _EditableTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.teal),
      title: Text(label),
      subtitle: Text(value.isNotEmpty ? value : hint,
          style: TextStyle(color: value.isNotEmpty ? null : AppColors.grey)),
      trailing: const Icon(Icons.edit, size: 18, color: AppColors.grey),
      onTap: () => _showEditDialog(context),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) {
            onSave(v.trim());
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T) onChanged;

  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.teal),
      title: Text(label),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(itemLabel(i))))
            .toList(),
        onChanged: (v) => onChanged(v as T),
      ),
    );
  }
}

class _VersionTile extends StatefulWidget {
  const _VersionTile();

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          _version.isNotEmpty ? _version : '',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey.withOpacity(0.5),
              ),
        ),
      ),
    );
  }
}
