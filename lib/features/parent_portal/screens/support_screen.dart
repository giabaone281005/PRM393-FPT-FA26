import '../../shared/widgets/role_ui.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/study_repository.dart';
import '../parent_area.dart';

class SupportScreen extends StatefulWidget {
  final bool admin;
  final String? orderId;
  const SupportScreen({super.key, this.admin = false, this.orderId});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<Map<String, dynamic>> _items = [];
  int _page = 0;
  bool _busy = true;
  String? _error, _pendingMessage, _requestId;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      var query = SupabaseService.client!.from('support_requests').select();
      if (!widget.admin) {
        query = query.eq('parent_id', SupabaseService.currentUser!.id);
      }
      if (widget.orderId != null) query = query.eq('order_id', widget.orderId!);
      final rows = await query
          .order('status')
          .order('created_at', ascending: false)
          .range(_page * 20, _page * 20 + 19);
      if (mounted) {
        setState(() {
          _items = rows;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Chưa tải được yêu cầu hỗ trợ.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _write([Map<String, dynamic>? ticket]) async {
    final c = TextEditingController(
      text: ticket == null ? _pendingMessage : null,
    );
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ticket == null ? 'Gửi yêu cầu hỗ trợ' : 'Phản hồi hỗ trợ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ticket != null) Text(ticket['message']),
              TextField(
                controller: c,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Nội dung (ít nhất 5 ký tự)',
                ),
              ),
              if (ticket == null)
                const Text(
                  'Với lỗi thanh toán, mô tả thời điểm và tình trạng bị trừ tiền. Không gửi mật khẩu, PIN hoặc thông tin thẻ.',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    c.dispose();
    if (!mounted) return;
    if (message == null || message.length < 5) return;
    if (ticket == null && message != _pendingMessage) _requestId = null;
    _requestId ??= StudyRepository.requestId();
    _pendingMessage = message;
    setState(() => _busy = true);
    try {
      if (ticket == null) {
        await StudyRepository.rpc('request_support', {
          'p_order': widget.orderId,
          'p_message': message,
          'p_key': _requestId,
          'p_token': context.read<AppStateProvider>().parentToken,
        });
      } else {
        await StudyRepository.rpc('resolve_support', {
          'p_id': ticket['id'],
          'p_reply': message,
        });
      }
      _pendingMessage = null;
      _requestId = null;
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PostgrestException
              ? e.message
              : 'Chưa gửi được. Nội dung được giữ lại để thử lần nữa.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.admin && !context.watch<AppStateProvider>().isParentUnlocked) {
      return const ParentAreaLocked();
    }
    return RoleScaffold(
      appBar: RoleAppBar(
        title: Text(widget.admin ? 'Xử lý yêu cầu hỗ trợ' : 'Hỗ trợ gia đình'),
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
          if (widget.orderId != null) SelectableText('Đơn: ${widget.orderId}'),
          if (!widget.admin)
            FilledButton(
              onPressed: _busy ? null : () => _write(),
              child: const Text('Gửi yêu cầu mới'),
            ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(_error!),
          if (!_busy && _items.isEmpty) const Text('Chưa có yêu cầu.'),
          for (final t in _items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['status'] == 'open' ? 'Đang chờ hỗ trợ' : 'Đã phản hồi',
                    ),
                    SelectableText('${t['message']}\n${t['created_at']}'),
                    if (widget.admin)
                      SelectableText(
                        'Gia đình: ${t['parent_id']}\nĐơn: ${t['order_id'] ?? "—"}',
                      ),
                    if (t['reply'] != null) Text('Phản hồi: ${t['reply']}'),
                    if (widget.admin && t['status'] == 'open')
                      TextButton(
                        onPressed: _busy ? null : () => _write(t),
                        child: const Text('Phản hồi và hoàn tất'),
                      ),
                  ],
                ),
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
}
