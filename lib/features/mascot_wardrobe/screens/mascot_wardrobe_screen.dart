import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../auth/widgets/mascot_owl_3d.dart';
import '../popups/item_buy_dialog.dart';

class MascotWardrobeScreen extends StatefulWidget {
  const MascotWardrobeScreen({super.key});

  @override
  State<MascotWardrobeScreen> createState() => _MascotWardrobeScreenState();
}

class _MascotWardrobeScreenState extends State<MascotWardrobeScreen> {
  int _activeCategoryIndex = 0; // 0: Tất cả, 1: Mũ nón, 2: Mắt kính, 3: Cánh/Hiệu ứng

  final List<Map<String, dynamic>> _allItems = [
    // Mũ nón
    {
      'id': 'hat_detective',
      'category': 1,
      'type': 'hat',
      'name': 'Mũ Thám Tử',
      'tag': 'Mũ nón',
      'buff': '+5% XP mỗi bài toán',
      'cost': 0,
      'icon': '🕵️',
    },
    {
      'id': 'hat_scholar',
      'category': 1,
      'type': 'hat',
      'name': 'Mũ Cử Nhân Thủ Khoa',
      'tag': 'Mũ nón',
      'buff': 'Soi giải bài khó',
      'cost': 40,
      'icon': '🎓',
    },
    {
      'id': 'hat_wizard',
      'category': 1,
      'type': 'hat',
      'name': 'Áo Choàng Phù Thủy',
      'tag': 'Trang phục',
      'buff': 'Cứu 1 mạng khi giải sai',
      'cost': 80,
      'icon': '🧙',
    },
    {
      'id': 'hat_crown',
      'category': 1,
      'type': 'hat',
      'name': 'Vương Miện Quán Quân',
      'tag': 'Huyền thoại',
      'buff': 'Top 1 Đấu Trường Tuần',
      'cost': 150,
      'icon': '👑',
    },
    // Mắt kính
    {
      'id': 'glasses_round',
      'category': 2,
      'type': 'glasses',
      'name': 'Kính Tròn Tri Thức',
      'tag': 'Mắt kính',
      'buff': 'Gợi ý phép chia nhanh',
      'cost': 0,
      'icon': '👓',
    },
    {
      'id': 'glasses_star',
      'category': 2,
      'type': 'glasses',
      'name': 'Kính Ngôi Sao',
      'tag': 'Mắt kính',
      'buff': '+10% Vàng nhận được',
      'cost': 35,
      'icon': '⭐',
    },
    {
      'id': 'glasses_monocle',
      'category': 2,
      'type': 'glasses',
      'name': 'Kính Thám Tử',
      'tag': 'Mắt kính',
      'buff': 'Nhìn thấy đáp án 50/50',
      'cost': 60,
      'icon': '🔍',
    },
    // Cánh / Hào quang
    {
      'id': 'wings_aura',
      'category': 3,
      'type': 'wings',
      'name': 'Cánh Hào Quang Thiên Thần',
      'tag': 'Cánh thần',
      'buff': 'x2 Xu khi thắng đấu trường',
      'cost': 100,
      'icon': '🪽',
    },
  ];

  String? _equippedWings = 'Cánh Hào Quang Thiên Thần';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;

    final filteredItems = _activeCategoryIndex == 0
        ? _allItems
        : _allItems.where((item) => item['category'] == _activeCategoryIndex).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'MathLingo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LỚP ${kid.grade}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Tủ Đồ & Mascot 3D',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Fire streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${kid.streakCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEA580C)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Hearts badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              children: [
                const Text('❤️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${kid.currentHearts}/${kid.maxHearts}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE11D48)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Tag Line
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Thám Tử Nhí • Lv.${kid.grade + 3}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 20, color: Color(0xFF64748B)),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, size: 20, color: Color(0xFF64748B)),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ================= BỤC TRƯNG BÀY 3D BÉ CÚ OLIVER =================
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Mascot 3D Cú thay đổi trực tiếp đồ đang mặc
                      Center(
                        child: MascotOwl3D(
                          size: 150,
                          hat: state.currentHat,
                          glasses: state.currentGlasses,
                          wings: _equippedWings,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tên Bé Cú
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Bé Cú Oliver',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, size: 20, color: Color(0xFFF97316)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bạn đồng hành toán học Lớp ${kid.grade}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 14),

                      // Pill badges hiển thị trang bị hiện tại
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildEquippedPill(
                            icon: Icons.face_rounded,
                            label: state.currentHat,
                            onRemove: () => state.updateMascotGear(hat: 'Không đội'),
                          ),
                          _buildEquippedPill(
                            icon: Icons.visibility_rounded,
                            label: state.currentGlasses,
                            onRemove: () => state.updateMascotGear(glasses: 'Không đeo'),
                          ),
                          if (_equippedWings != null && _equippedWings != 'Không có')
                            _buildEquippedPill(
                              icon: Icons.auto_awesome_rounded,
                              label: _equippedWings!,
                              onRemove: () => setState(() => _equippedWings = 'Không có'),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Dòng nút Tháo hết đồ & Buff
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              state.updateMascotGear(hat: 'Không đội', glasses: 'Không đeo');
                              setState(() => _equippedWings = 'Không có');
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF64748B)),
                                SizedBox(width: 4),
                                Text(
                                  'Tháo hết đồ',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF10B981)),
                              SizedBox(width: 2),
                              Text(
                                '+15% Thưởng Math',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ================= COIN & CRYSTAL BALANCE BAR =================
                Row(
                  children: [
                    // Xu vàng
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${kid.energyStars * 12}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                ),
                                const Text('XU VÀNG', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Pha lê
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Text('💎', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${kid.energyStars}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                                ),
                                const Text('PHA LÊ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Kiếm Xu button
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.monetization_on_rounded, size: 16),
                      label: const Text('Kiếm Xu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ================= CATEGORY FILTER TABS =================
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildCategoryTab(0, 'Tất cả'),
                      _buildCategoryTab(1, '🎩 Mũ nón'),
                      _buildCategoryTab(2, '👓 Mắt kính'),
                      _buildCategoryTab(3, '🪽 Cánh thần'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= GRID ITEMS 2 CỘT HIỆN ĐẠI =================
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final String type = item['type'] as String;
                    final String name = item['name'] as String;
                    final String tag = item['tag'] as String;
                    final String buff = item['buff'] as String;
                    final int cost = item['cost'] as int;
                    final String icon = item['icon'] as String;

                    bool isEquipped = false;
                    if (type == 'hat') {
                      isEquipped = state.currentHat.contains(name) || name.contains(state.currentHat);
                    } else if (type == 'glasses') {
                      isEquipped = state.currentGlasses.contains(name) || name.contains(state.currentGlasses);
                    } else if (type == 'wings') {
                      isEquipped = _equippedWings != null && _equippedWings!.contains(name);
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isEquipped ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
                          width: isEquipped ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Status Badge
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isEquipped
                                    ? const Color(0xFF10B981)
                                    : (cost == 0 ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isEquipped ? '✓ Đang mặc' : (cost == 0 ? 'Đã sở hữu' : 'Mới về'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isEquipped || cost == 0 ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),

                          // Large Item Emoji/Icon Container
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: Center(
                                  child: Text(icon, style: const TextStyle(fontSize: 38)),
                                ),
                              ),
                            ),
                          ),

                          // Tag Pill
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Item Name
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Buff info
                          Text(
                            buff,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Action Button: Đang dùng / Trang bị / Mua
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                if (type == 'wings') {
                                  setState(() {
                                    _equippedWings = isEquipped ? 'Không có' : name;
                                  });
                                } else {
                                  if (isEquipped) {
                                    // Tháo ra
                                    if (type == 'hat') state.updateMascotGear(hat: 'Không đội');
                                    if (type == 'glasses') state.updateMascotGear(glasses: 'Không đeo');
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (_) => ItemBuyDialog(
                                        state: state,
                                        gearType: type,
                                        itemName: name,
                                        costStars: cost,
                                        isEquipped: isEquipped,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEquipped
                                    ? const Color(0xFFEFF6FF)
                                    : (cost == 0 ? const Color(0xFF0284C7) : const Color(0xFFF97316)),
                                foregroundColor: isEquipped ? const Color(0xFF0284C7) : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                isEquipped
                                    ? '✓ Đang dùng'
                                    : (cost == 0 ? '⚡ Trang bị' : '$cost 🪙 Mua ngay'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ================= BOTTOM BAR LƯU NGAY CỐ ĐỊNH =================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diện Mạo Sẵn Sàng',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Oliver đã sẵn sàng giải toán!',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✨ Đã lưu diện mạo mới cho Bé Cú Oliver thành công!'),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('LƯU NGAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquippedPill({required IconData icon, required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0284C7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(int index, String label) {
    final isSelected = _activeCategoryIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeCategoryIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF97316) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
