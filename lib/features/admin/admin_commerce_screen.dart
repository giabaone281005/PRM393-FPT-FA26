import '../shared/widgets/role_ui.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/commerce_models.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../data/repositories/demo_payment_repository.dart';
import '../../data/repositories/account_live_sync.dart';
import '../subscriptions/widgets/demo_transaction_card.dart';
import '../../core/supabase/supabase_service.dart';

class AdminCommerceScreen extends StatefulWidget {
  const AdminCommerceScreen({super.key});
  @override
  State<AdminCommerceScreen> createState() => _AdminCommerceScreenState();
}

class _AdminCommerceScreenState extends State<AdminCommerceScreen> {
  List<PlanPrice> _prices = [];
  List<LearningOrder> _orders = [];
  List<LearningOrder> _demoOrders = [];
  StreamSubscription<Set<String>>? _live;
  bool _loading = true;
  String? _error;
  int _page = 0;
  List<Map<String, dynamic>> _refunds = [];
  Future<void> _refund(LearningOrder order) async {
    final reason = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn tiền toàn phần'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hoàn ${formatVnd(order.amountVnd)} và thu hồi kỳ Plus của đơn này. Thao tác gửi sang VNPay.',
            ),
            TextField(
              controller: reason,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Lý do (ít nhất 5 ký tự)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reason.text.trim()),
            child: const Text('Xác nhận hoàn tiền'),
          ),
        ],
      ),
    );
    reason.dispose();
    if (text == null || text.length < 5) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.client!.functions.invoke(
        'vnpay-refund',
        body: {'orderId': order.id, 'reason': text},
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kết quả chưa rõ. Kiểm tra lịch sử hoàn tiền trước khi thao tác tiếp.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) await _load();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    _live = AccountLiveSync.watch(AccountLiveSync.commerceTables, () {
      if (!_loading) _load();
    });
  }

  @override
  void dispose() {
    _live?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prices = await CommerceRepository.fetchPrices(admin: true);
      final refunds = await SupabaseService.client!
          .from('refund_requests')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      final orders = await CommerceRepository.fetchOrders(
        admin: true,
        page: _page,
      );
      final demoOrders = await DemoPaymentRepository().history(page: _page);
      if (mounted) {
        setState(() {
          _refunds = refunds;
          _prices = prices;
          _orders = orders;
          _demoOrders = demoOrders;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không tải được dữ liệu. Kiểm tra quyền admin, migration và kết nối.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(PlanPrice price) async {
    final label = TextEditingController(text: price.label);
    final amount = TextEditingController(text: '${price.amountVnd}');
    var published = price.published, newVersion = false, saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Giá gói học tập'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${price.durationMonths} tháng · Thanh toán một kỳ'),
                TextField(
                  controller: label,
                  decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                ),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá toàn kỳ (VND)',
                  ),
                ),
                SwitchListTile(
                  title: const Text('Mở bán'),
                  value: published,
                  onChanged: saving ? null : (v) => update(() => published = v),
                ),
                CheckboxListTile(
                  title: const Text('Tạo phiên bản giá mới'),
                  subtitle: const Text(
                    'Bắt buộc nếu giá cũ đã có đơn. Tắt mở bán phiên bản cũ riêng khi cần.',
                  ),
                  value: newVersion,
                  onChanged: saving
                      ? null
                      : (v) => update(() => newVersion = v ?? false),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final value = int.tryParse(amount.text.trim());
                      if (value == null ||
                          value < 0 ||
                          value > 9999999999 ||
                          (published && value == 0) ||
                          label.text.trim().isEmpty) {
                        update(
                          () => error = 'Nhập tên và giá hợp lệ; giá mở bán phải lớn hơn 0.',
                        );
                        return;
                      }
                      update(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await CommerceRepository.savePrice(
                          price,
                          label: label.text.trim(),
                          amount: value,
                          published: published,
                          newVersion: newVersion,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (_) {
                        if (ctx.mounted) {
                          update(() {
                            saving = false;
                            error = 'Không lưu được. Nếu giá đã có đơn, chọn tạo phiên bản mới.';
                          });
                        }
                      }
                    },
              child: Text(saving ? 'Đang lưu…' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    amount.dispose();
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => RoleScaffold(
    appBar: RoleAppBar(
      title: const Text('Gói và đơn hàng'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const RoleIntroCard(
          icon: Icons.receipt_long_rounded,
          title: 'Gói học & giao dịch',
          description: 'Quản lý giá gói, theo dõi đơn hàng và kiểm tra trạng thái thanh toán của gia đình.',
        ),
        const SizedBox(height: 16),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        Text('Danh mục giá', style: Theme.of(context).textTheme.titleLarge),
        const Text(
          'Giá nháp không hiện với phụ huynh. Giao dịch chỉ được xác nhận bởi backend VNPay.',
        ),
        ..._prices.map(
          (p) => Card(
            child: ListTile(
              title: Text(p.label),
              subtitle: Text(
                '${formatVnd(p.amountVnd)} · ${p.published ? "Đang bán" : "Nháp"}',
              ),
              trailing: const Icon(Icons.edit),
              onTap: _loading ? null : () => _edit(p),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Đơn hàng', style: Theme.of(context).textTheme.titleLarge),
        ..._orders.map(
          (o) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${o.label} · ${formatVnd(o.amountVnd)}'),
                  Text(o.displayStatus),
                  SelectableText('Đơn: ${o.id}\nPhụ huynh: ${o.parentId}'),
                  if (o.status == 'paid' &&
                      !_refunds.any(
                        (r) => r['order_id'] == o.id && r['status'] != 'failed',
                      ))
                    TextButton(
                      onPressed: _loading ? null : () => _refund(o),
                      child: const Text('Hoàn tiền toàn phần'),
                    ),
                  if (o.status != 'refunded')
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () async {
                              setState(() => _loading = true);
                              try {
                                await CommerceRepository.reconcile(o.id);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Chưa đối soát được giao dịch.',
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) await _load();
                              }
                            },
                      child: const Text('Đối soát VNPay'),
                    ),
                ],
              ),
            ),
          ),
        ),
        const Text('50 yêu cầu hoàn tiền gần nhất'),
        for (final r in _refunds)
          Card(
            child: ListTile(
              title: Text('${r['status']} · ${r['order_id']}'),
              subtitle: SelectableText(
                '${r['reason']}\n${r['external_reference'] ?? ""} · ${r['response_code'] ?? ""}',
              ),
            ),
          ),
        if (!_loading && _error == null && _orders.isEmpty)
          const Text('Chưa có đơn trên trang này.'),
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
              child: const Text('Trước'),
            ),
            Text('Trang ${_page + 1}'),
            TextButton(
              onPressed:
                  _loading || (_orders.length < 20 && _demoOrders.length < 20)
                  ? null
                  : () {
                      _page++;
                      _load();
                    },
              child: const Text('Sau'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Lịch sử thanh toán mô phỏng',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Text(
          'DEMO — không thu tiền và không tính vào doanh thu merchant. Không gửi hoàn tiền qua VNPay.',
        ),
        for (final demo in _demoOrders)
          DemoTransactionCard(order: demo, showParent: true),
      ],
    ),
  );
}
