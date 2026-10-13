import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/providers/app_state_provider.dart';

class MarioPrincessRescueGame extends StatefulWidget {
  final AppStateProvider state;
  final VoidCallback onGameOver;

  const MarioPrincessRescueGame({
    super.key,
    required this.state,
    required this.onGameOver,
  });

  @override
  State<MarioPrincessRescueGame> createState() => _MarioPrincessRescueGameState();
}

class _MarioPrincessRescueGameState extends State<MarioPrincessRescueGame>
    with SingleTickerProviderStateMixin {
  int _stage = 0; // 0, 1, 2, 3 (3 = cứu được công chúa)
  double _marioX = 0.05; // 0.0 to 0.85
  double _marioY = 0.0; // nhảy lên (0 -> 1 -> 0)
  bool _isJumping = false;
  bool _isAnswerPromptOpen = false;
  bool _won = false;
  int _hearts = 3;
  int _score = 0;

  late final AnimationController _jumpController;

  final List<Map<String, dynamic>> _mathChallenges = [
    {
      'question': '🍄 Nấm Phép Thuật: 6 × 7 = ?',
      'options': [36, 42, 48],
      'answer': 42,
      'bonus': 'Mario hóa khổng lồ (+50 XP)',
    },
    {
      'question': '🐢 Vượt Rùa Gai: 81 ÷ 9 = ?',
      'options': [9, 8, 7],
      'answer': 9,
      'bonus': 'Đạp rùa gai bay xa (+60 XP)',
    },
    {
      'question': '🏰 Mở Khóa Lâu Đài: 125 + 75 = ?',
      'options': [190, 200, 210],
      'answer': 200,
      'bonus': 'Cứu Công Chúa Vương Quốc Toán Học (+100 XP)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _jumpController.addListener(() {
      setState(() {
        _marioY = (_jumpController.value < 0.5
            ? _jumpController.value * 2
            : (1 - _jumpController.value) * 2);
      });
    });
  }

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  void _jumpAndCollect() {
    if (_isJumping || _isAnswerPromptOpen || _won) return;
    setState(() => _isJumping = true);
    _jumpController.forward(from: 0.0).then((_) {
      setState(() {
        _isJumping = false;
        _isAnswerPromptOpen = true;
      });
    });
  }

  Future<void> _handleAnswer(int option) async {
    final currentQ = _mathChallenges[_stage];
    if (option == currentQ['answer']) {
      setState(() {
        _score += 70;
        _stage++;
        _marioX += 0.25;
        _isAnswerPromptOpen = false;
      });

      if (_stage >= 3) {
        setState(() => _won = true);
        await widget.state.submitArenaScore(200);
      }
    } else {
      setState(() {
        _hearts--;
        _isAnswerPromptOpen = false;
      });
      if (_hearts <= 0) {
        // Hết mạng
        await widget.state.submitArenaScore(_score);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5C94FC), // Mario Sky Blue 8-bit
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF000000), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Retro 8-bit Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFE52521), // Mario Red
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Text('🍄', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'SUPER MATH BROS',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      3,
                      (i) => Text(
                        i < _hearts ? '❤️' : '🖤',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      widget.onGameOver();
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            ),

            // Gameplay Window (Retro Pixel Canvas)
            Container(
              height: 220,
              width: double.infinity,
              color: const Color(0xFF6B8CFF),
              child: Stack(
                children: [
                  // Mây Pixel
                  Positioned(top: 20, left: 30, child: _pixelCloud()),
                  Positioned(top: 40, right: 60, child: _pixelCloud()),

                  // Lâu đài đích đến (Phía bên phải)
                  Positioned(
                    right: 16,
                    bottom: 38,
                    child: Column(
                      children: [
                        Text(_won ? '👑👸' : '🏰', style: const TextStyle(fontSize: 42)),
                        Text(
                          _won ? 'CÔNG CHÚA ĐÃ ĐƯỢC CỨU!' : 'LÂU ĐÀI',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nấm/Quái vật theo từng Stage
                  if (_stage < 3 && !_isAnswerPromptOpen)
                    Positioned(
                      left: 60.0 + (_stage * 75.0),
                      bottom: 45,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBD000),
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stage == 0 ? '🍄' : (_stage == 1 ? '🐢' : '🔑'),
                            style: const TextStyle(fontSize: 26),
                          ),
                        ],
                      ),
                    ),

                  // Mario Nhân vật nhảy
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 100),
                    left: 20 + (_marioX * 220),
                    bottom: 38 + (_marioY * 50),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('BẠN', style: TextStyle(color: Colors.yellow, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                        Text(
                          _won ? '🕺🎉' : (_isJumping ? '🏃‍♂️💨' : '👨‍🔧'),
                          style: const TextStyle(fontSize: 34),
                        ),
                      ],
                    ),
                  ),

                  // Đất Pixel Brick Ground
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC84C0C),
                        border: Border(top: BorderSide(color: Colors.black, width: 3)),
                      ),
                      child: Row(
                        children: List.generate(
                          12,
                          (i) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE06C38),
                                border: Border.all(color: const Color(0xFF802800), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dialog câu hỏi hoặc Nút điều khiển
            Padding(
              padding: const EdgeInsets.all(16),
              child: _won
                  ? Column(
                      children: [
                        const Text(
                          '🎉 CHIẾN THẮNG HOÀN HẢO! 🎉',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFFFBD000),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mario đã vượt qua mọi phép toán và giải cứu Công Chúa an toàn!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43B047),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.black, width: 3),
                            ),
                          ),
                          onPressed: () {
                            widget.onGameOver();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'NHẬN 200 XP & VỀ ĐẤU TRƯỜNG',
                            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  : _hearts <= 0
                      ? Column(
                          children: [
                            const Text('💀 GAME OVER 💀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                              onPressed: () {
                                widget.onGameOver();
                                Navigator.pop(context);
                              },
                              child: const Text('THỬ LẠI LẦN SAU', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      : _isAnswerPromptOpen
                          ? _buildMathQuestionBox()
                          : Column(
                              children: [
                                Text(
                                  'Chạm nút NHẢY để ăn Nấm & giải toán mở đường!',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFBD000), // Mario Coin Yellow
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Colors.black, width: 3),
                                    ),
                                  ),
                                  onPressed: _jumpAndCollect,
                                  icon: const Icon(Icons.arrow_upward_rounded, size: 24),
                                  label: const Text(
                                    'NHẢY ĂN NẤM PHÉP THUẬT',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMathQuestionBox() {
    final q = _mathChallenges[_stage];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Column(
        children: [
          Text(
            q['question'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFFE52521),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: (q['options'] as List<int>).map((ans) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A2E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                onPressed: () => _handleAnswer(ans),
                child: Text('$ans', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _pixelCloud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.2), width: 1.5),
      ),
      child: const Text('☁️', style: TextStyle(fontSize: 18)),
    );
  }
}
