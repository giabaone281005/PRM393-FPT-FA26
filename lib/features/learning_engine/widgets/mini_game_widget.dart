import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

class MiniGameWidget extends StatefulWidget {
  final String title;
  final String miniGameType;
  final Function(bool isWon) onGameFinished;

  const MiniGameWidget({
    super.key,
    required this.title,
    required this.miniGameType,
    required this.onGameFinished,
  });

  @override
  State<MiniGameWidget> createState() => _MiniGameWidgetState();
}

class _MiniGameWidgetState extends State<MiniGameWidget> {
  int _score = 0;
  final int _targetScore = 3;
  int _secondsLeft = 30;
  Timer? _timer;
  bool _gameOver = false;
  bool _gameWon = false;

  // Thuộc tính từng dạng game bám sát đề tài
  late String _gameMission;
  late String _questionFormula;
  late String _correctTarget;
  late List<String> _gameItems;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _score = 0;
    _secondsLeft = 30;
    _gameOver = false;
    _gameWon = false;
    _setupRound();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _gameOver = true;
          t.cancel();
          widget.onGameFinished(false);
        }
      });
    });
  }

  void _setupRound() {
    final t = widget.title;

    if (t.contains('Phân số') || t.contains('phân số')) {
      // Game 1: Bắt Cặp Phân Số Bằng Nhau
      final rounds = [
        {'q': 'Tìm phân số BẰNG VỚI 1/2:', 'target': '2/4', 'items': ['2/4', '1/3', '3/5', '2/5']},
        {'q': 'Tìm phân số BẰNG VỚI 2/3:', 'target': '4/6', 'items': ['4/6', '2/5', '3/4', '1/6']},
        {'q': 'Tìm phân số TỐI GIẢN của 4/8:', 'target': '1/2', 'items': ['1/2', '2/4', '2/3', '3/8']},
        {'q': 'Quy đồng 1/3 với mẫu 6 là:', 'target': '2/6', 'items': ['2/6', '3/6', '1/6', '4/6']},
      ];
      final current = rounds[_score % rounds.length];
      _gameMission = '🍕 THỬ THÁCH BÁNH PIZZA PHÂN SỐ';
      _questionFormula = current['q'] as String;
      _correctTarget = current['target'] as String;
      _gameItems = List<String>.from(current['items'] as List)..shuffle();
    } else if (t.contains('thập phân')) {
      // Game 2: Thần Tốc Dấu Phẩy Thập Phân
      final rounds = [
        {'q': '2.5 × 10 = ?', 'target': '25', 'items': ['25', '2.50', '0.25', '250']},
        {'q': '14.2 : 10 = ?', 'target': '1.42', 'items': ['1.42', '142', '0.142', '14.02']},
        {'q': '0.75 × 100 = ?', 'target': '75', 'items': ['75', '7.5', '750', '0.075']},
        {'q': '3.14 × 10 = ?', 'target': '31.4', 'items': ['31.4', '314', '3.140', '0.314']},
      ];
      final current = rounds[_score % rounds.length];
      _gameMission = '⚡ THẦN TỐC DỊCH DẤU PHẨY';
      _questionFormula = current['q'] as String;
      _correctTarget = current['target'] as String;
      _gameItems = List<String>.from(current['items'] as List)..shuffle();
    } else if (t.contains('Vận tốc') || t.contains('chuyển động') || t.contains('Quãng đường')) {
      // Game 3: Đua Xe Công Thức Vận Tốc
      final rounds = [
        {'q': 'Đoàn tàu s = 100km, t = 2h. Vận tốc v = ?', 'target': '50 km/h', 'items': ['50 km/h', '200 km/h', '60 km/h', '25 km/h']},
        {'q': 'Xe máy v = 40 km/h chạy 2h. Quãng đường s = ?', 'target': '80 km', 'items': ['80 km', '42 km', '20 km', '120 km']},
        {'q': 'Ô tô v = 60 km/h đi 180 km. Thời gian t = ?', 'target': '3 giờ', 'items': ['3 giờ', '2 giờ', '120 phút', '4 giờ']},
      ];
      final current = rounds[_score % rounds.length];
      _gameMission = '🏎️ ĐUA XE BẮT TỐC ĐỘ VẬN TỐC';
      _questionFormula = current['q'] as String;
      _correctTarget = current['target'] as String;
      _gameItems = List<String>.from(current['items'] as List)..shuffle();
    } else {
      // Game 4: Siêu Trí Nhớ Lưới Diện Tích & Bảng Tính
      final rounds = [
        {'q': 'Hình chữ nhật 4cm × 5cm. Diện tích = ?', 'target': '20 cm²', 'items': ['20 cm²', '18 cm²', '9 cm²', '24 cm²']},
        {'q': 'Hình vuông cạnh 6cm. Diện tích = ?', 'target': '36 cm²', 'items': ['36 cm²', '24 cm²', '12 cm²', '30 cm²']},
        {'q': 'Tính nhẩm thần tốc: 7 × 8 = ?', 'target': '56', 'items': ['56', '54', '48', '63']},
      ];
      final current = rounds[_score % rounds.length];
      _gameMission = '📐 ĐO LƯỜNG DIỆN TÍCH THẦN TỐC';
      _questionFormula = current['q'] as String;
      _correctTarget = current['target'] as String;
      _gameItems = List<String>.from(current['items'] as List)..shuffle();
    }
  }

  void _onItemTap(String item) {
    if (_gameOver || _gameWon) return;

    if (item == _correctTarget) {
      setState(() {
        _score++;
        if (_score >= _targetScore) {
          _gameWon = true;
          _gameOver = true;
          _timer?.cancel();
          widget.onGameFinished(true);
        } else {
          _setupRound();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa đúng rồi! Quan sát kỹ phép tính bài học nhé! 💡'),
          duration: Duration(milliseconds: 600),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(30),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Game
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🎮', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  Text(
                    _gameMission,
                    style: AppTypography.titleMedium.copyWith(
                      color: const Color(0xFF4338CA),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: Color(0xFF4F46E5), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_secondsLeft}s',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4F46E5), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Câu đố game bám sát bài học
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA5B4FC)),
            ),
            child: Column(
              children: [
                Text(
                  'Mục tiêu: Đạt 3 điểm (Hiện tại: $_score/$_targetScore)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                ),
                const SizedBox(height: 6),
                Text(
                  _questionFormula,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1B4B),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Vùng lựa chọn tương tác của game
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: _gameItems.length,
            itemBuilder: (context, index) {
              final val = _gameItems[index];

              return GestureDetector(
                onTap: () => _onItemTap(val),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      val,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          if (_gameWon) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('🎉', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Text(
                    'XUẤT SẮC! BẠN ĐÃ CHIẾN THẮNG GAME (+20 XP)!',
                    style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15803D), fontSize: 13),
                  ),
                ],
              ),
            ),
          ] else if (_gameOver) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startNewGame,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              child: const Text('HẾT GIỜ! BẤM ĐỂ CHƠI LẠI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
