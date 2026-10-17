import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ClockRotationWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool isCorrect) onAnswerSubmitted;
  final ValueChanged<dynamic>? onAnswerValue;

  const ClockRotationWidget({
    super.key,
    required this.data,
    required this.onAnswerSubmitted,
    this.onAnswerValue,
  });

  @override
  State<ClockRotationWidget> createState() => _ClockRotationWidgetState();
}

class _ClockRotationWidgetState extends State<ClockRotationWidget> {
  int _currentMinute = 0; // 0, 5, 10, ... 55
  late int _targetHour;
  late int _targetMinute;

  @override
  void initState() {
    super.initState();
    _targetHour = widget.data['targetHour'] ?? 3;
    _targetMinute = widget.data['targetMinute'] ?? 30;
  }

  @override
  Widget build(BuildContext context) {
    final minuteAngle = (_currentMinute / 60.0) * 2 * pi;
    final hourAngle =
        ((_targetHour % 12) / 12.0) * 2 * pi + (minuteAngle / 12.0);

    return Column(
      children: [
        // Mặt đồng hồ cơ học tương tác
        GestureDetector(
          onPanUpdate: (details) {
            // Tính góc xoay dựa trên tâm đồng hồ
            final offset = details.localPosition - const Offset(100, 100);
            var angle = atan2(offset.dy, offset.dx) + pi / 2;
            if (angle < 0) angle += 2 * pi;
            final minute = ((angle / (2 * pi)) * 60).round();
            final roundedMinute = ((minute / 5).round() * 5) % 60;
            setState(() {
              _currentMinute = roundedMinute;
            });
          },
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.primary, width: 6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(50),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Các số trên mặt đồng hồ
                ...List.generate(12, (index) {
                  final num = index == 0 ? 12 : index;
                  final angle = (index / 12.0) * 2 * pi - pi / 2;
                  final x = 70 * cos(angle);
                  final y = 70 * sin(angle);
                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Text(
                      '$num',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }),

                // Kim giờ (ngắn, màu cam đậm)
                Transform.rotate(
                  angle: hourAngle,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 55),
                      width: 6,
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppColors.primaryHover,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Kim phút (dài, màu xanh)
                Transform.rotate(
                  angle: minuteAngle,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 35),
                      width: 4,
                      height: 65,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Tâm đồng hồ
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Hiển thị giờ hiện tại
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_targetHour : ${_currentMinute.toString().padLeft(2, '0')}',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.primaryHover,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Nút điều chỉnh bước nhảy +5 phút / -5 phút
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceSubtle,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _currentMinute = (_currentMinute - 5 + 60) % 60;
                });
              },
              icon: const Icon(Icons.remove, size: 16),
              label: const Text('- 5 phút'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceSubtle,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _currentMinute = (_currentMinute + 5) % 60;
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ 5 phút'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            if (widget.onAnswerValue != null) {
              widget.onAnswerValue!({
                'hour': _targetHour,
                'minute': _currentMinute,
              });
            } else {
              widget.onAnswerSubmitted(_currentMinute == _targetMinute);
            }
          },
          child: const Text(
            'KIỂM TRA ĐỒNG HỒ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
