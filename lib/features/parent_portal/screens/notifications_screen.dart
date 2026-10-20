import '../../shared/widgets/role_ui.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/family_notification.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/account_live_sync.dart';
import '../parent_area.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.repository});
  final NotificationRepository? repository;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<FamilyNotification> _items = [];
  late final _repository = widget.repository ?? NotificationRepository();
  bool _busy = false;
  String? _error;
  String? _account;
  int _page = 0, _generation = 0;
  StreamSubscription<Set<String>>? _live;
  @override
  void initState() {
    super.initState();
    _live = AccountLiveSync.watch({'notifications'}, () {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _live?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = Provider.of<AppStateProvider>(context);
    final account = state.isParentUnlocked ? state.accountId : null;
    if (_account == account) return;
    _account = account;
    _generation++;
    _items = [];
    _page = 0;
    _busy = false;
    _error = null;
    if (account != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _account == account) _load();
      });
    }
  }

  Future<void> _load() async {
    final state = context.read<AppStateProvider>();
    if (_busy || !state.isParentUnlocked || _account == null) return;
    final generation = _generation;
    setState(() => _busy = true);
    try {
      final rows = await _repository.fetch(page: _page);
      if (_canApply(generation)) {
        setState(() {
          _items = rows;
          _error = null;
        });
      }
    } catch (_) {
      if (_canApply(generation)) {
        setState(() => _error = 'Không tải được thông báo. Hãy thử tải lại.');
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  bool _canApply(int generation) =>
      mounted &&
      generation == _generation &&
      context.read<AppStateProvider>().isParentUnlocked &&
      context.read<AppStateProvider>().accountId == _account;

  Future<void> _markRead(FamilyNotification notification) async {
    if (_busy || notification.readAt != null || !_canApply(_generation)) return;
    final generation = _generation;
    setState(() => _busy = true);
    try {
      await _repository.markRead(notification.id);
      if (!_canApply(generation)) return;
      setState(() => _busy = false);
      await _load();
    } catch (_) {
      if (_canApply(generation)) {
        setState(() => _error = 'Chưa đánh dấu đã đọc. Hãy thử lại.');
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
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
              IconButton(
                onPressed: _busy ? null : _load,
                tooltip: 'Tải lại thông báo',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) Text(_error!),
              if (!_busy && _error == null && _items.isEmpty)
                const Text('Chưa có thông báo.'),
              for (final n in _items)
                Card(
                  child: ListTile(
                    leading: Icon(
                      n.readAt == null ? Icons.mark_email_unread : Icons.drafts,
                    ),
                    title: Text(n.title),
                    subtitle: Text(
                      '${n.body}\n${DateFormat('dd/MM/yyyy HH:mm').format(n.createdAt.toLocal())}',
                    ),
                    onTap: _busy || n.readAt != null
                        ? null
                        : () => _markRead(n),
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
                    tooltip: 'Trang trước',
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
                    tooltip: 'Trang sau',
                  ),
                ],
              ),
            ],
          ),
        );
}
