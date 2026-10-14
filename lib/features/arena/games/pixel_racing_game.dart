import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/providers/app_state_provider.dart';

class PixelTurboMathRacingGame extends StatefulWidget {
  final AppStateProvider state;
  final VoidCallback onGameOver;

  const PixelTurboMathRacingGame({
    super.key,
    required this.state,
    required this.onGameOver,
  });

  @override
  State<PixelTurboMathRacingGame> createState() => _PixelTurboMathRacingGameState();
}

class _PixelTurboMathRacingGameState extends State<PixelTurboMathRacingGame> {
  double _myCarDistance = 0.1; // 0.1 to 0.85
  double _rivalCarDistance = 0.1;
  int _questionIndex = 0;
  int _turboBoosts = 0;
  bool _isFinished = false;
  bool _won = false;
  Timer? _rivalTimer;

  final List<Map<String, dynamic>> _racingQuestions = [
    {
      'q': '⚡ NITRO 1: 9 × 4 = ?',
      'options': [32, 36, 40],
      'ans': 36,
      'speed': 0.25,
    },
    {
      'q': '⚡ NITRO 2: 72 ÷ 8 = ?',
      'options': [9, 8, 7],
      'ans': 9,
      'speed': 0.25,
    },
    {
      'q': '⚡ NITRO 3: 45 + 55 = ?',
      'options': [90, 100, 110],
      'ans': 100,
      'speed': 0.25,
    },
    {
      'q': '⚡ CÁN ĐÍCH: 15 × 3 = ?',
      'options': [40, 45, 50],
      'ans': 45,
      'speed': 0.25,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Đối thủ AI xe tím tự động chạy từ từ
    _rivalTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted || _isFinished) {
        timer.cancel();
        return;
      }
      setState(() {
        _rivalCarDistance += 0.055;
        if (_rivalCarDistance >= 0.85 && !_isFinished) {
          _isFinished = true;
          _won = false;
          _rivalTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _rivalTimer?.cancel();
    super.dispose();
  }

  Future<void> _answerQuestion(int choice) async {
    final cur = _racingQuestions[_questionIndex];
    if (choice == cur['ans']) {
      setState(() {
        _myCarDistance += 0.22;
        _turboBoosts++;
        if (_questionIndex < _racingQuestions.length - 1) {
          _questionIndex++;
        }
      });

      if (_myCarDistance >= 0.85 && !_isFinished) {
        _rivalTimer?.cancel();
        setState(() {
          _isFinished = true;
          _won = true;
        });
        await widget.state.submitArenaScore(180);
      }
    } else {
      // Phạt nhẹ xe giật lại do trả lời sai
      setState(() {
        if (_myCarDistance > 0.05) _myCarDistance -= 0.05;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E), // Dark Cyber Racing
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00FFA3), width: 4), // Neon Pixel border
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FFA3).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Retro Cyber Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF11111B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Text('🏎️', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'TURBO MATH RACING 🏁',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00FFA3),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'NITRO x$_turboBoosts',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black),
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

            // 2-Lane Pixel Racing Track
            Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFF313244),
              child: Stack(
                children: [
                  // Vạch kẻ đường đứt đoạn
                  Positioned(
                    top: 88,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        10,
                        (i) => Container(
                          width: 18,
                          height: 4,
                          color: const Color(0xFFF9E2AF),
                        ),
                      ),
                    ),
                  ),

                  // Cột cờ đích (Finish Line Checkerboard)
                  Positioned(
                    right: 28,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Column(
                        children: List.generate(
                          8,
                          (i) => Expanded(
                            child: Container(
                              color: i % 2 == 0 ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Làn 1: Xe Bạn (Xe Đỏ Cute Pixel)
                  Positioned(
                    top: 15,
                    left: 10,
                    child: const Text('BẠN', style: TextStyle(color: Color(0xFFF38BA8), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    top: 28,
                    left: 10 + (_myCarDistance * 240),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏎️💨', style: TextStyle(fontSize: 32)),
                        if (_myCarDistance > 0.4)
                          const Text('⚡', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),

                  // Làn 2: Đối Thủ AI (Xe Tím Pixel)
                  Positioned(
                    bottom: 60,
                    left: 10,
                    child: const Text('ĐỐI THỦ (RIVAL)', style: TextStyle(color: Color(0xFFCBA6F7), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    bottom: 18,
                    left: 10 + (_rivalCarDistance * 240),
                    child: const Text('🚗💨', style: TextStyle(fontSize: 32)),
                  ),
                ],
              ),
            ),

            // Question or Game Over Screen
            Padding(
              padding: const EdgeInsets.all(16),
              child: _isFinished
                  ? Column(
                      children: [
                        Text(
                          _won ? '🏆 VỀ ĐÍCH HẠNG NHẤT! 🏆' : '💥 ĐỐI THỦ ĐÃ VỀ ĐÍCH TRƯỚC!',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: _won ? const Color(0xFF00FFA3) : const Color(0xFFF38BA8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _won
                              ? 'Tốc độ giải toán siêu nhanh đã giúp xe của bạn bứt phá nitro đoạt cúp!'
                              : 'Đối thủ đã nhanh tay hơn một chút, hãy luyện thêm phép tính nhẩm nhé!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _won ? const Color(0xFF00FFA3) : Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            widget.onGameOver();
                            Navigator.pop(context);
                          },
                          child: Text(
                            _won ? 'NHẬN 180 XP ĐẤU TRƯỜNG' : 'ĐÓNG',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181825),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF00FFA3), width: 2),
                          ),
                          child: Text(
                            _racingQuestions[_questionIndex]['q'],
                            style: const TextStyle(
                              color: Color(0xFF00FFA3),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: (_racingQuestions[_questionIndex]['options'] as List<int>).map((opt) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF89B4FA),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                              onPressed: () => _answerQuestion(opt),
                              child: Text(
                                '$opt',
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
