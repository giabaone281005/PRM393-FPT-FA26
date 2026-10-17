import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../shared/widgets/role_ui.dart';

const _ink = AppColors.textPrimary;
const _muted = AppColors.textSecondary;
const _orange = AppColors.primary;
const _line = AppColors.borderSubtle;
const _canvas = AppColors.background;

/// Presentation only. All permissions and mutations remain in the controller.
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({
    super.key,
    required this.parents,
    required this.stats,
    required this.busy,
    required this.error,
    required this.page,
    required this.tier,
    required this.email,
    required this.onRefresh,
    required this.onSearch,
    required this.onTier,
    required this.onPage,
    required this.onFamily,
    required this.onSupportFamily,
    required this.onCommerce,
    required this.onContent,
    required this.onRoles,
    required this.onSupport,
    required this.onAi,
    required this.onLogout,
  });

  final Map<String, dynamic> parents, stats;
  final bool busy;
  final String? error;
  final int page;
  final String tier, email;
  final Future<void> Function() onRefresh;
  final VoidCallback onCommerce, onContent, onRoles, onSupport, onAi, onLogout;
  final ValueChanged<String> onSearch, onTier;
  final ValueChanged<int> onPage;
  final ValueChanged<Map<String, dynamic>> onFamily, onSupportFamily;

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _section = 0;
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  static const _titles = ['Tổng quan', 'Gia đình', 'Hoạt động'];
  static const _icons = [
    Icons.home_rounded,
    Icons.people_rounded,
    Icons.history_rounded,
  ];

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _section = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  String _number(dynamic value) => value == null
      ? '—'
      : NumberFormat.decimalPattern('vi').format(num.tryParse('$value') ?? 0);

  Widget _panel(
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(20),
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _heading(String title, {String? subtitle, Widget? trailing}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final adminTheme = roleTheme(context, base: AppTheme.lightTheme);
    return Theme(
      data: adminTheme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1000;
          return Scaffold(
            bottomNavigationBar: desktop
                ? null
                : RoleNavigationBar(
                    selectedIndex: _section,
                    onSelected: _select,
                    labels: _titles,
                    icons: _icons,
                  ),
            body: SafeArea(
              child: Row(
                children: [
                  if (desktop) _sidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        _topbar(desktop),
                        if (widget.busy)
                          const LinearProgressIndicator(minHeight: 2),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: widget.onRefresh,
                            child: SingleChildScrollView(
                              controller: _scroll,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.all(desktop ? 32 : 20),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1280,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _pageHeader(),
                                      const SizedBox(height: 24),
                                      if (widget.error != null) ...[
                                        _errorBanner(),
                                        const SizedBox(height: 20),
                                      ],
                                      if (_section == 0) _overview(),
                                      if (_section == 1) _families(),
                                      if (_section == 2) _activity(),
                                      const SizedBox(height: 24),
                                      const Center(
                                        child: Text(
                                          'MathLingo • Không gian quản trị',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _muted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sidebar() => Container(
    width: 240,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: _line)),
    ),
    padding: const EdgeInsets.all(20),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _brand(),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text(
              'KHÔNG GIAN LÀM VIỆC',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.3,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++)
            _navItem(
              _titles[i],
              _icons[i],
              () => _select(i),
              selected: _section == i,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _navItem(
            'Nội dung học tập',
            Icons.auto_stories_outlined,
            widget.onContent,
          ),
          _navItem(
            'Gói & giao dịch',
            Icons.receipt_long_outlined,
            widget.onCommerce,
          ),
          _navItem('Hỗ trợ', Icons.support_agent_rounded, widget.onSupport),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _canvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_outlined, color: _orange),
                SizedBox(height: 10),
                Text(
                  'Cùng trẻ tiến bộ mỗi ngày',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Quản lý trải nghiệm học tập trong một không gian.',
                  style: TextStyle(fontSize: 11, color: _muted, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _navItem('Đăng xuất', Icons.logout_rounded, widget.onLogout),
        ],
      ),
    ),
  );

  Widget _navItem(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool selected = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: selected ? AppColors.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? _orange : _muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _orange : _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _brand() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _orange,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 10),
      const Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MathLingo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
            Text(
              'ADMIN WORKSPACE',
              style: TextStyle(
                fontSize: 8,
                color: _muted,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _topbar(bool desktop) => Container(
    padding: EdgeInsets.symmetric(horizontal: desktop ? 32 : 20, vertical: 14),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: _line)),
    ),
    child: Row(
      children: [
        if (!desktop)
          _brand()
        else
          Text(
            'Không gian quản trị  /  ${_titles[_section]}',
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        const Spacer(),
        IconButton(
          tooltip: 'Làm mới dữ liệu',
          onPressed: widget.busy ? null : widget.onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 21),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Tài khoản quản trị',
          onSelected: (_) => widget.onLogout(),
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Text(widget.email, style: const TextStyle(fontSize: 12)),
            ),
            const PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
          ],
          child: const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              'AD',
              style: TextStyle(
                color: _orange,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _pageHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _section == 0
            ? 'BỨC TRANH HÔM NAY'
            : _section == 1
            ? 'QUẢN LÝ TÀI KHOẢN'
            : 'NHẬT KÝ QUẢN TRỊ',
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.6,
          color: _orange,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        _section == 0
            ? 'Tổng quan hệ thống'
            : _section == 1
            ? 'Gia đình & học viên'
            : 'Hoạt động gần đây',
        style: const TextStyle(
          fontSize: 27,
          letterSpacing: -.9,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _section == 0
            ? 'Theo dõi học tập và vận hành MathLingo.'
            : _section == 1
            ? 'Tìm kiếm, xem hồ sơ và hỗ trợ từng gia đình.'
            : 'Theo dõi các thay đổi và thao tác quản trị.',
        style: const TextStyle(fontSize: 13, height: 1.5, color: _muted),
      ),
    ],
  );

  Widget _errorBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EE),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: Color(0xFFC64834)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.error!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFC64834)),
          ),
        ),
        TextButton(onPressed: widget.onRefresh, child: const Text('Thử lại')),
      ],
    ),
  );

  Widget _overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LayoutBuilder(
        builder: (context, box) {
          final columns = box.maxWidth >= 760 ? 4 : 2;
          final width = (box.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metric(
                'Gia đình',
                widget.parents['total'],
                Icons.people_rounded,
                AppColors.primary,
                width,
              ),
              _metric(
                'Hồ sơ bé',
                widget.parents['kid_total'],
                Icons.face_rounded,
                const Color(0xFF6885D6),
                width,
              ),
              _metric(
                'Plus hiệu lực',
                widget.parents['plus_total'],
                Icons.workspace_premium_rounded,
                const Color(0xFFB18A39),
                width,
              ),
              _metric(
                'Phiên học / 7 ngày',
                widget.stats['sessions_week'],
                Icons.local_library_outlined,
                const Color(0xFF48A290),
                width,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryHover, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFFEF3C7),
                  size: 19,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DOANH THU ĐÃ XÁC MINH',
                    style: TextStyle(
                      color: Color(0xFFFFEDD5),
                      fontSize: 10,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_number(widget.stats['verified_revenue_vnd'])} đ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                letterSpacing: -1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 24,
              runSpacing: 10,
              children: [
                _paymentCount(
                  'Đã thanh toán',
                  widget.stats['paid_orders'],
                  const Color(0xFF82D8B7),
                ),
                _paymentCount(
                  'Đang chờ',
                  widget.stats['pending_orders'],
                  const Color(0xFFFEF3C7),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                onPressed: widget.onCommerce,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text(
                  'Xem giao dịch',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      _heading(
        'Truy cập nhanh',
        subtitle: 'Các công việc quản trị thường dùng',
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, box) {
          final columns = box.maxWidth >= 760 ? 3 : 2;
          final width = (box.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _shortcut(
                'Gia đình',
                'Hồ sơ & gói học',
                Icons.people_rounded,
                _orange,
                () => _select(1),
                width,
              ),
              _shortcut(
                'Nội dung',
                'Chủ đề & bài học',
                Icons.auto_stories_outlined,
                const Color(0xFF6885D6),
                widget.onContent,
                width,
              ),
              _shortcut(
                'Giao dịch',
                'Gói học & đơn hàng',
                Icons.receipt_long_outlined,
                const Color(0xFF48A290),
                widget.onCommerce,
                width,
              ),
              _shortcut(
                'Hỗ trợ',
                'Yêu cầu từ gia đình',
                Icons.support_agent_rounded,
                const Color(0xFFAF7AC5),
                widget.onSupport,
                width,
              ),
              _shortcut(
                'Phân quyền',
                'Admin & biên tập',
                Icons.admin_panel_settings_outlined,
                const Color(0xFF668398),
                widget.onRoles,
                width,
              ),
              _shortcut(
                'Trợ lý AI',
                'Thiết lập hạn mức',
                Icons.auto_awesome_outlined,
                const Color(0xFFB18A39),
                widget.onAi,
                width,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 28),
      _activity(preview: true),
    ],
  );

  Widget _metric(
    String label,
    dynamic value,
    IconData icon,
    Color color,
    double width,
  ) => SizedBox(
    width: width,
    child: _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 17),
          Text(
            _number(value),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _muted, height: 1.4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
    ),
  );

  Widget _paymentCount(String label, dynamic value, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(
        '${_number(value)}  $label',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ],
  );

  Widget _shortcut(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    double width,
  ) => SizedBox(
    width: width,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 25),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    color: _muted,
                    size: 15,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: _muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _families() {
    final items = widget.parents['items'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panel(
          Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: widget.onSearch,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm theo email…',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _muted,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: _muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tier in {
                          '': 'Tất cả',
                          'basic': 'Basic',
                          'plus': 'Plus',
                        }.entries)
                          ChoiceChip(
                            label: Text(
                              tier.value,
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: widget.tier == tier.key,
                            onSelected: widget.busy
                                ? null
                                : (_) => widget.onTier(tier.key),
                            showCheckmark: false,
                            selectedColor: AppColors.primaryLight,
                            side: BorderSide(
                              color: widget.tier == tier.key
                                  ? _orange.withValues(alpha: .3)
                                  : _line,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '${_number(widget.parents['total'])} gia đình trong hệ thống',
          style: const TextStyle(fontSize: 12, color: _muted),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty && !widget.busy)
          _empty(
            Icons.search_off_rounded,
            'Không tìm thấy gia đình',
            'Thử một email khác hoặc thay đổi bộ lọc.',
          ),
        for (final raw in items) ...[
          _familyCard(Map<String, dynamic>.from(raw)),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Trang trước',
              onPressed: widget.page == 0 || widget.busy
                  ? null
                  : () => widget.onPage(widget.page - 1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Trang ${widget.page + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Trang sau',
              onPressed: items.length < 20 || widget.busy
                  ? null
                  : () => widget.onPage(widget.page + 1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _familyCard(Map<String, dynamic> p) {
    final email = '${p['email'] ?? 'Chưa có email'}';
    final subscription = p['subscription'] as Map?;
    final expiry = DateTime.tryParse('${subscription?['expires_at']}');
    final plus =
        subscription?['tier'] == 'plus' &&
        subscription?['status'] == 'active' &&
        (expiry == null || expiry.isAfter(DateTime.now()));
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFFF0F3F8),
                child: Text(
                  email.isEmpty ? '?' : email[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF668398),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${p['kid_count'] ?? 0} hồ sơ bé',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: plus ? const Color(0xFFFFF4DB) : _canvas,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plus ? 'PLUS' : 'BASIC',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                    color: plus ? const Color(0xFFAD822C) : _muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => widget.onFamily(p),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text(
                  'Xem gia đình',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              TextButton.icon(
                onPressed: () => widget.onSupportFamily(p),
                icon: const Icon(Icons.redeem_rounded, size: 15),
                label: const Text(
                  'Cấp bù Plus',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _activity({bool preview = false}) {
    final logs = widget.stats['audit'] as List? ?? [];
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'Hoạt động gần đây',
            subtitle: preview
                ? 'Các thay đổi mới nhất trong hệ thống'
                : '50 thao tác quản trị gần nhất',
            trailing: preview
                ? IconButton(
                    tooltip: 'Xem tất cả hoạt động',
                    onPressed: () => _select(2),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          if (logs.isEmpty)
            _empty(
              Icons.history_rounded,
              'Chưa có hoạt động',
              'Các thao tác quản trị sẽ xuất hiện tại đây.',
            ),
          for (final raw in logs.take(preview ? 4 : 50))
            _logItem(Map<String, dynamic>.from(raw)),
        ],
      ),
    );
  }

  Widget _logItem(Map<String, dynamic> log) {
    const labels = {
      'CREATE_QA_FIXTURE': 'Tạo tài khoản kiểm thử',
      'SUPPORT_CHANGE': 'Điều chỉnh gói học',
      'ROLE_CHANGE': 'Thay đổi phân quyền',
      'PUBLISH_LESSON': 'Xuất bản bài học',
      'REFUND_REQUEST': 'Yêu cầu hoàn tiền',
      'REFUND_RESULT': 'Cập nhật hoàn tiền',
      'NORMALIZE_LEGACY': 'Cập nhật dữ liệu học tập',
    };
    final action = '${log['action'] ?? 'Thao tác quản trị'}';
    final date = DateTime.tryParse('${log['created_at']}')?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 48, bottom: 12),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const CircleAvatar(
          radius: 17,
          backgroundColor: _canvas,
          child: Icon(Icons.history_rounded, size: 17, color: _muted),
        ),
        title: Text(
          labels[action] ?? action.replaceAll('_', ' ').toLowerCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          date == null
              ? 'Chưa có thời gian'
              : DateFormat('dd/MM/yyyy · HH:mm').format(date),
          style: const TextStyle(fontSize: 10, color: _muted),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              'Người thực hiện: ${log['actor_id'] ?? 'Hệ thống'}\nĐối tượng: ${log['target_type'] ?? '—'}\n${log['details'] ?? ''}',
              style: const TextStyle(fontSize: 11, color: _muted, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 32, color: _muted.withValues(alpha: .5)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: _muted, height: 1.5),
          ),
        ],
      ),
    ),
  );
}
