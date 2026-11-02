import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../data/models/admin_dashboard.dart';
import '../../data/providers/admin_dashboard_controller.dart';
import 'role_ui.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.controller});
  final AdminDashboardController controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Matlingo Admin',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => AdminRoleGate(
        controller: controller,
        login: _AdminLogin(controller: controller),
        dashboard: AdminDashboardPage(
          key: ValueKey(controller.userId),
          controller: controller,
        ),
      ),
    ),
  );
}

class _AdminLogin extends StatefulWidget {
  const _AdminLogin({required this.controller});
  final AdminDashboardController controller;
  @override
  State<_AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<_AdminLogin> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _obscure = true;
  void _submit() {
    if (_form.currentState!.validate()) {
      widget.controller.signIn(_email.text, _password.text);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school_outlined, size: 48),
                const SizedBox(height: 24),
                Text(
                  'Matlingo Admin',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                const Text('Quản lý người dùng và nội dung học tập.'),
                const SizedBox(height: 32),
                TextFormField(
                  key: const ValueKey('admin-email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email quản trị',
                  ),
                  validator: (value) =>
                      value != null &&
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value.trim())
                      ? null
                      : 'Nhập email hợp lệ.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('admin-password'),
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Nhập mật khẩu.' : null,
                ),
                if (widget.controller.message != null) ...[
                  const SizedBox(height: 16),
                  Text(widget.controller.message!),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: widget.controller.busy ? null : _submit,
                  child: Text(
                    widget.controller.busy ? 'Đang đăng nhập…' : 'Đăng nhập',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.controller});
  final AdminDashboardController controller;
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminDashboardController get controller => widget.controller;
  bool _editing = false;
  AdminTopic? _topic;
  AdminAccount? _account;

  Future<void> _changeStatus(BuildContext context, AdminAccount account) async {
    setState(() => _account = account);
  }

  Future<void> _editTopic(BuildContext context, [AdminTopic? topic]) async {
    setState(() {
      _topic = topic;
      _editing = true;
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1000;
      final selected = controller.section == 'accounts' ? 0 : 1;
      final body = ListView(
        padding: EdgeInsets.all(wide ? 32 : 16),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan học tập',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.live
                        ? 'Realtime đang kết nối'
                        : 'Đang nối realtime · tự kiểm tra mỗi 30 giây',
                  ),
                  if (controller.updatedAt != null)
                    Text(
                      'Cập nhật ${TimeOfDay.fromDateTime(controller.updatedAt!).format(context)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: controller.loading ? null : controller.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final metric in const {
                'users': 'Người dùng',
                'active_users': 'Đang hoạt động',
                'suspended_users': 'Tạm khóa',
                'topics': 'Chủ đề máy chủ',
                'verified_completions': 'Lượt hoàn thành xác nhận',
              }.entries)
                SizedBox(
                  width: wide ? 188 : (constraints.maxWidth - 44) / 2,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.value,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${controller.overview[metric.key] ?? 0}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Text(
                selected == 0 ? 'Người dùng' : 'Chủ đề hiện có',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (selected == 1)
                FilledButton.icon(
                  key: const ValueKey('admin-add-topic'),
                  onPressed: controller.busy ? null : () => _editTopic(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm chủ đề'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: ValueKey('admin-search-${controller.section}'),
            initialValue: controller.search,
            maxLength: 100,
            onChanged: controller.setSearch,
            decoration: InputDecoration(
              labelText: selected == 0
                  ? 'Tìm tên, email hoặc ID người dùng'
                  : 'Tìm tên, môn học hoặc ID chủ đề',
              prefixIcon: const Icon(Icons.search_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          if (controller.message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                controller.message!,
                key: const ValueKey('admin-error'),
              ),
            ),
          if (controller.loading) const LinearProgressIndicator(),
          if (selected == 0 && controller.accounts.isNotEmpty)
            if (wide)
              _accountsTable(context)
            else
              ...controller.accounts.map(
                (account) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(account.email),
                        SelectableText(
                          account.id,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        _accountAction(context, account),
                      ],
                    ),
                  ),
                ),
              )
          else if (selected == 1 && controller.topics.isNotEmpty)
            if (wide)
              _topicsTable(context)
            else
              ...controller.topics.map(
                (topic) => Card(
                  child: ListTile(
                    isThreeLine: true,
                    title: Text(topic.title),
                    subtitle: Text(
                      '${topic.subject} · ${topic.activityCount} hoạt động\n${_status(topic.status)} · ${topic.id}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Sửa chủ đề',
                      onPressed: controller.busy
                          ? null
                          : () => _editTopic(context, topic),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                ),
              )
          else if (!controller.loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Không có dữ liệu phù hợp.'),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${controller.total} kết quả · Trang ${controller.offset ~/ 25 + 1}',
              ),
              OutlinedButton(
                onPressed: controller.loading || controller.offset == 0
                    ? null
                    : () => controller.page(controller.offset - 25),
                child: const Text('Trước'),
              ),
              OutlinedButton(
                onPressed:
                    controller.loading ||
                        controller.offset + 25 >= controller.total
                    ? null
                    : () => controller.page(controller.offset + 25),
                child: const Text('Tiếp'),
              ),
            ],
          ),
        ],
      );
      final page = Scaffold(
        appBar: AppBar(
          title: const Text('Matlingo · Admin'),
          actions: [
            if (wide) Center(child: Text(controller.email ?? '')),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: controller.signOut,
              icon: const Icon(Icons.logout),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Row(
          children: [
            if (wide)
              NavigationRail(
                extended: true,
                selectedIndex: selected,
                onDestinationSelected: (index) => controller.selectSection(
                  index == 0 ? 'accounts' : 'topics',
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    label: Text('Người dùng'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    label: Text('Chủ đề'),
                  ),
                ],
              ),
            if (wide) const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (index) => controller.selectSection(
                  index == 0 ? 'accounts' : 'topics',
                ),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.people_outline),
                    label: 'Người dùng',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    label: 'Chủ đề',
                  ),
                ],
              ),
      );
      final modal = _editing || _account != null;
      return Stack(
        children: [
          ExcludeFocus(
            excluding: modal,
            child: ExcludeSemantics(excluding: modal, child: page),
          ),
          if (modal)
            Positioned.fill(
              child: BlockSemantics(
                child: Stack(
                  children: [
                    const ModalBarrier(
                      dismissible: false,
                      color: Colors.black54,
                    ),
                    Center(
                      child: _editing
                          ? _TopicEditor(
                              controller: controller,
                              topic: _topic,
                              onClose: () {
                                if (mounted) setState(() => _editing = false);
                              },
                            )
                          : AlertDialog(
                              title: Text(
                                _account!.status == 'active'
                                    ? 'Tạm khóa tài khoản?'
                                    : 'Mở lại tài khoản?',
                              ),
                              content: Text(
                                '${_account!.name}\n${_account!.email}\n\nDữ liệu học tập được giữ nguyên.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: controller.busy
                                      ? null
                                      : () => setState(() => _account = null),
                                  child: const Text('Hủy'),
                                ),
                                FilledButton(
                                  onPressed: controller.busy
                                      ? null
                                      : () async {
                                          final account = _account!;
                                          final success = await controller
                                              .setAccountStatus(
                                                account,
                                                account.status == 'active'
                                                    ? 'suspended'
                                                    : 'active',
                                              );
                                          if (mounted && success) {
                                            setState(() => _account = null);
                                          }
                                        },
                                  child: Text(
                                    controller.busy ? 'Đang lưu…' : 'Xác nhận',
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  String _status(String status) => switch (status) {
    'active' => 'Đang hoạt động',
    'suspended' => 'Tạm khóa',
    'draft' => 'Bản nháp',
    'archived' => 'Lưu trữ',
    _ => status,
  };
  Widget _accountAction(BuildContext context, AdminAccount account) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(_status(account.status)),
      TextButton(
        onPressed:
            controller.busy || !['active', 'suspended'].contains(account.status)
            ? null
            : () => _changeStatus(context, account),
        child: Text(account.status == 'active' ? 'Tạm khóa' : 'Mở lại'),
      ),
    ],
  );
  Widget _accountsTable(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      dataRowMinHeight: 76,
      dataRowMaxHeight: 110,
      columns: const [
        DataColumn(label: Text('Người dùng')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Trạng thái / thao tác')),
      ],
      rows: controller.accounts
          .map(
            (account) => DataRow(
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name),
                      Text(
                        account.id,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                DataCell(Text(account.email)),
                DataCell(_accountAction(context, account)),
              ],
            ),
          )
          .toList(),
    ),
  );
  Widget _topicsTable(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      dataRowMinHeight: 64,
      dataRowMaxHeight: 100,
      columns: const [
        DataColumn(label: Text('Chủ đề')),
        DataColumn(label: Text('Môn học')),
        DataColumn(label: Text('Hoạt động')),
        DataColumn(label: Text('Trạng thái')),
        DataColumn(label: Text('Thứ tự')),
        DataColumn(label: Text('Thao tác')),
      ],
      rows: controller.topics
          .map(
            (topic) => DataRow(
              cells: [
                DataCell(Text(topic.title)),
                DataCell(Text(topic.subject)),
                DataCell(Text('${topic.activityCount}')),
                DataCell(Text(_status(topic.status))),
                DataCell(Text('${topic.sortOrder}')),
                DataCell(
                  IconButton(
                    tooltip: 'Sửa ${topic.title}',
                    onPressed: controller.busy
                        ? null
                        : () => _editTopic(context, topic),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    ),
  );
}

class _TopicEditor extends StatefulWidget {
  const _TopicEditor({
    required this.controller,
    required this.onClose,
    this.topic,
  });
  final AdminDashboardController controller;
  final VoidCallback onClose;
  final AdminTopic? topic;
  @override
  State<_TopicEditor> createState() => _TopicEditorState();
}

class _TopicEditorState extends State<_TopicEditor> {
  final _form = GlobalKey<FormState>();
  late final _id = TextEditingController(text: widget.topic?.id ?? ''),
      _title = TextEditingController(text: widget.topic?.title ?? ''),
      _subtitle = TextEditingController(text: widget.topic?.subtitle ?? ''),
      _subject = TextEditingController(text: widget.topic?.subject ?? ''),
      _sort = TextEditingController(text: '${widget.topic?.sortOrder ?? 0}');
  late String _status = widget.topic?.status ?? 'draft';
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    for (final field in [_id, _title, _subtitle, _subject, _sort]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final success = await widget.controller.saveTopic(
      AdminTopic(
        id: _id.text.trim(),
        title: _title.text.trim(),
        subtitle: _subtitle.text.trim(),
        subject: _subject.text.trim(),
        status: _status,
        sortOrder: int.parse(_sort.text),
        iconKey: widget.topic?.iconKey ?? 'menu_book_outlined',
        actionLabel: widget.topic?.actionLabel ?? '',
      ),
    );
    if (!mounted) return;
    if (success) {
      widget.onClose();
    } else {
      setState(() {
        _saving = false;
        _error = widget.controller.message ?? 'Chưa lưu được chủ đề.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.topic == null ? 'Thêm chủ đề' : 'Chỉnh sửa chủ đề'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chỉnh sửa metadata máy chủ. Nội dung bài đã phát hành giữ nguyên phiên bản; ứng dụng mobile hiện dùng catalog đóng gói.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('topic-id'),
                controller: _id,
                readOnly: widget.topic != null,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'ID (chữ thường và dấu gạch ngang)',
                ),
                validator: (v) =>
                    RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Ví dụ: logic-mo-rong',
              ),
              TextFormField(
                key: const ValueKey('topic-title'),
                controller: _title,
                maxLength: 160,
                decoration: const InputDecoration(labelText: 'Tên chủ đề'),
                validator: (v) =>
                    v?.trim().isNotEmpty == true ? null : 'Nhập tên chủ đề.',
              ),
              TextFormField(
                controller: _subtitle,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
              ),
              TextFormField(
                key: const ValueKey('topic-subject'),
                controller: _subject,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Môn học'),
                validator: (v) =>
                    v?.trim().isNotEmpty == true ? null : 'Nhập môn học.',
              ),
              TextFormField(
                controller: _sort,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Thứ tự'),
                validator: (v) {
                  final value = int.tryParse(v ?? '');
                  return value != null && value >= 0 && value <= 100000
                      ? null
                      : 'Nhập số từ 0 đến 100000.';
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Bản nháp')),
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('Đang hoạt động'),
                  ),
                  DropdownMenuItem(value: 'archived', child: Text('Lưu trữ')),
                ],
                onChanged: _saving ? null : (v) => setState(() => _status = v!),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : widget.onClose,
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Đang lưu…' : 'Lưu chủ đề'),
      ),
    ],
  );
}
