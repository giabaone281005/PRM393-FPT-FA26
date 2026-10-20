import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/commerce_models.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/demo_payment_repository.dart';
import '../parent_portal/parent_area.dart';
import '../shared/widgets/role_ui.dart';

class DemoPaymentScreen extends StatefulWidget {
  const DemoPaymentScreen({super.key, required this.order, this.repository});
  final LearningOrder order;
  final DemoPaymentRepository? repository;
  @override
  State<DemoPaymentScreen> createState() => _DemoPaymentScreenState();
}

class _DemoPaymentScreenState extends State<DemoPaymentScreen> {
  late LearningOrder _order = widget.order;
  bool _busy = false;
  String? _message;

  Future<void> _confirm() async {
    final state = context.read<AppStateProvider>();
    final token = state.parentToken;
    if (_busy || token == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final paid = await (widget.repository ?? DemoPaymentRepository()).confirm(
        transactionId: _order.id,
        parentToken: token,
      );
      if (!mounted) return;
      setState(() => _order = paid);
      await state.refreshSubscription().timeout(const Duration(seconds: 15));
      if (mounted && state.syncError != null) {
        setState(
          () => _message = 'Đã lưu thanh toán mô phỏng. Tải lại dữ liệu để cập nhật quyền học.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = _order.status == 'paid'
              ? 'Đã lưu thanh toán mô phỏng. Tải lại dữ liệu để cập nhật quyền học.'
              : 'Chưa xác nhận được. Kiểm tra kết nối, PIN hoặc lịch sử demo rồi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AppStateProvider>().isParentUnlocked) {
      return const ParentAreaLocked();
    }
    final paid = _order.status == 'paid';
    return RoleScaffold(
      appBar: RoleAppBar(title: const Text('Thanh toán mô phỏng')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'DEMO — không thu tiền thật',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(_order.label, style: Theme.of(context).textTheme.titleLarge),
          Text('${formatVnd(_order.amountVnd)} (giá trị mô phỏng)'),
          const Text(
            'Giao dịch được lưu vào lịch sử demo riêng và cấp quyền Plus phục vụ trình diễn.',
          ),
          SelectableText('Mã đơn demo: ${_order.id}'),
          if (_order.transactionId != null)
            SelectableText('Mã giao dịch: ${_order.transactionId}'),
          const SizedBox(height: 20),
          if (paid) ...[
            const Icon(Icons.check_circle, size: 56),
            const Text('Đã thanh toán mô phỏng thành công'),
            const Text('Lịch sử đã được lưu trên hệ thống.'),
          ] else
            FilledButton.icon(
              onPressed: _busy || !_order.canResume ? null : _confirm,
              icon: const Icon(Icons.science_outlined),
              label: Text(
                _busy ? 'Đang xác nhận…' : 'Giả lập thanh toán thành công',
              ),
            ),
          if (_message != null) Text(_message!),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : () => Navigator.pop(context, paid),
            child: const Text('Về gói học và lịch sử'),
          ),
        ],
      ),
    );
  }
}
