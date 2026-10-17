import 'dart:async';

import 'package:flutter/material.dart';

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
  State<MarioPrincessRescueGame> createState() =>
      _MarioPrincessRescueGameState();
}

class _MarioPrincessRescueGameState extends State<MarioPrincessRescueGame>
    with SingleTickerProviderStateMixin {
  // Tọa độ thế giới Mario
  // Mario x: từ 20 đến 1250 (Công chúa ở x = 1180)
  double _marioX = 40.0;
  double _marioY = 0.0; // Chiều cao nhảy từ mặt đất (0 -> 90)
  bool _isJumping = false;
  bool _isMovingLeft = false;
  bool _isMovingRight = false;
  bool _facingRight = true;
  Timer? _gameLoopTimer;

  // Trạng thái game
  int _hearts = 3;
  int _score = 297200;
  int _coins = 65;
  final int _time = 268;
  bool _won = false;
  bool _isMathPromptOpen = false;

  // Animation nhảy
  late final AnimationController _jumpController;

  // Danh sách các ống nước xanh (Green Pipes) và các khối hộp xanh (Blue Blocks)
  final List<double> _pipePositions = [320.0, 680.0, 980.0];
  final double _pipeWidth = 56.0;
  final double _pipeHeight = 58.0;

  // Khối tháp hộp xanh (Blue Question / Steel Blocks giống ảnh mẫu NES World 3)
  final List<double> _blueBlockTowerX = [240.0, 600.0, 900.0];

  // Danh sách Quái vật (Goomba / Koopa / Bowser) canh giữ dọc đường
  final List<Map<String, dynamic>> _monsters = [
    {
      'id': 1,
      'name': 'Nấm Độc Goomba',
      'emoji': '🍄',
      'x': 450.0,
      'defeated': false,
      'question': '🍄 Nấm Goomba: 8 × 7 = ?',
      'options': [54, 56, 64],
      'answer': 56,
      'reward': '+100 Điểm',
    },
    {
      'id': 2,
      'name': 'Rùa Gai Koopa',
      'emoji': '🐢',
      'x': 780.0,
      'defeated': false,
      'question': '🐢 Rùa Gai Koopa: 108 ÷ 9 = ?',
      'options': [11, 12, 13],
      'answer': 12,
      'reward': '+150 Điểm',
    },
    {
      'id': 3,
      'name': 'Rồng Lửa Bowser',
      'emoji': '🦖',
      'x': 1060.0,
      'defeated': false,
      'question': '🦖 Đấu Trùm Lâu Đài: 450 + 270 = ?',
      'options': [720, 710, 730],
      'answer': 720,
      'reward': '+200 Điểm',
    },
  ];

  Map<String, dynamic>? _currentActiveMonster;
  final double _princessX = 1180.0;

  @override
  void initState() {
    super.initState();
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _jumpController.addListener(() {
      setState(() {
        // Nhảy cao và mượt mà hơn để dễ dàng vượt chướng ngại vật
        final val = _jumpController.value;
        _marioY = 4 * 105 * val * (1 - val);
      });
      _checkCollisions();
    });

    _jumpController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isJumping = false;
          _marioY = 0.0;
        });
        _jumpController.reset();
        _checkCollisions();
      }
    });

    // Game Loop 60fps để xử lý di chuyển mượt mà
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_won || _hearts <= 0 || _isMathPromptOpen) return;

      bool positionChanged = false;
      if (_isMovingRight) {
        _facingRight = true;
        _marioX += 5.0;
        positionChanged = true;
      } else if (_isMovingLeft) {
        _facingRight = false;
        _marioX = (_marioX - 5.0).clamp(20.0, 1300.0);
        positionChanged = true;
      }

      // Xử lý va chạm vật lý với ống nước:
      // Mario chỉ bị chặn lại từ phía bên hông khi đang ở tầm thấp (dưới độ cao ống)
      for (final px in _pipePositions) {
        final double pipeLeft = px - 20.0;
        final double pipeRight = px + _pipeWidth - 8.0;
        if (_marioX >= pipeLeft && _marioX <= pipeRight) {
          if (_marioY < _pipeHeight - 12) {
            if (_isMovingRight && _marioX < px) {
              _marioX = pipeLeft;
            } else if (_isMovingLeft && _marioX > px + 10) {
              _marioX = pipeRight;
            }
          }
        }
      }

      if (positionChanged) {
        setState(() {});
        _checkCollisions();
      }
    });
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _jumpController.dispose();
    super.dispose();
  }

  void _jump() {
    if (_isJumping || _isMathPromptOpen || _won || _hearts <= 0) return;
    setState(() => _isJumping = true);
    _jumpController.forward(from: 0.0);
  }

  void _checkCollisions() {
    if (_isMathPromptOpen || _won || _hearts <= 0) return;

    // 1. Kiểm tra chạm công chúa ở cuối map
    if (_marioX >= _princessX - 40) {
      setState(() {
        _won = true;
        _isMovingLeft = false;
        _isMovingRight = false;
        _score += 5000;
      });
      widget.state.submitArenaScore(200);
      return;
    }

    // 2. Kiểm tra đụng độ quái vật chưa bị hạ
    for (var monster in _monsters) {
      if (!monster['defeated']) {
        final double mx = monster['x'];
        if ((_marioX - mx).abs() < 36) {
          setState(() {
            _isMovingLeft = false;
            _isMovingRight = false;
            _isMathPromptOpen = true;
            _currentActiveMonster = monster;
          });
          break;
        }
      }
    }
  }

  Future<void> _handleAnswer(int selected) async {
    if (_currentActiveMonster == null) return;

    final monster = _currentActiveMonster!;
    if (selected == monster['answer']) {
      setState(() {
        monster['defeated'] = true;
        _score += 1000;
        _coins += 5;
        // Mario tự động nhảy vượt qua quái vật sau khi giải đúng để tiếp tục di chuyển mượt mà
        _marioX = (monster['x'] as double) + 48.0;
        _isMathPromptOpen = false;
        _currentActiveMonster = null;
        _isMovingLeft = false;
        _isMovingRight = false;
      });
      _jump(); // Nhảy ăn mừng
    } else {
      setState(() {
        _hearts--;
        // Trả lời sai: giật lùi về sau an toàn
        _marioX = ((monster['x'] as double) - 55.0).clamp(20.0, 1300.0);
        _isMathPromptOpen = false;
        _currentActiveMonster = null;
        _isMovingLeft = false;
        _isMovingRight = false;
      });

      if (_hearts <= 0) {
        await widget.state.submitArenaScore(150);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chiều rộng khung nhìn camera
    const double viewportWidth = 320.0;
    double cameraX = _marioX - (viewportWidth / 2);
    if (cameraX < 0) cameraX = 0;
    if (cameraX > (1300 - viewportWidth)) cameraX = 1300 - viewportWidth;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(4, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ================= 1. NINTENDO NES TOP STATUS BAR =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Mario text & Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MARIO',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        _score.toString().padLeft(6, '0'),
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  // Coins
                  Row(
                    children: [
                      _buildPixelCoin(),
                      const SizedBox(width: 4),
                      Text(
                        'x${_coins.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // World & Hearts
                  Column(
                    children: [
                      const Text(
                        'WORLD 3-1',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          3,
                          (i) => Text(
                            i < _hearts ? '❤️' : '🖤',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Close button
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      widget.onGameOver();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // ================= 2. GAME CANVAS VIEWPORT (CHUẨN NES WORLD 3 CỦA HÌNH ẢNH MẪU) =================
            Container(
              height: 230,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBD0A4), // Nền màu cam nhạt cát vàng chuẩn Mario Bros 3 (Desert/Water World 3)
                border: Border(
                  top: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: ClipRect(
                child: Stack(
                  children: [
                    // Cảnh vật di chuyển theo Camera
                    Transform.translate(
                      offset: Offset(-cameraX, 0),
                      child: SizedBox(
                        width: 1350,
                        height: 230,
                        child: Stack(
                          children: [
                            // 1. Mây trắng viền đen mắt đen kiểu Mario Bros 3
                            Positioned(
                              top: 25,
                              left: 120,
                              child: _buildRetroMarioCloud(),
                            ),
                            Positioned(
                              top: 45,
                              left: 450,
                              child: _buildRetroMarioCloud(),
                            ),
                            Positioned(
                              top: 30,
                              left: 820,
                              child: _buildRetroMarioCloud(),
                            ),
                            Positioned(
                              top: 40,
                              left: 1120,
                              child: _buildRetroMarioCloud(),
                            ),

                            // 2. Tiền xu lơ lửng dọc đường (Giống hàng đồng xu trên ảnh mẫu)
                            ...List.generate(
                              5,
                              (i) => Positioned(
                                left: 60.0 + (i * 26.0),
                                bottom: 55,
                                child: _buildPixelCoin(),
                              ),
                            ),

                            // 3. Khối tháp hộp xanh (Blue X-Blocks kiểu Mario 3)
                            ..._blueBlockTowerX.map(
                              (bx) => Positioned(
                                left: bx,
                                bottom: 40,
                                child: _buildBlueBlockTower(),
                              ),
                            ),

                            // 4. Các ống nước xanh kinh điển chuẩn 8-bit (Green Warp Pipes)
                            ..._pipePositions.map(
                              (px) => Positioned(
                                left: px,
                                bottom: 40,
                                child: _buildPixelGreenPipe(),
                              ),
                            ),

                            // 5. Quái vật canh giữ dọc đường
                            ..._monsters.map((m) {
                              if (m['defeated']) {
                                return Positioned(
                                  left: m['x'],
                                  bottom: 46,
                                  child: const Text(
                                    '💨',
                                    style: TextStyle(fontSize: 22),
                                  ),
                                );
                              }
                              return Positioned(
                                left: m['x'],
                                bottom: 44,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'MATH',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.yellow,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      m['emoji'],
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            // 6. Đích đến: Công Chúa & Lâu Đài
                            Positioned(
                              left: _princessX - 25,
                              bottom: 40,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.pink,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Text(
                                      'CỨU CÔNG CHÚA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _won ? '💖👸💖' : '👸',
                                        style: const TextStyle(fontSize: 34),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '🏰',
                                        style: TextStyle(fontSize: 48),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 7. Nhân vật Mario phong cách Pixel Sprite
                            Positioned(
                              left: _marioX,
                              bottom: 40 + _marioY,
                              child: Transform.scale(
                                scaleX: _facingRight ? 1.0 : -1.0,
                                scaleY: 1.0,
                                child: _buildPixelMarioSprite(),
                              ),
                            ),

                            // 8. Dải sóng biển xanh nước biển (Ocean Water giống ảnh mẫu của người dùng)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: _buildPixelOceanWaves(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= 3. NINTENDO NES BOTTOM HUD STRIP (WORLD 3 / METER / CARD CAROUSEL) =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: Colors.black,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Row(
                  children: [
                    // World info & P-Meter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'WORLD 3 ',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // P-Meter speed arrows
                              ...List.generate(
                                6,
                                (i) => Container(
                                  margin: const EdgeInsets.only(right: 2),
                                  child: Text(
                                    '▶',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color:
                                          (_isMovingLeft || _isMovingRight) &&
                                              i < 4
                                          ? const Color(0xFFFBD000)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 1,
                                ),
                                color: (_isMovingLeft || _isMovingRight)
                                    ? Colors.orange
                                    : Colors.white,
                                child: Text(
                                  'P',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: (_isMovingLeft || _isMovingRight)
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$$_coins',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text(
                                'M x 04  ',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_score.toString().padLeft(6, '0')}  ',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '⏱ $_time',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Item Box Slots (Mushroom / Star / Card)
                    Row(
                      children: [
                        _buildRetroCardSlot('🍄'),
                        const SizedBox(width: 4),
                        _buildRetroCardSlot('⭐'),
                        const SizedBox(width: 4),
                        _buildRetroCardSlot('🌸'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ================= 4. KHU VỰC ĐIỀU KHIỂN NÚT BẤM PIXEL CHUẨN ẢNH ASSET =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: const Color(0xFF242730), // Nền xám đậm retro
              child: _won
                  ? _buildVictoryBox()
                  : _hearts <= 0
                  ? _buildGameOverBox()
                  : _isMathPromptOpen
                  ? _buildMathQuestionBox()
                  : _buildPixelButtonsController(),
            ),
          ],
        ),
      ),
    );
  }

  // Ống nước xanh Pixel phong cách Mario 3 (đúng ảnh mẫu)
  Widget _buildPixelGreenPipe() {
    return Column(
      children: [
        // Đầu ống nước (vành trên rộng hơn)
        Container(
          width: _pipeWidth,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF00A800),
            border: Border.all(color: Colors.black, width: 2.5),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                color: const Color(0xFF88F888),
              ), // Highlight vệt sáng
              Container(width: 14, color: const Color(0xFF00D800)),
              Expanded(child: Container(color: const Color(0xFF00A800))),
              Container(
                width: 10,
                color: const Color(0xFF005000),
              ), // Bóng tối bên phải
            ],
          ),
        ),
        // Thân ống nước
        Container(
          width: _pipeWidth - 8,
          height: _pipeHeight - 18,
          decoration: BoxDecoration(
            color: const Color(0xFF00A800),
            border: Border.all(color: Colors.black, width: 2.5),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                color: const Color(0xFF88F888),
              ), // Highlight vệt sáng
              Container(width: 12, color: const Color(0xFF00D800)),
              Expanded(child: Container(color: const Color(0xFF00A800))),
              Container(width: 8, color: const Color(0xFF005000)), // Bóng tối
            ],
          ),
        ),
      ],
    );
  }

  // Khối tháp hộp xanh (Blue Blocks X) giống hệt ảnh mẫu NES World 3
  Widget _buildBlueBlockTower() {
    return Column(
      children: List.generate(
        4,
        (i) => Container(
          width: 30,
          height: 22,
          margin: const EdgeInsets.symmetric(vertical: 0.5),
          decoration: BoxDecoration(
            color: const Color(0xFF0068DE),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Stack(
            children: [
              // Họa tiết dấu X màu xanh nhạt
              Center(
                child: CustomPaint(
                  size: const Size(26, 18),
                  painter: _BlueBlockPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dải sóng biển Pixel xanh lam ở đáy bản đồ
  Widget _buildPixelOceanWaves() {
    return SizedBox(
      width: 1350,
      child: Column(
        children: [
          // Sóng nước trắng răng cưa
          Container(
            height: 8,
            color: const Color(0xFF0068DE),
            child: Row(
              children: List.generate(
                90,
                (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(top: 1),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // Nước biển xanh thẳm
          Container(
            height: 32,
            color: const Color(0xFF0068DE),
            child: Row(
              children: List.generate(
                45,
                (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    height: 3,
                    color: const Color(0xFF88D8F8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mây trắng mắt đen kiểu Mario Bros 3
  Widget _buildRetroMarioCloud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 3, height: 6, color: Colors.black),
          const SizedBox(width: 10),
          Container(width: 3, height: 6, color: Colors.black),
        ],
      ),
    );
  }

  // Đồng xu pixel vàng
  Widget _buildPixelCoin() {
    return Container(
      width: 10,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFFFBD000),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Center(
        child: Container(width: 2, height: 10, color: const Color(0xFFE52521)),
      ),
    );
  }

  // Sprite nhân vật Mario 8-bit cổ điển
  Widget _buildPixelMarioSprite() {
    return Column(
      children: [
        // Mũ đỏ
        Container(
          width: 22,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE52521),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
        ),
        // Mặt + Râu
        Container(
          width: 20,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFFBD0A4),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(width: 3, height: 4, color: Colors.black), // Mắt
              const SizedBox(width: 2),
              Container(
                width: 6,
                height: 3,
                color: const Color(0xFF882000),
              ), // Râu
            ],
          ),
        ),
        // Áo yếm xanh đỏ
        Container(
          width: 24,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF0068DE),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              color: const Color(0xFFE52521),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetroCardSlot(String symbol) {
    return Container(
      width: 26,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(child: Text(symbol, style: const TextStyle(fontSize: 16))),
    );
  }

  // ================= 5. NÚT ĐIỀU KHIỂN PIXEL PHONG CÁCH ASSET MẪU CỦA NGƯỜI DÙNG =================
  Widget _buildPixelButtonsController() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 2 NÚT DI CHUYỂN TRÁI / PHẢI DẠNG MŨI TÊN PIXEL (Chuẩn hình ảnh mũi tên pixel người dùng gửi)
        Row(
          children: [
            // Nút TRÁI Pixel
            _buildPixelArrowKey(
              direction: _ArrowDir.left,
              onPressedDown: () => setState(() => _isMovingLeft = true),
              onPressedUp: () => setState(() => _isMovingLeft = false),
            ),
            const SizedBox(width: 14),
            // Nút PHẢI Pixel
            _buildPixelArrowKey(
              direction: _ArrowDir.right,
              onPressedDown: () => setState(() => _isMovingRight = true),
              onPressedUp: () => setState(() => _isMovingRight = false),
            ),
          ],
        ),

        // NÚT PLAY / NHẢY THEO PHONG CÁCH NÚT HÌNH CHỮ NHẬT 8-BIT "PLAY" MÀU XANH LÁ HOẶC ĐỎ (Chuẩn ảnh mẫu người dùng gửi)
        _buildPixelActionJumpButton(),
      ],
    );
  }

  // Nút mũi tên pixel (Giống hàng mũi tên trắng viền đen ở ảnh mẫu người dùng gửi)
  Widget _buildPixelArrowKey({
    required _ArrowDir direction,
    required VoidCallback onPressedDown,
    required VoidCallback onPressedUp,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPressedDown(),
      onTapUp: (_) => onPressedUp(),
      onTapCancel: () => onPressedUp(),
      child: Container(
        width: 68,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFDCDCDC),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black, width: 3.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 4)),
          ],
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(32, 28),
            painter: _PixelArrowPainter(direction: direction),
          ),
        ),
      ),
    );
  }

  // Nút NHẢY phong cách nút 8-bit "START/PLAY" (Viền đen, có vệt trắng highlight ngang chuẩn ảnh mẫu)
  Widget _buildPixelActionJumpButton() {
    return GestureDetector(
      onTapDown: (_) => _jump(),
      child: Container(
        width: 125,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFE52521), // Đỏ retro Mario
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 3.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // Highlight bar màu trắng sữa ngang nút (giống hệt nút START / PLAY trong ảnh mẫu)
            Container(
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'JUMP',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hộp thoại toán học đụng quái
  Widget _buildMathQuestionBox() {
    final monster = _currentActiveMonster!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(monster['emoji'], style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  monster['question'],
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE52521),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: (monster['options'] as List<int>).map((opt) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0068DE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                onPressed: () => _handleAnswer(opt),
                child: Text(
                  '$opt',
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryBox() {
    return Column(
      children: [
        const Text(
          '★ CONGRATULATIONS! ★',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFFFBD000),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'BẠN ĐÃ GIẢI CỨU CÔNG CHÚA AN TOÀN!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Courier',
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A800),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.white, width: 2),
            ),
          ),
          onPressed: () {
            widget.onGameOver();
            Navigator.pop(context);
          },
          child: const Text(
            'NHẬN 200 XP & VỀ ĐẤU TRƯỜNG',
            style: TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverBox() {
    return Column(
      children: [
        const Text(
          'GAME OVER',
          style: TextStyle(
            fontFamily: 'Courier',
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
          onPressed: () {
            widget.onGameOver();
            Navigator.pop(context);
          },
          child: const Text(
            'TRY AGAIN',
            style: TextStyle(
              fontFamily: 'Courier',
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

enum _ArrowDir { left, right }

// Painter vẽ mũi tên Pixel chuẩn retro 8-bit theo đúng hình ảnh tham khảo
class _PixelArrowPainter extends CustomPainter {
  final _ArrowDir direction;
  _PixelArrowPainter({required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()..color = Colors.white;
    final paintShadow = Paint()..color = const Color(0xFF94A3B8);
    final paintBorder = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    if (direction == _ArrowDir.left) {
      // Mũi tên chỉ sang trái
      path.moveTo(0, size.height * 0.5);
      path.lineTo(size.width * 0.45, 0);
      path.lineTo(size.width * 0.45, size.height * 0.25);
      path.lineTo(size.width, size.height * 0.25);
      path.lineTo(size.width, size.height * 0.75);
      path.lineTo(size.width * 0.45, size.height * 0.75);
      path.lineTo(size.width * 0.45, size.height);
      path.close();
    } else {
      // Mũi tên chỉ sang phải
      path.moveTo(size.width, size.height * 0.5);
      path.lineTo(size.width * 0.55, 0);
      path.lineTo(size.width * 0.55, size.height * 0.25);
      path.lineTo(0, size.height * 0.25);
      path.lineTo(0, size.height * 0.75);
      path.lineTo(size.width * 0.55, size.height * 0.75);
      path.lineTo(size.width * 0.55, size.height);
      path.close();
    }

    // Vẽ bóng, thân và viền đen
    canvas.drawPath(path, paintShadow);
    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter vẽ khối hộp xanh X (Blue Blocks) kiểu Super Mario Bros 3
class _BlueBlockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF88D8F8)
      ..strokeWidth = 2.0;

    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, size.height),
      paintLine,
    );
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
