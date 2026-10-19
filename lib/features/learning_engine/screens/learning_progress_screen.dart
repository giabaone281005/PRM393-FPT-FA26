import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/streak_calculator.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/learning_statistics.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/learning_statistics_repository.dart';
import '../../../data/repositories/wrong_answer_repository.dart';
import '../../practice_garden/screens/practice_garden_screen.dart';
import 'review_wrong_answers_screen.dart';

/// Screen displaying the learner's overall learning progress, accuracy statistics,
/// answer breakdown, and current daily streak.
class LearningProgressScreen extends StatefulWidget {
  final String? kidId;
  final LearningStatistics? statistics;
  final int? streakCount;

  const LearningProgressScreen({
    super.key,
    this.kidId,
    this.statistics,
    this.streakCount,
  });

  @override
  State<LearningProgressScreen> createState() => _LearningProgressScreenState();
}

class _LearningProgressScreenState extends State<LearningProgressScreen> {
  bool _loading = true;
  String? _error;
  LearningStatistics _statistics = const LearningStatistics.empty();
  int _streakCount = 0;
  int? _lastStatsRevision;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final appState = Provider.of<AppStateProvider>(context);
      if (_lastStatsRevision != null &&
          _lastStatsRevision != appState.statsRevision) {
        _lastStatsRevision = appState.statsRevision;
        _loadData();
      } else {
        _lastStatsRevision = appState.statsRevision;
      }
    } catch (_) {}
  }

  String _resolveKidId() {
    if (widget.kidId != null && widget.kidId!.trim().isNotEmpty) {
      return widget.kidId!.trim();
    }
    try {
      final state = context.read<AppStateProvider>();
      if (state.hasKids) {
        return state.currentKid.id;
      }
    } catch (_) {
      // Handled if provider is not in widget hierarchy
    }
    return '';
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.statistics != null) {
        setState(() {
          _statistics = widget.statistics!;
          _streakCount = widget.streakCount ?? 0;
          _loading = false;
        });
        return;
      }

      final kidId = _resolveKidId();
      AppStateProvider? appState;
      try {
        appState = context.read<AppStateProvider>();
      } catch (_) {}

      final stats = await LearningStatisticsRepository.getStatistics(
        kidId: kidId,
      );

      int streak = widget.streakCount ?? 0;
      if (widget.streakCount == null) {
        final streakRecord = await LearningStatisticsRepository.getStreak(
          kidId: kidId,
        );
        if (SupabaseService.isLoggedIn || streakRecord.currentStreak > 0) {
          streak = streakRecord.currentStreak;
        } else if (appState != null &&
            appState.hasKids &&
            (kidId.isEmpty || appState.currentKid.id == kidId)) {
          streak = appState.currentKid.streakCount;
        }

        if (!SupabaseService.isLoggedIn && streak == 0 && kidId.isNotEmpty) {
          final wrongAnswers = await WrongAnswerRepository.getWrongAnswers(
            kidId,
          );
          if (wrongAnswers.isNotEmpty) {
            final calculated = StreakCalculator.fromWrongAnswerRecords(
              wrongAnswers,
            );
            streak = calculated.currentStreak;
          }
        }
      }

      if (mounted) {
        setState(() {
          _statistics = stats;
          _streakCount = streak;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải dữ liệu tiến độ. Vui lòng thử lại.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tiến độ học tập'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Đang tải dữ liệu tiến độ...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.accentRed,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStreakBanner(),
              const SizedBox(height: 20),
              _buildMetricsGrid(constraints),
              const SizedBox(height: 20),
              if (_statistics.totalAnswered == 0)
                _buildEmptyState()
              else ...[
                _buildAccuracyBar(),
                const SizedBox(height: 20),
                _buildDailyProgressChart(),
              ],
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.accentGoldLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withAlpha(120)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.streakFire,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$_streakCount',
                      style: AppTypography.displayMedium.copyWith(
                        color: const Color(0xFFB45309),
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ngày liên tiếp',
                      style: AppTypography.titleMedium.copyWith(
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _streakCount > 0
                      ? 'Bé đang duy trì thói quen học tập rất tốt!'
                      : 'Làm bài hôm nay để bắt đầu chuỗi ngày học tập!',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BoxConstraints constraints) {
    final isWide = constraints.maxWidth > 550;

    final cards = [
      _buildMetricCard(
        icon: Icons.quiz_outlined,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryLight,
        label: 'Tổng số câu',
        value: '${_statistics.totalAnswered}',
      ),
      _buildMetricCard(
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.accentGreen,
        iconBgColor: AppColors.accentGreenLight,
        label: 'Đã trả lời đúng',
        value: '${_statistics.correctAnswers}',
      ),
      _buildMetricCard(
        icon: Icons.highlight_off_rounded,
        iconColor: AppColors.accentRed,
        iconBgColor: AppColors.accentRedLight,
        label: 'Trả lời sai',
        value: '${_statistics.incorrectAnswers}',
      ),
      _buildMetricCard(
        icon: Icons.pie_chart_outline_rounded,
        iconColor: AppColors.accentPurple,
        iconBgColor: AppColors.accentPurpleLight,
        label: 'Độ chính xác',
        value: _formatAccuracy(_statistics.accuracyPercentage),
      ),
    ];

    if (isWide) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: c,
        ))).toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyBar() {
    final accuracy = _statistics.accuracyPercentage;
    final total = _statistics.totalAnswered;
    final correctRatio = total > 0 ? (_statistics.correctAnswers / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ lệ chính xác',
                style: AppTypography.titleMedium.copyWith(fontSize: 16),
              ),
              Text(
                _formatAccuracy(accuracy),
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 16,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: correctRatio.clamp(0.0, 1.0),
                backgroundColor: AppColors.accentRed.withAlpha(50),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accentGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đúng: ${_statistics.correctAnswers}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Sai: ${_statistics.incorrectAnswers}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgressChart() {
    final correct = _statistics.correctAnswers.toDouble();
    final incorrect = _statistics.incorrectAnswers.toDouble();
    final maxY = (correct > incorrect ? correct : incorrect);
    final effectiveMaxY = maxY > 0 ? maxY * 1.25 : 5.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biểu đồ phân phối kết quả',
            style: AppTypography.titleMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'So sánh số câu trả lời đúng và sai đã hoàn thành',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: effectiveMaxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final label = val.toInt() == 0 ? 'Đúng' : 'Sai';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: correct,
                        color: AppColors.accentGreen,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: incorrect,
                        color: AppColors.accentRed,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu học tập',
            style: AppTypography.titleMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy hoàn thành các câu hỏi luyện tập để theo dõi độ chính xác và chuỗi rèn luyện của bé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.sports_esports_rounded),
          label: const Text(
            'Vào vườn luyện tập',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PracticeGardenScreen(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.history_edu_rounded),
          label: const Text('Xem lại câu trả lời sai'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewWrongAnswersScreen(kidId: widget.kidId),
            ),
          ),
        ),
      ],
    );
  }

  String _formatAccuracy(double accuracy) {
    if (accuracy.isNaN || accuracy.isInfinite) return '0%';
    if (accuracy == accuracy.roundToDouble()) {
      return '${accuracy.toInt()}%';
    }
    return '${accuracy.toStringAsFixed(1)}%';
  }
}
