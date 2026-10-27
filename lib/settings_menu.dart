import 'app_layout.dart';

import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_preferences.dart';
import 'learning_store.dart';
import 'features/account/cloud_account_page.dart';
import 'features/engines/engine_scope.dart';
import 'features/engines/engine_settings_page.dart';

enum _MenuDestination { appearance, cloud, engines, gift, about, help, logout }

class SettingsMenuButton extends StatelessWidget {
  const SettingsMenuButton({super.key, required this.store});
  final LearningStore store;
  @override
  Widget build(BuildContext context) => PopupMenuButton<_MenuDestination>(
    key: const ValueKey('app-settings'),
    tooltip: 'Menu ứng dụng',
    icon: const Icon(Icons.menu_rounded),
    position: PopupMenuPosition.under,
    constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    color: Theme.of(context).colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shadowColor: const Color(0x18000000),
    onSelected: (destination) async {
      if (destination == _MenuDestination.logout) {
        final cloud = CloudScope.maybeOf(context);
        if (cloud != null) {
          await cloud.signOut();
        } else {
          await store.signOut();
        }
        return;
      }
      final page = switch (destination) {
        _MenuDestination.appearance => const AppearancePage(),
        _MenuDestination.cloud => CloudAccountPage(
          controller: CloudScope.maybeOf(context)!,
        ),
        _MenuDestination.engines => EngineSettingsPage(
          runtime: EngineScope.maybeOf(context)!.runtime,
        ),
        _MenuDestination.gift => const GiftPremiumPage(),
        _MenuDestination.about => const AboutMatlingoPage(),
        _MenuDestination.help => const HelpMatlingoPage(),
        _MenuDestination.logout => const SizedBox.shrink(),
      };
      if (context.mounted) {
        Navigator.push(context, DiscoveryRoute<void>(builder: (_) => page));
      }
    },
    itemBuilder: (_) => [
      if (EngineScope.maybeOf(context) != null)
        const PopupMenuItem(
          value: _MenuDestination.engines,
          key: ValueKey('menu-engines'),
          child: Text('Engine học tập'),
        ),
      if (CloudScope.maybeOf(context) != null)
        const PopupMenuItem(
          value: _MenuDestination.cloud,
          child: Text('Tài khoản & sao lưu'),
        ),
      const PopupMenuItem(
        value: _MenuDestination.appearance,
        key: ValueKey('menu-appearance'),
        child: Text('Cài đặt'),
      ),
      const PopupMenuItem(
        value: _MenuDestination.gift,
        key: ValueKey('menu-gift'),
        child: Text('Tặng Premium'),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: _MenuDestination.about,
        key: ValueKey('menu-about'),
        child: Text('Giới thiệu'),
      ),
      const PopupMenuItem(
        value: _MenuDestination.help,
        key: ValueKey('menu-help'),
        child: Text('Trợ giúp'),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: _MenuDestination.logout,
        key: ValueKey('menu-logout'),
        child: Text('Đăng xuất'),
      ),
    ],
  );
}

class _InformationPage extends StatelessWidget {
  const _InformationPage({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageHeader(title: Text(title)),
    body: AppPageBody(children: children),
  );
}

class GiftPremiumPage extends StatelessWidget {
  const GiftPremiumPage({super.key});
  @override
  Widget build(BuildContext context) => _InformationPage(
    title: 'Tặng Premium',
    children: [
      const SizedBox(height: 28),
      Icon(
        Icons.card_giftcard_rounded,
        size: 88,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 28),
      Text(
        'Món quà cho\nsự tò mò.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 24),
      const Text(
        'Tính năng tặng Premium đang được chuẩn bị.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      const Text(
        'Hiện tại, bạn có thể khám phá miễn phí toàn bộ 10 chủ đề và 46 thí nghiệm trong Matlingo. Khi mở quà tặng, thông tin gói và giá sẽ xuất hiện tại đây.',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.6),
      ),
      const SizedBox(height: 28),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Tiếp tục khám phá'),
      ),
    ],
  );
}

class AboutMatlingoPage extends StatelessWidget {
  const AboutMatlingoPage({super.key});
  @override
  Widget build(BuildContext context) => _InformationPage(
    title: 'Giới thiệu',
    children: [
      Icon(
        Icons.auto_awesome,
        color: Theme.of(context).colorScheme.primary,
        size: 48,
      ),
      const SizedBox(height: 24),
      Text('Matlingo', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      const Text('Hiểu bằng cách tự tay làm.', style: TextStyle(fontSize: 18)),
      const SizedBox(height: 8),
      const Text('Phiên bản 1.3.0 (4)'),
      const SizedBox(height: 28),
      const Text(
        'Kéo, xoay, ghép và thử. Mỗi chủ đề là ba thí nghiệm nhỏ giúp bạn tự tìm ra quy luật.',
        style: TextStyle(height: 1.6),
      ),
      const SizedBox(height: 24),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.grid_view_rounded),
        title: Text('10 chủ đề · 46 thí nghiệm'),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.offline_bolt_outlined),
        title: Text('Học và lưu tiến độ offline'),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.person_outline),
        title: Text('Hồ sơ riêng trên thiết bị'),
      ),
      const Divider(height: 36),
      Text('Dữ liệu của bạn', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      const Text(
        'Hồ sơ và tiến độ được lưu trên thiết bị. Mở Tài khoản & sao lưu để liên kết hồ sơ với tài khoản cloud và khôi phục trên điện thoại khác. Đăng xuất không xóa hồ sơ; hãy kiểm tra bản sao lưu trước khi gỡ ứng dụng.',
        style: TextStyle(height: 1.6),
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: () => openAppearance(context),
        icon: const Icon(Icons.tune_rounded),
        label: const Text('Tùy chỉnh giao diện'),
      ),
    ],
  );
}

class HelpMatlingoPage extends StatefulWidget {
  const HelpMatlingoPage({super.key});
  @override
  State<HelpMatlingoPage> createState() => _HelpMatlingoPageState();
}

class _HelpMatlingoPageState extends State<HelpMatlingoPage> {
  String query = '';
  static const questions = [
    (
      'Bắt đầu học như thế nào?',
      'Chọn Chủ đề, mở một thẻ bạn thích rồi vào phòng thí nghiệm. Bạn có thể tự do thử và thay đổi mô hình trước khi kiểm tra.',
    ),
    (
      'Làm sao học tiếp và xem tiến độ?',
      'Nút Học tiếp trên Trang chủ mở đúng bước bạn đã lưu. Tab Chủ đề có bộ lọc Đang học, dấu hoàn thành, thành tựu và lịch sử.',
    ),
    (
      'XP được tính ra sao?',
      'Hoàn thành cả ba thí nghiệm của một chủ đề để nhận 30 XP lần đầu. Ôn lại vẫn lưu lịch sử nhưng không cộng trùng XP.',
    ),
    (
      'Đổi hồ sơ hoặc đăng xuất có mất bài không?',
      'Không. Mở tab Hồ sơ để lưu phiên hoặc đổi người học. Đăng xuất giữ lại hồ sơ và tiến độ trên thiết bị; chọn lại hồ sơ để tiếp tục.',
    ),
    (
      'Có cần kết nối mạng để học không?',
      'Các thí nghiệm và tiến độ hoạt động offline. Nếu được kết nối trong tương lai, trợ lý chat sẽ cần mạng để trả lời.',
    ),
    (
      'Vì sao chat chưa gửi được?',
      'Trợ lý hiện chưa được kết nối. Bạn có thể soạn câu hỏi và chọn gợi ý; nút gửi sẽ hoạt động khi trợ lý sẵn sàng.',
    ),
    (
      'Đổi nền, màu và cỡ chữ ở đâu?',
      'Mở menu ở góc trên bên phải, chọn Cài đặt. Thay đổi được áp dụng ngay và lưu trên thiết bị.',
    ),
    (
      'Đã có thể tặng Premium chưa?',
      'Chưa. Mục Tặng Premium hiện giới thiệu tính năng sắp có; chưa có bước thanh toán. Toàn bộ nội dung hiện có vẫn dùng miễn phí.',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final results = questions
        .where(
          (q) => '${q.$1} ${q.$2}'.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return _InformationPage(
      title: 'Trợ giúp',
      children: [
        Text(
          'Bạn cần giúp gì?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('help-search'),
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Tìm câu hỏi…',
          ),
        ),
        const SizedBox(height: 20),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Chưa tìm thấy. Thử từ khóa khác nhé.'),
          ),
        for (final question in results)
          ExpansionTile(
            key: ValueKey(question.$1),
            tilePadding: EdgeInsets.zero,
            title: Text(
              question.$1,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(question.$2, style: const TextStyle(height: 1.6)),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
