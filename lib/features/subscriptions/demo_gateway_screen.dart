import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/commerce_models.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/commerce_repository.dart';

/// Màn hình giả lập app MoMo / VNPay sau khi quét QR (chỉ để demo, không trừ tiền).
/// Pop(true) khi đã thanh toán xong.
class DemoGatewayScreen extends StatefulWidget {
  final PaymentSession session;
  const DemoGatewayScreen({super.key, required this.session});
  @override
  State<DemoGatewayScreen> createState() => _DemoGatewayScreenState();
}

enum _Step { confirm, processing, done, error }

class _DemoGatewayScreenState extends State<DemoGatewayScreen> {
  _Step _step = _Step.confirm;
  String? _txn; // mã giao dịch do server sinh (kiểu MoMo / VNPay)
  DateTime? _paidAt;

  bool get _isMomo => widget.session.provider == 'demo-momo';
  Color get _color =>
      _isMomo ? const Color(0xFFAE2070) : const Color(0xFF005BAA);
  String get _name => _isMomo ? 'MoMo' : 'VNPAY';
  String get _amount => widget.session.amountVnd == null
      ? ''
      : formatVnd(widget.session.amountVnd!);
  // Mã đơn hàng kiểu cổng thanh toán (MoMo: MOMO + timestamp). Không có thì dùng mã rút gọn.
  String get _gatewayOrderId =>
      widget.session.gatewayOrderId ??
          (widget.session.orderId.length >= 8
              ? widget.session.orderId.substring(0, 8).toUpperCase()
              : widget.session.orderId);

  Future<void> _pay() async {
    setState(() => _step = _Step.processing);
    try {
      await Future.delayed(const Duration(milliseconds: 1500)); // giả lập đang xử lý
      if (!mounted) return;
      final txn = await CommerceRepository.simulateScan(
        orderId: widget.session.orderId,
        parentToken: context.read<AppStateProvider>().parentToken!,
        style: _isMomo ? 'momo' : 'vnpay',
      );
      if (!mounted) return;
      setState(() {
        _txn = txn ?? '';
        _paidAt = DateTime.now();
        _step = _Step.done;
      });
    } catch (_) {
      if (mounted) setState(() => _step = _Step.error);
    }
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const SizedBox(width: 16),
        Flexible(
          child: SelectableText(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 20 : 15,
            ),
          ),
        ),
      ],
    ),
  );

  ButtonStyle get _btnStyle => FilledButton.styleFrom(
    backgroundColor: _color,
    minimumSize: const Size.fromHeight(48),
  );

  Widget _body() {
    switch (_step) {
      case _Step.confirm:
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thanh toán cho',
                        style: TextStyle(color: Colors.black54)),
                    const Text(
                      'MathLingo',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    _row('Nhà cung cấp', 'MathLingo'),
                    _row('Mã đơn hàng', _gatewayOrderId),
                    _row('Nội dung', 'Thanh toán gói Plus MathLingo'),
                    _row('Nguồn tiền', _isMomo ? 'Ví MoMo' : 'NCB •••• 1198'),
                    const Divider(height: 24),
                    _row('Số tiền', _amount, bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: _btnStyle,
              onPressed: _pay,
              child: const Text('Hoàn tất thanh toán'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đây là màn hình mô phỏng để demo, không trừ tiền thật.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        );
      case _Step.processing:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang xử lý giao dịch…'),
            ],
          ),
        );
      case _Step.done:
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.check_circle, size: 96, color: Colors.green.shade600),
            const SizedBox(height: 16),
            Text(
              'Thanh toán thành công',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _amount,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Mã giao dịch', _txn ?? ''),
                    _row('Mã đơn hàng', _gatewayOrderId),
                    _row('Nhà cung cấp', 'MathLingo'),
                    _row(
                      'Thời gian',
                      DateFormat('dd/MM/yyyy HH:mm:ss')
                          .format(_paidAt ?? DateTime.now()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: _btnStyle,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Về MathLingo'),
            ),
          ],
        );
      case _Step.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 72, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Chưa hoàn tất được thanh toán. Hãy thử lại.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: _btnStyle,
                  onPressed: _pay,
                  child: const Text('Thử lại'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step != _Step.processing,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _color,
          foregroundColor: Colors.white,
          title: Text(_name),
        ),
        body: _body(),
      ),
    );
  }
}