import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/study_repository.dart';

class MascotWardrobeScreen extends StatefulWidget {
  const MascotWardrobeScreen({super.key});
  @override
  State<MascotWardrobeScreen> createState() => _MascotWardrobeScreenState();
}

class _MascotWardrobeScreenState extends State<MascotWardrobeScreen> {
  Map<String, dynamic>? _data;
  bool _busy = false;
  String? _error;
  String _filter = 'all';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final id = context.read<AppStateProvider>().currentKid.id;
      final data = Map<String, dynamic>.from(
        await StudyRepository.rpc('get_wardrobe', {'p_kid': id}) as Map,
      );
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'Chưa tải được tủ đồ.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _select(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item['icon'] ?? "🦉"} ${item['name']}'),
        content: Text(
          item['owned'] == true
              ? 'Món đồ đã sở hữu. Trang bị lại miễn phí.'
              : 'Đổi ${item['price_stars']} sao để sở hữu và trang bị. Chỉ thay đổi diện mạo, không tăng điểm hoặc tim.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(item['owned'] == true ? 'Trang bị' : 'Đổi bằng sao'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final state = context.read<AppStateProvider>();
      final data = Map<String, dynamic>.from(
        await StudyRepository.rpc('buy_equip_item', {
          'p_kid': state.currentKid.id,
          'p_item': item['id'],
          'p_buy': item['owned'] != true,
        }) as Map,
      );
      if (mounted) setState(() => _data = data);
      await state.refreshFromCloud();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa đổi được món đồ. Kiểm tra số sao và kết nối.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (_data?['items'] as List? ?? []).where(
      (i) =>
          _filter == 'all' ||
          (_filter == 'owned' ? i['owned'] == true : i['slot'] == _filter),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tủ đồ Mathy'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(_error!),
          Text(
            '⭐ ${_data?['stars'] ?? 0} sao',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'Trang phục thay đổi diện mạo. Sao được tích lũy từ bài học và đấu trường.',
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final f in ['all', 'owned', 'hat', 'glasses'])
                ChoiceChip(
                  label: Text(
                    {
                      'all': 'Tất cả',
                      'owned': 'Đã sở hữu',
                      'hat': 'Mũ',
                      'glasses': 'Kính',
                    }[f]!,
                  ),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
          ...items.map((raw) {
            final i = Map<String, dynamic>.from(raw as Map);
            return Card(
              child: ListTile(
                leading: Text(
                  i['icon']?.toString() ?? '🦉',
                  style: const TextStyle(fontSize: 30),
                ),
                title: Text(i['name'] as String),
                subtitle: Text(
                  i['equipped'] == true
                      ? 'Đang trang bị'
                      : i['owned'] == true
                      ? 'Đã sở hữu · Miễn phí trang bị'
                      : '${i['price_stars']} sao',
                ),
                trailing: i['equipped'] == true
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: _busy || i['equipped'] == true ? null : () => _select(i),
              ),
            );
          }),
        ],
      ),
    );
  }
}
