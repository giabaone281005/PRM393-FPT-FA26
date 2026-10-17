import '../shared/widgets/role_ui.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/commerce_models.dart';
import '../parent_portal/popups/parent_gate_dialog.dart';
import '../parent_portal/parent_area.dart';
import '../parent_portal/screens/support_screen.dart';
import '../../core/supabase/supabase_service.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/commerce_repository.dart';

class LearningPackagesScreen extends StatefulWidget {
  const LearningPackagesScreen({super.key});
  @override
  State<LearningPackagesScreen> createState() => _LearningPackagesScreenState();
}

class _LearningPackagesScreenState extends State<LearningPackagesScreen>
    with WidgetsBindingObserver {
  List<PlanPrice> _prices = [];
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
      final prices = await CommerceRepository.fetchPrices();
      final orders = await CommerceRepository.fetchOrders(page: _page);
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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(price.label),
          content: Text(
            '${formatVnd(price.amountVnd)} cho ${price.durationMonths} tháng.\n'
            'Tối đa 3 bé. Thanh toán một kỳ, không tự gia hạn.\nBạn sẽ chuyển sang VNPay để thanh toán.',
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
    setState(() => _buying = true);
    try {
      final uri = await CommerceRepository.checkout(
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
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Không mở được VNPay');
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
                      subscription.isPlusActive
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
            ..._prices.map(
              (p) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${formatVnd(p.amountVnd)} / ${p.durationMonths} tháng',
                      ),
                      const Text('Không tự gia hạn · Áp dụng cho gia đình'),
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
                              : subscription.isPlusActive
                              ? 'Mua thêm thời gian'
                              : 'Chọn gói',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Lịch sử mua', style: Theme.of(context).textTheme.titleLarge),
            const Text(
              'Sau khi trở lại từ VNPay, chọn kiểm tra trạng thái. Không thanh toán lại nếu tài khoản đã bị trừ tiền.',
            ),
            if (!_loading && _error == null && _orders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chưa có đơn hàng trên trang này.'),
              ),
            ..._orders.map(
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
