import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/commerce_repository.dart';
import 'demo_gateway_screen.dart';

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
  bool _closed = false;
  String _status = 'pending';
  final _deadline = DateTime.now().add(const Duration(minutes: 15));

  bool get _isMomo => widget.session.provider == 'momo';
  bool get _isDemo => widget.session.provider.startsWith('demo');
  bool get _demoMomo => widget.session.provider == 'demo-momo';
  String get _title => _isDemo
      ? (_demoMomo ? 'Thanh toán MoMo (demo)' : 'Thanh toán VNPay (demo)')
      : _isMomo
      ? 'Thanh toán MoMo'
      : 'Thanh toán VNPay';
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
    if (s == AppLifecycleState.resumed) _poll(); // quay lại từ app ngân hàng/MoMo
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.pop(context, true);
  }

  Future<void> _poll() async {
    if (_checking || !mounted || _status == 'paid') return;
    _checking = true;
    try {
      final s = await CommerceRepository.fetchOrderStatus(widget.session.orderId);
      if (!mounted) return;
      if (s == 'paid') {
        _timer?.cancel();
        await context.read<AppStateProvider>().refreshSubscription();
        if (!mounted) return;
        setState(() => _status = 'paid'); // hiện màn hình "Thanh toán thành công"
        await Future.delayed(const Duration(milliseconds: 2500));
        _close();
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

  /// Mở màn hình giả lập app MoMo/VNPay (như sau khi quét QR)
  Future<void> _openDemoGateway() async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DemoGatewayScreen(session: widget.session),
      ),
    );
    if (!mounted) return;
    if (done == true) await _poll(); // thấy đơn đã paid thì hiện "Thanh toán thành công"
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
    final String data;
    final double size;
    final String caption;
    if (_isDemo) {
      // QR mô phỏng: bấm nút bên dưới để giả lập quét và hoàn tất thanh toán
      data = s.qrData ?? s.payUrl.toString();
      size = 260;
      caption = _demoMomo
          ? 'Quét mã bằng ứng dụng MoMo rồi bấm Hoàn tất thanh toán. Bản demo: bấm nút Mô phỏng quét QR bên dưới.'
          : 'Quét mã bằng ứng dụng VNPay rồi bấm Hoàn tất thanh toán. Bản demo: bấm nút Mô phỏng quét QR bên dưới.';
    } else if (_isMomo) {
      data = s.qrData ?? s.payUrl.toString();
      size = 240;
      caption = 'Quét mã bằng ứng dụng MoMo để thanh toán.';
    } else {
      data = s.payUrl.toString();
      size = 300;
      caption =
      'Quét mã bằng camera hoặc app ngân hàng để mở trang thanh toán VNPay trên điện thoại. Hoặc bấm nút bên dưới.';
    }
    return Column(
      children: [
        Center(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: QrImageView(
              data: data,
              size: size,
              // Link VNPay rất dài: mức sửa lỗi thấp để QR thưa, dễ quét hơn
              errorCorrectionLevel:
              (_isDemo || _isMomo) ? QrErrorCorrectLevel.M : QrErrorCorrectLevel.L,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(caption, textAlign: TextAlign.center),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _successView() {
    return Scaffold(
      appBar: AppBar(title: Text(_title), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 96, color: Colors.green.shade600),
              const SizedBox(height: 16),
              Text(
                'Thanh toán thành công!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text('Gói Plus đã được kích hoạt.'),
              const SizedBox(height: 24),
              FilledButton(onPressed: _close, child: const Text('Xong')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'paid') return _successView();
    final s = widget.session;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (!_ended) _qrBlock(),
          if (!_ended && _isDemo)
            FilledButton.icon(
              onPressed: _openDemoGateway,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Mô phỏng quét QR (demo)'),
            ),
          if (!_ended && !_isDemo)
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