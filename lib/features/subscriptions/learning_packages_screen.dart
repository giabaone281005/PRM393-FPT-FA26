import '../shared/widgets/role_ui.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../data/models/commerce_models.dart';
import '../parent_portal/popups/parent_gate_dialog.dart';
import '../parent_portal/parent_area.dart';
import '../parent_portal/screens/support_screen.dart';
import '../../core/supabase/supabase_service.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import 'payment_waiting_screen.dart';

enum PayMethod { momoDemo, vnpayDemo, momo, vnpayQr, vnpay }

class LearningPackagesScreen extends StatefulWidget {
  const LearningPackagesScreen({super.key});
  @override
  State<LearningPackagesScreen> createState() => _LearningPackagesScreenState();
}

class _LearningPackagesScreenState extends State<LearningPackagesScreen>
    with WidgetsBindingObserver {
  List<PlanPrice> _prices = [];
  PlanInfo? _trial;
  LinkedWallet? _wallet;
  bool _trialUsed = false;
  List<LearningOrder> _orders = [];
  final Map<String, String> _requestIds = {};
  bool _loading = true, _buying = false;
  String? _error;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading && !_buying) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      try {
        await CommerceRepository.purgeUnpaid(); // xóa đơn chưa thanh toán đã quá cũ
      } catch (_) {}
      final prices = await CommerceRepository.fetchPrices();
      final orders = await CommerceRepository.fetchOrders(page: _page);
      final plans = await WalletRepository.fetchPlans();
      final wallet = await WalletRepository.fetchLinked();
      final used = await WalletRepository.hasUsedTrial();
      _requestIds.removeWhere(
            (_, requestId) => orders.any(
              (order) =>
          order.requestId == requestId &&
              (order.status != 'pending' || !order.canResume),
        ),
      );
      if (!mounted) return;
      await context.read<AppStateProvider>().refreshSubscription();
      if (!mounted) return;
      setState(() {
        _prices = prices;
        _orders = orders;
        _trial = plans.where((p) => p.code == 'basic_trial').firstOrNull;
        _wallet = wallet;
        _trialUsed = used;
      });
    } catch (_) {
      if (mounted) {
        setState(
              () => _error =
          'Chưa tải được gói hoặc lịch sử. Kiểm tra kết nối và thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Lịch sử chỉ hiện đơn đã thanh toán hoặc đã hoàn tiền (đơn chờ thanh toán không lưu)
  List<LearningOrder> get _visibleOrders =>
      _orders.where((o) => o.status == 'paid' || o.status == 'refunded').toList();

  // ---- Giá, giảm giá, cộng dồn ----
  List<PlanPrice> get _sortedPrices =>
      [..._prices]..sort((a, b) => a.durationMonths.compareTo(b.durationMonths));

  PlanPrice? get _monthlyPrice {
    for (final p in _sortedPrices) {
      if (p.durationMonths == 1) return p;
    }
    return null;
  }

  /// Giá mua lẻ từng tháng cho cùng số tháng (để tính % giảm)
  int _fullPrice(PlanPrice p) => (_monthlyPrice?.amountVnd ?? 0) * p.durationMonths;

  int _discountPercent(PlanPrice p) {
    final full = _fullPrice(p);
    if (p.durationMonths <= 1 || full <= 0 || p.amountVnd >= full) return 0;
    return ((1 - p.amountVnd / full) * 100).round();
  }

  /// Cộng tháng theo lịch, giữ ngày trong tháng (31/01 + 1 tháng = 28/02), giống Postgres
  DateTime _addMonths(DateTime d, int months) {
    final total = d.month - 1 + months;
    final year = d.year + total ~/ 12;
    final month = total % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(
      year,
      month,
      d.day > lastDay ? lastDay : d.day,
      d.hour,
      d.minute,
    );
  }

  Future<PayMethod?> _pickMethod() => showModalBottomSheet<PayMethod>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('MoMo – quét QR (mô phỏng)'),
            subtitle: const Text('Demo: không trừ tiền'),
            onTap: () => Navigator.pop(ctx, PayMethod.momoDemo),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: const Text('VNPay – quét QR (mô phỏng)'),
            subtitle: const Text('Demo: không trừ tiền'),
            onTap: () => Navigator.pop(ctx, PayMethod.vnpayDemo),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Sandbox – Ví MoMo (QR / mở app)'),
            onTap: () => Navigator.pop(ctx, PayMethod.momo),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: const Text('Sandbox – VNPay QR'),
            onTap: () => Navigator.pop(ctx, PayMethod.vnpayQr),
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Sandbox – VNPay (thẻ ATM)'),
            onTap: () => Navigator.pop(ctx, PayMethod.vnpay),
          ),
        ],
      ),
    ),
  );

  Future<void> _pay({PlanPrice? price, LearningOrder? order}) async {
    if (_buying) return;
    if (!context.read<AppStateProvider>().isParentUnlocked) {
      await showDialog(
        context: context,
        builder: (_) => ParentGateDialog(onUnlocked: () {}),
      );
      if (!mounted || !context.read<AppStateProvider>().isParentUnlocked) {
        return;
      }
    }
    if (price != null) {
      final sub = context.read<AppStateProvider>().subscription;
      final now = DateTime.now();
      final current = sub.isPlusActive ? sub.expiresAt?.toLocal() : null;
      final base = (current != null && current.isAfter(now)) ? current : now;
      final next = _addMonths(base, price.durationMonths);
      final pct = _discountPercent(price);
      final fmt = DateFormat('dd/MM/yyyy HH:mm');
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(price.label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${formatVnd(price.amountVnd)} cho ${price.durationMonths} tháng'),
              if (pct > 0) Text('Giảm $pct% so với mua từng tháng'),
              const SizedBox(height: 8),
              if (current != null) Text('Hạn hiện tại: ${fmt.format(current)}'),
              Text('Hạn sau khi mua (khoảng): ${fmt.format(next)}'),
              const SizedBox(height: 8),
              const Text(
                'Tối đa 3 bé. Thanh toán một kỳ, không tự gia hạn. Mua nhiều lần sẽ được cộng dồn thời gian. Bạn sẽ chọn cách thanh toán ở bước tiếp theo.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final method = await _pickMethod();
    if (method == null || !mounted) return;
    setState(() => _buying = true);
    try {
      final session = await CommerceRepository.startPayment(
        provider: switch (method) {
          PayMethod.momoDemo => 'demo-momo',
          PayMethod.vnpayDemo => 'demo-vnpay',
          PayMethod.momo => 'momo',
          _ => 'vnpay',
        },
        qr: method == PayMethod.vnpayQr,
        parentToken: context.read<AppStateProvider>().parentToken!,
        priceId: price?.id,
        orderId: order?.id,
        requestId: price == null
            ? null
            : _requestIds.putIfAbsent(
          price.id,
          CommerceRepository.newRequestId,
        ),
      );
      if (!mounted) return;
      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWaitingScreen(session: session),
        ),
      );
      if (paid != true) {
        // Thoát giữa chừng mà chưa trả tiền: xóa luôn đơn, không lưu vào lịch sử
        // (server chỉ xóa nếu đơn vẫn chưa thanh toán)
        try {
          await CommerceRepository.discardOrder(session.orderId);
        } catch (_) {}
      }
      if (paid == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanh toán thành công! Gói Plus đã được kích hoạt.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa mở được thanh toán. Kiểm tra lịch sử đơn trước khi thử lại. Nếu đã trừ tiền, không thanh toán lần hai.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _buying = false);
        await _load();
      }
    }
  }

  Future<(String, String)?> _askWallet() {
    var provider = 'momo';
    final phone = TextEditingController();
    return showDialog<(String, String)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Gắn ví để dùng thử'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'momo', label: Text('MoMo')),
                  ButtonSegment(value: 'vnpay', label: Text('VNPay')),
                ],
                selected: {provider},
                onSelectionChanged: (s) => setD(() => provider = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại của ví',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Không tự động trừ tiền. Mỗi ví chỉ được dùng thử một lần.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, (provider, phone.text.trim())),
              child: const Text('Gắn ví'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTrial() async {
    if (_buying) return;
    if (!context.read<AppStateProvider>().isParentUnlocked) {
      await showDialog(
        context: context,
        builder: (_) => ParentGateDialog(onUnlocked: () {}),
      );
      if (!mounted || !context.read<AppStateProvider>().isParentUnlocked) {
        return;
      }
    }
    final token = context.read<AppStateProvider>().parentToken!;
    setState(() => _buying = true);
    try {
      if (_wallet == null) {
        final input = await _askWallet();
        if (input == null) return;
        await WalletRepository.link(
          provider: input.$1,
          phone: input.$2,
          parentToken: token,
        );
      }
      await WalletRepository.startTrial(token);
      if (!mounted) return;
      await context.read<AppStateProvider>().refreshSubscription();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bắt đầu dùng thử 7 ngày!')),
      );
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa thể bắt đầu dùng thử. Thử lại sau.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _buying = false);
        await _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    if (SupabaseService.isLoggedIn && !state.isParentUnlocked) {
      return const ParentAreaLocked();
    }
    final subscription = state.subscription;
    return RoleScaffold(
      appBar: RoleAppBar(
        title: const Text('Gói học tập'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Kiểm tra trạng thái',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.isTrialActive
                          ? 'Đang dùng thử Basic · còn ${subscription.trialDaysLeft} ngày'
                          : subscription.isPlusActive
                          ? 'Gia đình đang dùng Plus'
                          : 'Gia đình đang dùng Basic',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text('Tối đa ${subscription.effectiveMaxKids} bé'),
                    if (subscription.isPlusActive)
                      Text(
                        subscription.expiresAt == null
                            ? 'Không thời hạn'
                            : 'Hạn dùng: ${DateFormat('dd/MM/yyyy HH:mm').format(subscription.expiresAt!.toLocal())}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Basic: 1 bé. Plus: tối đa 3 bé và lộ trình toán lớp 1–5. Vườn luyện tập hồi tim luôn miễn phí.',
            ),
            const SizedBox(height: 4),
            const Text(
              'Mua càng lâu càng rẻ. Bạn có thể mua nhiều lần: thời gian được cộng dồn vào hạn hiện tại (kể cả khi đang dùng thử).',
            ),
            const SizedBox(height: 8),
            const Text(
              'Quét AI hiện là trải nghiệm mẫu, chưa nằm trong quyền lợi bán gói.',
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (!_loading && _error == null && _prices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Chưa có gói mở bán. Bạn vẫn có thể học với Basic.',
                ),
              ),
            if (_trial != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _trial!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_trial!.description),
                      const SizedBox(height: 8),
                      ..._trial!.features.map((f) => Text('• $f')),
                      const SizedBox(height: 8),
                      if (_wallet != null) Text('Ví đã gắn: ${_wallet!.label}'),
                      FilledButton(
                        onPressed: _buying ||
                            _loading ||
                            _trialUsed ||
                            subscription.isPlusActive
                            ? null
                            : _startTrial,
                        child: Text(
                          _trialUsed
                              ? (subscription.isTrialActive
                              ? 'Đang dùng thử'
                              : 'Đã dùng thử')
                              : _wallet == null
                              ? 'Gắn ví & dùng thử 7 ngày'
                              : 'Bắt đầu dùng thử 7 ngày',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ..._sortedPrices.map((p) {
              final pct = _discountPercent(p);
              final saved = _fullPrice(p) - p.amountVnd;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (pct > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Giảm $pct%',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${formatVnd(p.amountVnd)} / ${p.durationMonths} tháng',
                      ),
                      if (p.durationMonths > 1)
                        Text(
                          '≈ ${formatVnd((p.amountVnd / p.durationMonths).round())} / tháng',
                        ),
                      if (pct > 0 && saved > 0)
                        Text(
                          'Tiết kiệm ${formatVnd(saved)} so với mua từng tháng',
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                      const Text('Không tự gia hạn · Mua nhiều lần được cộng dồn'),
                      FilledButton(
                        onPressed:
                        _buying ||
                            _loading ||
                            (subscription.isPlusActive &&
                                subscription.expiresAt == null)
                            ? null
                            : () => _pay(price: p),
                        child: Text(
                          _buying
                              ? 'Đang xử lý…'
                              : subscription.isPlusActive &&
                              !subscription.isTrialActive
                              ? 'Mua thêm thời gian'
                              : 'Chọn gói',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            Text('Lịch sử mua', style: Theme.of(context).textTheme.titleLarge),
            const Text(
              'Chỉ hiển thị các đơn đã thanh toán. Đơn chưa thanh toán xong sẽ tự bị hủy.',
            ),
            if (!_loading && _error == null && _visibleOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chưa có đơn hàng trên trang này.'),
              ),
            ..._visibleOrders.map(
                  (o) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(formatVnd(o.amountVnd)),
                      Text(o.displayStatus),
                      SelectableText(
                        'Mã đơn: ${o.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(o.createdAt.toLocal()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupportScreen(orderId: o.id),
                          ),
                        ),
                        child: const Text('Yêu cầu hỗ trợ đơn này'),
                      ),
                      if (o.canResume)
                        TextButton(
                          onPressed: _buying ? null : () => _pay(order: o),
                          child: const Text('Tiếp tục đơn này'),
                        ),
                      if (o.status != 'paid')
                        TextButton(
                          onPressed: _buying || _loading
                              ? null
                              : () async {
                            setState(() => _buying = true);
                            try {
                              await CommerceRepository.reconcile(o.id);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Chưa kiểm tra được VNPay. Không thanh toán lại nếu đã trừ tiền.',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _buying = false);
                                await _load();
                              }
                            }
                          },
                          child: const Text('Kiểm tra với VNPay'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _loading || _page == 0
                      ? null
                      : () {
                    _page--;
                    _load();
                  },
                  child: const Text('Trang trước'),
                ),
                Text('Trang ${_page + 1}'),
                TextButton(
                  onPressed: _loading || _orders.length < 20
                      ? null
                      : () {
                    _page++;
                    _load();
                  },
                  child: const Text('Trang sau'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}