import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/commerce_repository.dart';
import 'demo_gateway_screen.dart';
import '../shared/widgets/role_ui.dart';

/// Pop(true) khi đã thanh toán thành công.
class PaymentWaitingScreen extends StatefulWidget {
  final PaymentSession session;
  final Future<String> Function(String)? statusLoader;
  final Future<void> Function()? refreshEntitlements;
  final Duration waitTimeout;
  const PaymentWaitingScreen({
    super.key,
    required this.session,
    this.statusLoader,
    this.refreshEntitlements,
    this.waitTimeout = const Duration(minutes: 15),
  });
  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _checking = false;
  bool _closed = false;
  bool _timedOut = false;
  String? _error;
  String _status = 'pending';
  late final _deadline = DateTime.now().add(widget.waitTimeout);

  bool get _isMomo => widget.session.provider == 'momo';
  bool get _isDemo => widget.session.provider.startsWith('demo');
  bool get _demoMomo => widget.session.provider == 'demo-momo';
  String get _title => _isDemo
      ? (_demoMomo ? 'Thanh toán MoMo (demo)' : 'Thanh toán VNPay (demo)')
      : _isMomo
      ? 'Thanh toán MoMo'
      : 'Thanh toán VNPay';
  bool get _ended => _status != 'pending' || _timedOut;

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
    if (s == AppLifecycleState.resumed) {
      _poll(); // quay lại từ app ngân hàng/MoMo
    }
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.pop(context, true);
  }

  Future<void> _poll() async {
    if (_checking || !mounted || _status == 'paid') return;
    setState(() => _checking = true);
    try {
      final s =
          await (widget.statusLoader ?? CommerceRepository.fetchOrderStatus)(
            widget.session.orderId,
          ).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (s == 'paid') {
        _timer?.cancel();
        setState(() {
          _status = 'paid';
          _error = null;
        }); // hiện màn hình "Thanh toán thành công"
        try {
          await (widget.refreshEntitlements ??
                  context.read<AppStateProvider>().refreshSubscription)()
              .timeout(const Duration(seconds: 15));
        } catch (_) {
          // Payment remains confirmed even when entitlement refresh is offline.
        }
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 2500));
        _close();
        return;
      }
      if (!['pending', 'failed', 'expired', 'refunded'].contains(s)) {
        throw const FormatException('Unknown order status');
      }
      final timedOut = DateTime.now().isAfter(_deadline);
      if (s != 'pending' || timedOut) _timer?.cancel();
      setState(() {
        _status = s;
        _timedOut = timedOut;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      final timedOut = DateTime.now().isAfter(_deadline);
      if (timedOut) _timer?.cancel();
      setState(() {
        _timedOut = timedOut;
        _error = 'Chưa kiểm tra được thanh toán. Nếu đã bị trừ tiền, đừng thanh toán lại.';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Missing platform handlers and rejected launches share the retry notice.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng thanh toán.')),
      );
    }
  }

  Future<void> _openMomoApp() async {
    final dl = widget.session.deeplink;
    if (dl != null) {
      try {
        if (await launchUrl(
          Uri.parse(dl),
          mode: LaunchMode.externalApplication,
        )) {
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
    if (done == true) {
      await _poll(); // thấy đơn đã paid thì hiện "Thanh toán thành công"
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(
      ClipboardData(text: widget.session.payUrl.toString()),
    );
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
      caption = 'Quét mã bằng camera hoặc app ngân hàng để mở trang thanh toán VNPay trên điện thoại. Hoặc bấm nút bên dưới.';
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
              errorCorrectionLevel: (_isDemo || _isMomo)
                  ? QrErrorCorrectLevel.M
                  : QrErrorCorrectLevel.L,
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
    return RoleScaffold(
      appBar: RoleAppBar(title: Text(_title)),
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
              const Text(
                'Đã ghi nhận thanh toán. Quyền học được cập nhật theo kỳ gói trên máy chủ.',
              ),
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
    return RoleScaffold(
      appBar: RoleAppBar(title: Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Text(_error!, textAlign: TextAlign.center),
            ),
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
                ? Text(switch (_status) {
                    'failed' => 'Thanh toán không thành công.',
                    'refunded' => 'Giao dịch đã được hoàn tiền. Kiểm tra lịch sử đơn để xem kỳ gói.',
                    'expired' => 'Đơn đã hết hạn. Nếu đã bị trừ tiền, hãy kiểm tra lịch sử đơn, đừng thanh toán lại.',
                    _ => 'Đã hết thời gian chờ xác nhận. Nếu đã bị trừ tiền, hãy kiểm tra lịch sử đơn, đừng thanh toán lại.',
                  }, textAlign: TextAlign.center)
                : Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text('Đang chờ xác nhận thanh toán…'),
                    ],
                  ),
          ),
          TextButton(
            onPressed: _checking ? null : _poll,
            child: const Text('Kiểm tra lại'),
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
