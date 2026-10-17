import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/study_repository.dart';
import '../../learning_engine/study_screen.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});
  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  Map<String, dynamic>? _board;
  bool _loading = true, _previous = false;
  String? _error;
  String? _kid;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<AppStateProvider>();
    if (state.hasKids && state.currentKid.id != _kid) {
      _kid = state.currentKid.id;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final kid = _kid;
      final data = Map<String, dynamic>.from(
        await StudyRepository.rpc('get_arena_board', {
          'p_kid': kid,
          'p_previous': _previous,
        }) as Map,
      );
      if (mounted && kid == _kid) setState(() => _board = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'Chưa tải được bảng xếp hạng.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = _board?['members'] as List? ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đấu trường'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Tuần ${_board?['week'] ?? ""} · Nhóm ${_board?['group_number'] ?? "–"}',
            ),
            const Text(
              'Thi đấu cùng tối đa 30 bạn cùng khối lớp. Điểm do máy chủ chấm từ 5 câu toán; hoàn thành một phiên chỉ nhận thưởng một lần.',
            ),
            SwitchListTile(
              title: const Text('Xem kết quả tuần trước'),
              value: _previous,
              onChanged: (v) {
                setState(() => _previous = v);
                _load();
              },
            ),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudyScreen(kind: 'arena'),
                        ),
                      );
                      if (mounted) _load();
                    },
              child: const Text('Thi đấu 5 câu toán'),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text(_error!),
            if (!_loading && members.isEmpty)
              const Text('Chưa có kết quả trong tuần này.'),
            ...members.map(
              (m) => Card(
                color: m['is_me'] == true
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  leading: Text('#${m['rank']}'),
                  title: Text(
                    '${m['nickname']}${m['is_me'] == true ? ' (bé)' : ''}',
                  ),
                  trailing: Text('${m['weekly_xp']} XP'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
