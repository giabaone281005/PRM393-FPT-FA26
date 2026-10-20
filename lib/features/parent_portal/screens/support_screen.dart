import '../../shared/widgets/role_ui.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/study_repository.dart';
import '../../../data/repositories/support_repository.dart';
import '../../../data/repositories/account_live_sync.dart';
import '../parent_area.dart';

class SupportScreen extends StatefulWidget {
  final bool admin;
  final String? orderId;
  final SupportRepository? repository;
  const SupportScreen({
    super.key,
    this.admin = false,
    this.orderId,
    this.repository,
  });
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<Map<String, dynamic>> _items = [];
  int _page = 0;
  late final _repository = widget.repository ?? SupportRepository();
  bool _busy = false, _editing = false;
  String? _account;
  int _generation = 0;
  final _replyDrafts = <String, String>{};
  StreamSubscription<Set<String>>? _live;
  String? _error, _pendingMessage, _requestId;

  bool _allowed(AppStateProvider state) =>
      widget.admin ? state.isAdmin : state.isParentUnlocked;

  @override
  void initState() {
    super.initState();
    _live = AccountLiveSync.watch({'support_requests'}, () {
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
    final account = _allowed(state) ? state.accountId : null;
    if (account == _account) return;
    _account = account;
    _generation++;
    _items = [];
    _page = 0;
    _busy = false;
    _editing = false;
    _error = _pendingMessage = _requestId = null;
    _replyDrafts.clear();
    if (account != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _account == account) _load();
      });
    }
  }

  bool _canApply(int generation) =>
      mounted &&
      generation == _generation &&
      _allowed(context.read<AppStateProvider>()) &&
      context.read<AppStateProvider>().accountId == _account;

  Future<void> _load() async {
    if (_busy || _editing || _account == null || !_canApply(_generation)) {
      return;
    }
    final generation = _generation;
    setState(() => _busy = true);
    try {
      final rows = await _repository.fetch(
        admin: widget.admin,
        orderId: widget.orderId,
        page: _page,
      );
      if (_canApply(generation)) {
        setState(() {
          _items = rows;
          _error = null;
        });
      }
    } catch (_) {
      if (_canApply(generation)) {
        setState(() => _error = 'Chưa tải được yêu cầu hỗ trợ.');
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _write([Map<String, dynamic>? ticket]) async {
    if (_busy || _editing || _account == null || !_canApply(_generation)) {
      return;
    }
    final generation = _generation;
    setState(() => _editing = true);
    final message = await showDialog<String>(
      context: context,
      builder: (_) {
        return _SupportMessageDialog(
          ticket: ticket,
          draft: ticket == null ? _pendingMessage : _replyDrafts[ticket['id']],
          account: _account!,
          admin: widget.admin,
        );
      },
    );
    if (!mounted || !_canApply(generation)) return;
    setState(() => _editing = false);
    if (message == null) {
      setState(() => _busy = false);
      return;
    }
    if (ticket == null && message != _pendingMessage) _requestId = null;
    _requestId ??= StudyRepository.requestId();
    if (ticket == null) {
      _pendingMessage = message;
    } else {
      _replyDrafts[ticket['id'] as String] = message;
    }
    setState(() => _busy = true);
    try {
      if (ticket == null) {
        await _repository.request(
          orderId: widget.orderId,
          message: message,
          requestId: _requestId!,
          parentToken: context.read<AppStateProvider>().parentToken ?? '',
        );
      } else {
        await _repository.resolve(ticket['id'] as String, message);
      }
      if (!_canApply(generation)) return;
      _pendingMessage = null;
      _requestId = null;
      if (ticket != null) _replyDrafts.remove(ticket['id']);
      setState(() => _busy = false);
      await _load();
    } catch (e) {
      if (_canApply(generation)) {
        setState(
          () => _error = e is PostgrestException
              ? e.message
              : 'Chưa gửi được. Nội dung được giữ lại để thử lần nữa.',
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    if (widget.admin && !state.isAdmin) {
      return const RoleScaffold(
        appBar: RoleAppBar(title: Text('Hỗ trợ')),
        body: Center(child: Text('Cần quyền admin để xử lý hỗ trợ.')),
      );
    }
    if (!widget.admin && !state.isParentUnlocked) {
      return const ParentAreaLocked();
    }
    return RoleScaffold(
      appBar: RoleAppBar(
        title: Text(widget.admin ? 'Xử lý yêu cầu hỗ trợ' : 'Hỗ trợ gia đình'),
        actions: [
          IconButton(
            onPressed: _busy || _editing ? null : _load,
            tooltip: 'Tải lại yêu cầu',
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
              onPressed: _busy || _editing ? null : () => _write(),
              child: const Text('Gửi yêu cầu mới'),
            ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(_error!),
          if (!_busy && _error == null && _items.isEmpty)
            const Text('Chưa có yêu cầu.'),
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
                        onPressed: _busy || _editing ? null : () => _write(t),
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
                onPressed: _page == 0 || _busy || _editing
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
                onPressed: _items.length < 20 || _busy || _editing
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
}

class _SupportMessageDialog extends StatefulWidget {
  const _SupportMessageDialog({
    this.ticket,
    this.draft,
    required this.account,
    required this.admin,
  });
  final Map<String, dynamic>? ticket;
  final String? draft;
  final String account;
  final bool admin;
  @override
  State<_SupportMessageDialog> createState() => _SupportMessageDialogState();
}

class _SupportMessageDialogState extends State<_SupportMessageDialog> {
  final _form = GlobalKey<FormState>();
  bool _closing = false;
  late final _controller = TextEditingController(text: widget.draft);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    if (state.accountId != widget.account ||
        !(widget.admin ? state.isAdmin : state.isParentUnlocked)) {
      if (!_closing) {
        _closing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
      return const SizedBox.shrink();
    }
    return AlertDialog(
      title: Text(
        widget.ticket == null ? 'Gửi yêu cầu hỗ trợ' : 'Phản hồi hỗ trợ',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.ticket != null)
                Text(widget.ticket!['message'] as String),
              TextFormField(
                controller: _controller,
                maxLines: 5,
                maxLength: 2000,
                validator: SupportRepository.validateMessage,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Nội dung (ít nhất 5 ký tự)',
                ),
              ),
              if (widget.ticket == null)
                const Text(
                  'Với lỗi thanh toán, mô tả thời điểm và tình trạng bị trừ tiền. Không gửi mật khẩu, PIN hoặc thông tin thẻ.',
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Gửi'),
        ),
      ],
    );
  }
}
