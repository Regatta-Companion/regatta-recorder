// lib/screens/tracks_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../services/track_manager.dart';
import '../theme/app_theme.dart';

final trackManagerProvider = Provider<TrackManager>((ref) => TrackManager());

final localTracksProvider = FutureProvider<List<File>>((ref) async {
  return ref.read(trackManagerProvider).listLocalTracks();
});

class TracksScreen extends ConsumerStatefulWidget {
  const TracksScreen({super.key});

  @override
  ConsumerState<TracksScreen> createState() => _TracksScreenState();
}

class _TracksScreenState extends ConsumerState<TracksScreen> {
  final Set<String> _uploading = {};
  // filename → status info
  final Map<String, _TrackStatus> _statuses = {};
  bool _serverChecked = false;

  @override
  void initState() {
    super.initState();
    _loadServerTracks();
  }

  Future<void> _loadServerTracks() async {
    final token = ref.read(settingsProvider).valueOrNull?.authToken;
    if (token == null) return;
    try {
      final tracks = await ref.read(apiServiceProvider).listTracks(token);
      if (!mounted) return;
      setState(() {
        _statuses.clear();
        for (final t in tracks) {
          final filename = (t['original_filename'] as String?)?.isNotEmpty == true
              ? t['original_filename'] as String
              : t['filename'] as String;
          final raceName = t['race_name'] as String?;
          _statuses[filename] = _TrackStatus(
            onServer: true,
            serverId: t['id'] as int?,
            raceName: raceName,
          );
        }
        _serverChecked = true;
      });
    } catch (_) {
      if (mounted) setState(() => _serverChecked = true);
    }
  }

  String _statusLabel(File file) {
    final name = file.uri.pathSegments.last;
    final status = _statuses[name];
    if (status == null) return 'Alleen lokaal';
    if (status.raceName != null) return 'Gekoppeld: ${status.raceName}';
    return 'Op server';
  }

  IconData _statusIcon(File file) {
    final name = file.uri.pathSegments.last;
    final status = _statuses[name];
    if (status == null) return Icons.phone_android;
    if (status.raceName != null) return Icons.emoji_events;
    return Icons.cloud_done;
  }

  Color _statusColor(File file) {
    final name = file.uri.pathSegments.last;
    final status = _statuses[name];
    if (status == null) return AppColors.amber;
    if (status.raceName != null) return AppColors.green;
    return AppColors.teal;
  }

  Future<void> _upload(File file) async {
    final token = ref.read(settingsProvider).valueOrNull?.authToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log eerst in om te uploaden')),
      );
      return;
    }
    final name = file.uri.pathSegments.last;
    setState(() => _uploading.add(name));
    try {
      await ref.read(apiServiceProvider).uploadTrack(file, token);

      // Auto-join met code
      final code = ref.read(settingsProvider).valueOrNull?.raceCode;
      if (code != null && code.isNotEmpty) {
        final updated = await ref.read(apiServiceProvider).listTracks(token);
        final match = updated.cast<Map<String, dynamic>?>().firstWhere(
              (t) =>
                  (t?['original_filename'] as String?) == name ||
                  t?['filename'] == name,
              orElse: () => null,
            );
        if (match != null) {
          await ref
              .read(apiServiceProvider)
              .joinWithCode(token, code, match['id'] as int);
        }
      }

      await _loadServerTracks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track geüpload ✓')),
        );
      }
    } catch (e) {
      final msg = e.toString() == 'already_on_server'
          ? 'Track staat al op de server'
          : 'Upload mislukt: $e';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        if (e.toString() == 'already_on_server') _loadServerTracks();
      }
    } finally {
      if (mounted) setState(() => _uploading.remove(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(localTracksProvider);
    final manager = ref.read(trackManagerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Opgenomen tracks')),
      body: tracksAsync.when(
        data: (tracks) => tracks.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_off, size: 48, color: AppColors.grey),
                    const SizedBox(height: 12),
                    const Text('Nog geen tracks opgenomen',
                        style: TextStyle(color: AppColors.grey)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(localTracksProvider);
                  await _loadServerTracks();
                },
                child: ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (ctx, i) {
                    final file = tracks[i];
                    final name = file.uri.pathSegments.last;
                    final formatted =
                        manager.formatTrackName(name);
                    final isUploading = _uploading.contains(name);

                    return ListTile(
                      leading: Icon(_statusIcon(file),
                          color: _statusColor(file)),
                      title: Text(formatted,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 14)),
                      subtitle: Text(
                        _statusLabel(file),
                        style: TextStyle(
                            color: _statusColor(file), fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUploading)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.teal),
                            )
                          else ...[
                            if (_statuses[name] == null)
                              IconButton(
                                icon: const Icon(Icons.cloud_upload_outlined),
                                tooltip: 'Uploaden naar server',
                                color: AppColors.teal,
                                onPressed: () => _upload(file),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: AppColors.red,
                              onPressed: () async {
                                await manager.deleteTrack(file);
                                ref.invalidate(localTracksProvider);
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(child: Text('Fout: $e')),
      ),
    );
  }
}

class _TrackStatus {
  final bool onServer;
  final int? serverId;
  final String? raceName;
  const _TrackStatus({
    required this.onServer,
    this.serverId,
    this.raceName,
  });
}
