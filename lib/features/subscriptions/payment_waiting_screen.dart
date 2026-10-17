import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/commerce_repository.dart';

/// Pop(true) khi đã thanh toán thành công.
class PaymentWaitingScreen extends StatefulWidget {
  final PaymentSession session;
  const PaymentWaitingScreen({super.key, required this.session});
  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _checking = false;
  String _status = 'pending';
  final _deadline = DateTime.now().add(const Duration(minutes: 15));

  bool get _isMomo => widget.session.provider == 'momo';
  bool get _ended => _status != 'pending' || DateTime.now().isAfter(_deadline);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _poll(); // quay lại từ app MoMo/ngân hàng
  }

  Future<void> _poll() async {
    if (_checking || !mounted) return;
    _checking = true;
    try {
      final s = await CommerceRepository.fetchOrderStatus(widget.session.orderId);
      if (!mounted) return;
      if (s == 'paid') {
        _timer?.cancel();
        await context.read<AppStateProvider>().refreshSubscription();
        if (mounted) Navigator.pop(context, true);
        return;
      }
      if (s != 'pending' || DateTime.now().isAfter(_deadline)) _timer?.cancel();
      setState(() => _status = s);
    } catch (_) {
      // lỗi mạng tạm thời: bỏ qua, lần sau thử lại
    } finally {
      _checking = false;
    }
  }

  Future<void> _open(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng thanh toán.')),
      );
    }
  }

  Future<void> _openMomoApp() async {
    final dl = widget.session.deeplink;
    if (dl != null) {
      try {
        if (await launchUrl(Uri.parse(dl), mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {}
    }
    await _open(widget.session.payUrl); // chưa cài MoMo: mở trang web MoMo
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.session.payUrl.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép liên kết thanh toán.')),
    );
  }

  Widget _qrBlock() {
    final s = widget.session;
    // MoMo: dùng mã QR do MoMo trả về, không có thì mã hóa link thanh toán.
    // VNPay: mã hóa link thanh toán (quét bằng camera/app ngân hàng để mở trang VNPay).
    final data = _isMomo ? (s.qrData ?? s.payUrl.toString()) : s.payUrl.toString();
    final size = _isMomo ? 240.0 : 300.0;
    return Column(
      children: [
        Center(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: QrImageView(
              data: data,
              size: size,
              // Link VNPay rất dài: dùng mức sửa lỗi thấp để QR thưa, dễ quét hơn
              errorCorrectionLevel: QrErrorCorrectLevel.L,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isMomo
              ? 'Quét mã bằng ứng dụng MoMo để thanh toán.'
              : 'Quét mã bằng camera hoặc app ngân hàng để mở trang thanh toán VNPay trên điện thoại. Hoặc bấm nút bên dưới.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(
      appBar: AppBar(title: Text(_isMomo ? 'Thanh toán MoMo' : 'Thanh toán VNPay')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (!_ended) _qrBlock(),
          if (!_ended)
            FilledButton.icon(
              onPressed: _isMomo ? _openMomoApp : () => _open(s.payUrl),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                _isMomo ? 'Mở ứng dụng MoMo' : 'Mở trang thanh toán VNPay',
              ),
            ),
          if (!_ended)
            TextButton.icon(
              onPressed: _copyLink,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Sao chép liên kết thanh toán'),
            ),
          const SizedBox(height: 24),
          Center(
            child: _ended
                ? Text(
                    _status == 'failed'
                        ? 'Thanh toán không thành công.'
                        : 'Đơn đã hết thời gian chờ. Nếu đã bị trừ tiền, hãy kiểm tra lịch sử đơn, đừng thanh toán lại.',
                    textAlign: TextAlign.center,
                  )
                : Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text('Đang chờ xác nhận thanh toán…'),
                      TextButton(
                        onPressed: _poll,
                        child: const Text('Kiểm tra lại'),
                      ),
                    ],
                  ),
          ),
          if (_ended) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng'),
            ),
          ],
        ],
      ),
    );
  }
}
