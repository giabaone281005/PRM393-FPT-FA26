import '../../shared/widgets/role_ui.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/app_state_provider.dart';
import '../parent_area.dart';

import '../../../core/supabase/supabase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _busy = true;
  String? _error;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final rows = await SupabaseService.client!
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .range(_page * 20, _page * 20 + 19);
      if (mounted) {
        setState(() {
          _items = rows;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được thông báo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      !context.watch<AppStateProvider>().isParentUnlocked
      ? const ParentAreaLocked()
      : RoleScaffold(
          appBar: RoleAppBar(
            title: const Text('Thông báo gia đình'),
            actions: [
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) Text(_error!),
              if (!_busy && _items.isEmpty) const Text('Chưa có thông báo.'),
              for (final n in _items)
                Card(
                  child: ListTile(
                    leading: Icon(
                      n['read_at'] == null
                          ? Icons.mark_email_unread
                          : Icons.drafts,
                    ),
                    title: Text(n['title']),
                    subtitle: Text('${n['body']}\n${n['created_at']}'),
                    onTap: () async {
                      try {
                        await SupabaseService.client!
                            .from('notifications')
                            .update({
                              'read_at': DateTime.now()
                                  .toUtc()
                                  .toIso8601String(),
                            })
                            .eq('id', n['id']);
                        await _load();
                      } catch (_) {
                        if (mounted) {
                          setState(() => _error = 'Chưa đánh dấu đã đọc.');
                        }
                      }
                    },
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page == 0 || _busy
                        ? null
                        : () {
                            _page--;
                            _load();
                          },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Trang ${_page + 1}'),
                  IconButton(
                    onPressed: _items.length < 20 || _busy
                        ? null
                        : () {
                            _page++;
                            _load();
                          },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        );
}
