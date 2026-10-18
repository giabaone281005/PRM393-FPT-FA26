import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/widgets/role_ui.dart';
import '../../auth/widgets/mascot_owl_3d.dart';

class ParentDashboardView extends StatefulWidget {
  const ParentDashboardView({
    super.key,
    required this.report,
    required this.limits,
    required this.plus,
    required this.maxKids,
    required this.loading,
    required this.error,
    required this.email,
    required this.sound,
    required this.dark,
    required this.onRefresh,
    required this.onNotifications,
    required this.onExit,
    required this.onAdd,
    required this.onEdit,
    required this.onRestore,
    required this.onChoose,
    required this.onLimit,
    required this.onPlans,
    required this.onAccount,
    required this.onPin,
    required this.onSupport,
    required this.onSound,
    required this.onTheme,
    this.syncedAt,
  });
  final Map<String, dynamic> report;
  final Map<String, int> limits;
  final bool plus, loading, sound, dark;
  final int maxKids;
  final String email;
  final String? error;
  final DateTime? syncedAt;
  final Future<void> Function() onRefresh;
  final VoidCallback onNotifications,
      onExit,
      onAdd,
      onPlans,
      onAccount,
      onPin,
      onSupport,
      onSound,
      onTheme;
  final ValueChanged<Map<String, dynamic>> onEdit, onRestore, onChoose, onLimit;
  @override
  State<ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<ParentDashboardView> {
  int _tab = 0;
  String? _selectedId;
  final _scroll = ScrollController();
  static const _labels = ['Tổng quan', 'Các bé', 'Gói học', 'Tài khoản'];
  static const _icons = [
    Icons.home_rounded,
    Icons.people_rounded,
    Icons.workspace_premium_rounded,
    Icons.person_rounded,
  ];
  Color get _muted => Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkTextSecondary
      : AppColors.textSecondary;
  Color get _line => Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkBorderSubtle
      : AppColors.borderSubtle;
  Color get _canvas => Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkBackground
      : AppColors.background;
  List<Map<String, dynamic>> get _kids => (widget.report['kids'] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  Map<String, dynamic>? get _kid {
    final kids = _kids;
    if (kids.isEmpty) return null;
    final active = (widget.report['entitlements'] as Map?)?['active_kid_id'];
    return kids.firstWhere(
      (k) => k['id'] == (_selectedId ?? active),
      orElse: () => kids.first,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(int tab) {
    setState(() => _tab = tab);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  String _number(dynamic value) =>
      value is num ? NumberFormat.decimalPattern('vi').format(value) : '—';
  String _minutes(dynamic value) =>
      value is num ? (value > 0 && value < 60 ? '<1' : '${value ~/ 60}') : '—';
  String _sessionStatus(Map last) {
    if (last['status'] == 'completed') return 'Đã hoàn thành';
    final heartbeat = DateTime.tryParse('${last['last_heartbeat_at']}');
    final age = heartbeat == null ? null : DateTime.now().difference(heartbeat);
    return last['status'] == 'active' &&
            last['last_active'] == true &&
            age != null &&
            !age.isNegative &&
            age <= const Duration(seconds: 45)
        ? 'Đang học'
        : 'Đang tạm dừng';
  }

  Widget _panel(
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(20),
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
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
  Widget _heading(String title, {String? subtitle, Widget? trailing}) =>
      LayoutBuilder(
        builder: (context, box) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: _muted, height: 1.5),
                ),
              ],
            ],
          );
          if (box.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (trailing != null) ...[const SizedBox(height: 10), trailing],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              ?trailing,
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) => Theme(
    data: roleTheme(context),
    child: LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 1000;
        return Scaffold(
          backgroundColor: _canvas,
          bottomNavigationBar: wide
              ? null
              : RoleNavigationBar(
                  selectedIndex: _tab,
                  onSelected: _select,
                  labels: _labels,
                  icons: _icons,
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  NavigationRail(
                    extended: true,
                    selectedIndex: _tab,
                    onDestinationSelected: _select,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    indicatorColor: AppColors.primary.withValues(alpha: .12),
                    leading: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'MathLingo',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    destinations: [
                      for (var i = 0; i < 4; i++)
                        NavigationRailDestination(
                          icon: Icon(_icons[i]),
                          label: Text(_labels[i]),
                        ),
                    ],
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _topbar(),
                      if (widget.loading)
                        const LinearProgressIndicator(minHeight: 2),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: widget.onRefresh,
                          child: SingleChildScrollView(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.all(wide ? 32 : 20),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1050,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      [
                                        'CÙNG CON TIẾN BỘ',
                                        'HỒ SƠ HỌC TẬP',
                                        'QUYỀN HỌC GIA ĐÌNH',
                                        'THIẾT LẬP GIA ĐÌNH',
                                      ][_tab],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.4,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Text(
                                      [
                                        'Gia đình & học tập',
                                        'Các bé trong gia đình',
                                        'Gói học của bạn',
                                        'Tài khoản phụ huynh',
                                      ][_tab],
                                      style: const TextStyle(
                                        fontSize: 27,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      [
                                        'Một nơi để theo dõi và đồng hành cùng bé.',
                                        'Mỗi bé một hành trình, cả nhà cùng tiến bộ.',
                                        'Theo dõi quyền học và lịch sử giao dịch.',
                                        'Bảo mật tài khoản và trải nghiệm của gia đình.',
                                      ][_tab],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _muted,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    if (widget.error != null) ...[
                                      _panel(
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline,
                                              color: AppColors.accentRed,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                widget.error!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: widget.loading
                                                  ? null
                                                  : widget.onRefresh,
                                              child: const Text('Thử lại'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    if (_tab < 2 && _kids.isNotEmpty) ...[
                                      _picker(),
                                      const SizedBox(height: 18),
                                    ],
                                    if (_tab == 0) _overview(),
                                    if (_tab == 1) _profiles(),
                                    if (_tab == 2) _plans(),
                                    if (_tab == 3) _account(),
                                    const SizedBox(height: 24),
                                    Center(
                                      child: Text(
                                        'MathLingo • Đồng hành cùng gia đình',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 11,
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

  Widget _topbar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(bottom: BorderSide(color: _line)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MathLingo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              Text(
                'GIA ĐÌNH',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: widget.onNotifications,
          icon: const Icon(Icons.notifications_none_rounded, size: 21),
        ),
        PopupMenuButton<String>(
          tooltip: 'Tùy chọn phụ huynh',
          onSelected: (value) {
            if (value == 'refresh') widget.onRefresh();
            if (value == 'account') _select(3);
            if (value == 'exit') widget.onExit();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'account',
              child: Text('Tài khoản phụ huynh'),
            ),
            PopupMenuItem(
              value: 'refresh',
              enabled: !widget.loading,
              child: const Text('Cập nhật dữ liệu'),
            ),
            const PopupMenuItem(
              value: 'exit',
              child: Text('Về chế độ học sinh'),
            ),
          ],
          child: CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.primary.withValues(alpha: .12),
            child: const Text(
              'PH',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _picker() => Row(
    children: [
      Icon(Icons.face_rounded, color: _muted, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _kid?['id'] as String?,
            items: [
              for (final k in _kids)
                DropdownMenuItem(
                  value: k['id'] as String,
                  child: Text(
                    '${k['nickname']} · Lớp ${k['grade']}${k['archived'] == true ? ' · Lưu trữ' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
            onChanged: (id) => setState(() => _selectedId = id),
          ),
        ),
      ),
      const SizedBox(width: 12),
      _badge(widget.plus ? 'PLUS' : 'BASIC'),
    ],
  );
  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: .5,
      ),
    ),
  );

  Widget _overview() {
    final k = _kid;
    if (k == null) return _empty();
    final seconds = k['today_seconds'] as num?;
    final limit =
        (k['screen_time_limit_minutes'] as num?)?.toInt() ??
        widget.limits[k['id']];
    final last = k['last_session'] as Map?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.syncedAt != null) ...[
          Text(
            'Cập nhật lúc ${DateFormat('HH:mm:ss').format(widget.syncedAt!.toLocal())}',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _metric(
                'Bài đã hoàn thành',
                _number(k['completed']),
                Icons.menu_book_rounded,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metric(
                'Phút học hôm nay',
                _minutes(seconds),
                Icons.schedule_rounded,
                const Color(0xFF6885D6),
              ),
            ),
          ],
        ),
        if (limit != null && seconds != null) ...[
          const SizedBox(height: 14),
          _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading(
                  'Nhịp học hôm nay',
                  trailing: Text(
                    '${_minutes(seconds)} / $limit phút',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: (seconds / (limit * 60)).clamp(0.0, 1.0),
                    minHeight: 7,
                    color: AppColors.primary,
                    backgroundColor: _canvas,
                    semanticsLabel: 'Thời gian học trong giới hạn hôm nay',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  seconds >= limit * 60
                      ? 'Bé đã đạt giới hạn học hôm nay.'
                      : 'Còn ${(limit - seconds / 60).ceil()} phút trong giới hạn hôm nay.',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            const ExcludeSemantics(child: MascotOwl3D(size: 64)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cú nhắc nhỏ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    seconds != null && seconds > 0
                        ? 'Một lời động viên sẽ giúp con thêm tự tin sau buổi học hôm nay.'
                        : 'Cùng bé bắt đầu một bài học nhỏ hôm nay nhé!',
                    style: TextStyle(fontSize: 12, height: 1.6, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _week(k),
        if (last != null) ...[
          const SizedBox(height: 14),
          _panel(
            _heading(
              'Bài học gần nhất',
              subtitle:
                  '${last['title'] ?? 'Phiên học'} · ${_sessionStatus(last)}'
                  '${last['duration_seconds'] is num ? '\nThời lượng đã xác nhận: ${(last['duration_seconds'] as num).toInt() ~/ 60} phút ${(last['duration_seconds'] as num).toInt() % 60} giây' : ''}',
              trailing: Icon(Icons.bookmark_outline, color: _muted),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _heading('Quản lý nhanh'),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth > 700 ? 4 : 2;
            final width = (box.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _shortcut(
                  'Hồ sơ bé',
                  'Quản lý các con',
                  Icons.people_rounded,
                  () => _select(1),
                  width,
                ),
                _shortcut(
                  'Thời gian học',
                  'Giới hạn mỗi ngày',
                  Icons.timer_outlined,
                  k['archived'] == true ? null : () => widget.onLimit(k),
                  width,
                ),
                _shortcut(
                  'Gói học',
                  'Quyền học & lịch sử',
                  Icons.workspace_premium_rounded,
                  () => _select(2),
                  width,
                ),
                _shortcut(
                  'Hỗ trợ',
                  'Đồng hành cùng gia đình',
                  Icons.support_agent_rounded,
                  widget.onSupport,
                  width,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) =>
      _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 17),
            Text(
              value,
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
      );

  Widget _week(Map<String, dynamic> k) {
    final days = (k['days'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final maxSeconds = days.fold<double>(
      1,
      (value, d) =>
          math.max(value, (d['total_seconds'] as num? ?? 0).toDouble()),
    );
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            '7 ngày gần đây',
            trailing: Text(
              'Phút học',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ),
          const SizedBox(height: 22),
          if (days.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Chưa có thời lượng học trong 7 ngày qua.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in days) Expanded(child: _day(d, maxSeconds)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _day(Map<String, dynamic> d, double maximum) {
    final date = DateTime.tryParse('${d['study_date']}');
    final seconds = (d['total_seconds'] as num? ?? 0).toDouble();
    final label = date == null ? '—' : DateFormat('dd/MM').format(date);
    return Semantics(
      label: '$label: ${_minutes(seconds)} phút học',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _minutes(seconds),
                style: TextStyle(fontSize: 11, color: _muted),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 22,
                    height: math.max(3, seconds / maximum * 80),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(fontSize: 10, color: _muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcut(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? action,
    double width,
  ) => SizedBox(
    width: width,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _line),
      ),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: action == null ? _muted : AppColors.primary,
                    size: 24,
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded, size: 14, color: _muted),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: _muted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _profiles() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        'Hồ sơ gia đình',
        subtitle:
            '${widget.plus ? 'Plus' : 'Basic'} · Tối đa ${widget.maxKids} hồ sơ hoạt động',
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: widget.onAdd,
        icon: const Icon(Icons.person_add_alt_rounded),
        label: const Text('Thêm bé'),
      ),
      const SizedBox(height: 18),
      if (_kids.isEmpty) _empty(),
      for (final k in _kids) ...[
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: .1),
                    child: const Icon(
                      Icons.face_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${k['nickname']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lớp ${k['grade']}${k['archived'] == true ? ' · Đã lưu trữ' : ''}',
                          style: TextStyle(fontSize: 12, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: _line),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () => widget.onEdit(k),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Sửa hồ sơ'),
                  ),
                  if (k['archived'] == true)
                    TextButton(
                      onPressed: () => widget.onRestore(k),
                      child: const Text('Khôi phục'),
                    ),
                  if (k['archived'] != true)
                    TextButton.icon(
                      onPressed: () => widget.onLimit(k),
                      icon: const Icon(Icons.timer_outlined, size: 16),
                      label: const Text('Thời gian học'),
                    ),
                  if (!widget.plus && k['archived'] != true)
                    TextButton(
                      onPressed:
                          (widget.report['entitlements']
                                  as Map?)?['active_kid_id'] ==
                              k['id']
                          ? null
                          : () => widget.onChoose(k),
                      child: Text(
                        (widget.report['entitlements']
                                    as Map?)?['active_kid_id'] ==
                                k['id']
                            ? 'Đang học với Basic'
                            : 'Chọn học với Basic',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (_kid != null) ...[const SizedBox(height: 8), _skills(_kid!)],
      const SizedBox(height: 16),
      Text(
        'Hết Plus không xóa hồ sơ. Basic học với một bé được chọn; các thành tích khác vẫn được giữ.',
        style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
      ),
    ],
  );
  Widget _skills(Map<String, dynamic> k) {
    final skills = k['skills'] as List? ?? [];
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'Kỹ năng của ${k['nickname']}',
            subtitle: 'Từ các lượt trả lời đã được ghi nhận',
          ),
          if (skills.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Chưa có đủ dữ liệu kỹ năng.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          for (final s in skills) ...[
            const SizedBox(height: 20),
            Text(
              '${s['name']} · ${s['accuracy']}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: ((s['accuracy'] as num? ?? 0) / 100).clamp(0.0, 1.0),
                minHeight: 6,
                color: AppColors.primary,
                backgroundColor: _canvas,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${s['attempts']} lượt trả lời${(s['accuracy'] as num? ?? 100) < 70 ? ' · Nên ôn thêm kỹ năng này.' : ''}',
              style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _plans() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFEF3C7),
              size: 28,
            ),
            const SizedBox(height: 20),
            const Text(
              'GÓI HỌC GIA ĐÌNH',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.3,
                color: Color(0xFFFFEDD5),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              widget.plus ? 'MathLingo Plus' : 'MathLingo Basic',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tối đa ${widget.maxKids} hồ sơ hoạt động',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Text(
              'Theo dõi tiến độ riêng của từng bé.\nLịch sử học tập được giữ lại khi đổi gói.',
              style: TextStyle(
                color: Color(0xFFFFEDD5),
                fontSize: 12,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: widget.onPlans,
          icon: const Icon(Icons.receipt_long_outlined, size: 19),
          label: const Text('Xem gói và lịch sử mua'),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Mua theo kỳ, không tự gia hạn. Khôi phục quyền học và kiểm tra giao dịch trong Gói học tập.',
        style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
      ),
    ],
  );
  Widget _account() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading('Tài khoản phụ huynh', subtitle: widget.email),
            const SizedBox(height: 20),
            _setting(
              'Bảo mật tài khoản',
              Icons.shield_outlined,
              widget.onAccount,
            ),
            _setting('Đổi PIN phụ huynh', Icons.key_rounded, widget.onPin),
            _setting(
              'Liên hệ hỗ trợ',
              Icons.support_agent_rounded,
              widget.onSupport,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _panel(
        Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Âm thanh phản hồi',
                style: TextStyle(fontSize: 13),
              ),
              secondary: Icon(Icons.volume_up_outlined, color: _muted),
              value: widget.sound,
              onChanged: (_) => widget.onSound(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Giao diện tối',
                style: TextStyle(fontSize: 13),
              ),
              secondary: Icon(Icons.dark_mode_outlined, color: _muted),
              value: widget.dark,
              onChanged: (_) => widget.onTheme(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: widget.onExit,
        icon: const Icon(Icons.lock_outline_rounded, size: 19),
        label: const Text('Về chế độ học sinh'),
      ),
    ],
  );
  Widget _setting(String title, IconData icon, VoidCallback action) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: _muted, size: 22),
    title: Text(title, style: const TextStyle(fontSize: 13)),
    trailing: Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
    onTap: action,
  );
  Widget _empty() => _panel(
    Column(
      children: [
        Icon(Icons.family_restroom_rounded, size: 38, color: _muted),
        const SizedBox(height: 16),
        Text(
          widget.error == null ? 'Chưa có hồ sơ bé' : 'Chưa tải được hồ sơ',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          widget.error == null
              ? 'Thêm bé đầu tiên để bắt đầu theo dõi hành trình học tập.'
              : 'Kiểm tra kết nối và thử cập nhật lại dữ liệu.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _muted, height: 1.6),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: widget.error == null ? widget.onAdd : widget.onRefresh,
          icon: Icon(
            widget.error == null ? Icons.person_add_alt_rounded : Icons.refresh,
          ),
          label: Text(widget.error == null ? 'Thêm bé' : 'Thử lại'),
        ),
      ],
    ),
  );
}
// Widget _metric(String label, String value, IconData icon, Color color) =>
//     _panel(
//       Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(9),
//             decoration: BoxDecoration(
//               color: color.withValues(alpha: .1),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: color, size: 21),
//           ),
//           const SizedBox(height: 17),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 29,
//               fontWeight: FontWeight.w800,
//               letterSpacing: -.8,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             label,
//             style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(18),
//     );
//
// Widget _week(Map<String, dynamic> k) {
//   final days = (k['days'] as List? ?? [])
//       .map((e) => Map<String, dynamic>.from(e as Map))
//       .toList();
//   final maxSeconds = days.fold<double>(
//     1,
//         (value, d) =>
//         math.max(value, (d['total_seconds'] as num? ?? 0).toDouble()),
//   );
//   return _panel(
//     Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _heading(
//           '7 ngày gần đây',
//           trailing: Text(
//             'Phút học',
//             style: TextStyle(fontSize: 11, color: _muted),
//           ),
//         ),
//         const SizedBox(height: 22),
//         if (days.isEmpty)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 20),
//             child: Center(
//               child: Text(
//                 'Chưa có thời lượng học trong 7 ngày qua.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 12, color: _muted),
//               ),
//             ),
//           )
//         else
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               for (final d in days) Expanded(child: _day(d, maxSeconds)),
//             ],
//           ),
//       ],
//     ),
//   );
// }
//
// Widget _day(Map<String, dynamic> d, double maximum) {
//   final date = DateTime.tryParse('${d['study_date']}');
//   final seconds = (d['total_seconds'] as num? ?? 0).toDouble();
//   final label = date == null ? '—' : DateFormat('dd/MM').format(date);
//   return Semantics(
//     label: '$label: ${_minutes(seconds)} phút học',
//     child: ExcludeSemantics(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 3),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               _minutes(seconds),
//               style: TextStyle(fontSize: 11, color: _muted),
//             ),
//             const SizedBox(height: 8),
//             SizedBox(
//               height: 80,
//               child: Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Container(
//                   width: 22,
//                   height: math.max(3, seconds / maximum * 80),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary.withValues(alpha: .65),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(label, style: TextStyle(fontSize: 10, color: _muted)),
//           ],
//         ),
//       ),
//     ),
//   );
// }
//
// Widget _shortcut(
//     String title,
//     String subtitle,
//     IconData icon,
//     VoidCallback? action,
//     double width,
//     ) => SizedBox(
//   width: width,
//   child: Material(
//     color: Theme.of(context).colorScheme.surface,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(16),
//       side: BorderSide(color: _line),
//     ),
//     child: InkWell(
//       onTap: action,
//       borderRadius: BorderRadius.circular(16),
//       child: Padding(
//         padding: const EdgeInsets.all(17),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   icon,
//                   color: action == null ? _muted : AppColors.primary,
//                   size: 24,
//                 ),
//                 const Spacer(),
//                 Icon(Icons.arrow_outward_rounded, size: 14, color: _muted),
//               ],
//             ),
//             const SizedBox(height: 18),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               subtitle,
//               style: TextStyle(fontSize: 11, color: _muted, height: 1.5),
//             ),
//           ],
//         ),
//       ),
//     ),
//   ),
// );
