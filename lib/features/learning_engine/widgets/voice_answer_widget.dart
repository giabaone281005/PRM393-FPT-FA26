import 'package:flutter/material.dart';

import '../../../../core/services/voice/speech_answer_normalizer.dart';
import '../../../../core/services/voice/speech_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../data/models/question.dart';

class VoiceAnswerWidget extends StatefulWidget {
  final Question question;
  final SpeechService? speechService;
  final ValueChanged<dynamic> onAnswerConfirmed;
  final bool isBusy;

  const VoiceAnswerWidget({
    super.key,
    required this.question,
    this.speechService,
    required this.onAnswerConfirmed,
    this.isBusy = false,
  });

  @override
  State<VoiceAnswerWidget> createState() => _VoiceAnswerWidgetState();
}

class _VoiceAnswerWidgetState extends State<VoiceAnswerWidget>
    with SingleTickerProviderStateMixin {
  late final SpeechService _speech;
  late final bool _isExternalService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  dynamic _resolvedAnswer;
  String _recognizedTranscript = '';

  @override
  void initState() {
    super.initState();
    _isExternalService = widget.speechService != null;
    _speech = widget.speechService ?? FlutterSpeechService();
    _speech.addListener(_onSpeechStateChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant VoiceAnswerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi câu hỏi thay đổi hoặc màn hình bận, reset phiên nghe cũ ngay lập tức
    if (oldWidget.question.id != widget.question.id) {
      _stopAndReset();
    }
  }

  void _onSpeechStateChanged() {
    if (!mounted) return;
    if (_speech.isListening) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    if (_speech.state == VoiceState.recognized ||
        _speech.recognizedWords.isNotEmpty) {
      _processSpokenWords(_speech.recognizedWords);
    }

    setState(() {});
  }

  void _processSpokenWords(String rawWords) {
    _recognizedTranscript = rawWords.trim();
    if (_recognizedTranscript.isEmpty) {
      _resolvedAnswer = null;
      return;
    }

    List<dynamic>? options;
    if (widget.question.data['options'] is List) {
      options = List<dynamic>.from(widget.question.data['options'] as List);
    }

    final resolved = SpeechAnswerNormalizer.resolveSpokenAnswer(
      speech: _recognizedTranscript,
      options: options,
      expectsInteger: widget.question.type == QuestionType.dragCounters,
    );

    _resolvedAnswer = resolved;
  }

  Future<void> _startListening() async {
    if (widget.isBusy) return;
    setState(() {
      _resolvedAnswer = null;
      _recognizedTranscript = '';
    });

    await _speech.startListening(
      onResult: (words) {
        if (!mounted) return;
        _processSpokenWords(words);
        setState(() {});
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stopListening();
  }

  void _stopAndReset() {
    _speech.cancelListening();
    _speech.reset();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _resolvedAnswer = null;
      _recognizedTranscript = '';
    });
  }

  void _confirmAnswer() {
    if (_resolvedAnswer == null || widget.isBusy) return;
    widget.onAnswerConfirmed(_resolvedAnswer);
    _stopAndReset();
  }

  @override
  void dispose() {
    _speech.removeListener(_onSpeechStateChanged);
    _pulseController.dispose();
    if (!_isExternalService) {
      _speech.dispose();
    } else {
      _speech.cancelListening();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColorForState(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColorForState(), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMainStatusRow(),
          if (_speech.recognizedWords.isNotEmpty ||
              _speech.state == VoiceState.recognized) ...[
            const SizedBox(height: 12),
            _buildRecognizedFeedbackCard(),
          ],
          if (_speech.state == VoiceState.error &&
              _speech.lastError != null) ...[
            const SizedBox(height: 12),
            _buildErrorFeedbackCard(),
          ],
        ],
      ),
    );
  }

  Color _backgroundColorForState() {
    switch (_speech.state) {
      case VoiceState.listening:
        return AppColors.accentGoldLight.withValues(alpha: 0.4);
      case VoiceState.recognized:
        return AppColors.accentGreenLight.withValues(alpha: 0.3);
      case VoiceState.error:
        return AppColors.accentRedLight.withValues(alpha: 0.3);
      case VoiceState.unsupported:
        return AppColors.surfaceSubtle;
      default:
        return Colors.white;
    }
  }

  Color _borderColorForState() {
    switch (_speech.state) {
      case VoiceState.listening:
        return AppColors.accentGold;
      case VoiceState.recognized:
        return AppColors.accentGreen;
      case VoiceState.error:
        return AppColors.accentRed;
      default:
        return AppColors.borderSubtle;
    }
  }

  Widget _buildMainStatusRow() {
    final isListening = _speech.isListening;
    final isRequesting = _speech.state == VoiceState.requestingPermission;
    final isUnsupported = _speech.state == VoiceState.unsupported;

    return Row(
      children: [
        // Nút Micro lớn thân thiện
        ScaleTransition(
          scale: isListening
              ? _pulseAnimation
              : const AlwaysStoppedAnimation(1.0),
          child: Material(
            color: isListening
                ? AppColors.accentRed
                : (isUnsupported ? Colors.grey : AppColors.primary),
            shape: const CircleBorder(),
            elevation: isListening ? 6 : 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.isBusy
                  ? null
                  : (isListening
                        ? _stopListening
                        : (isUnsupported ? null : _startListening)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: isRequesting
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(
                        isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Nhãn & hướng dẫn thân thiện cho bé
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleForState(),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isListening
                      ? AppColors.primaryHover
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _subtitleForState(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Nút dừng nghe hoặc nói lại nhanh
        if (isListening)
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accentRedLight,
              foregroundColor: AppColors.accentRed,
            ),
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: 'Dừng nghe',
            onPressed: _stopListening,
          )
        else if (_recognizedTranscript.isNotEmpty ||
            _speech.state == VoiceState.recognized ||
            _speech.state == VoiceState.error)
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.textSecondary,
            tooltip: 'Nói lại từ đầu',
            onPressed: widget.isBusy ? null : _startListening,
          ),
      ],
    );
  }

  String _titleForState() {
    switch (_speech.state) {
      case VoiceState.listening:
        return 'Cú đang nghe bé nói nè...';
      case VoiceState.requestingPermission:
        return 'Đang mở micro...';
      case VoiceState.processing:
        return 'Cú đang lắng nghe...';
      case VoiceState.recognized:
        return 'Cú đã nghe được rồi!';
      case VoiceState.error:
        return 'Chưa nghe rõ câu trả lời';
      case VoiceState.unsupported:
        return 'Nhận diện giọng nói chưa sẵn sàng';
      default:
        return 'Trả lời bằng giọng nói';
    }
  }

  String _subtitleForState() {
    switch (_speech.state) {
      case VoiceState.listening:
        return 'Bé hãy nói to đáp án vào micro nhé!';
      case VoiceState.requestingPermission:
        return 'Xin quyền micro để nghe bé nói.';
      case VoiceState.processing:
        return 'Đang chuyển lời nói thành câu trả lời...';
      case VoiceState.recognized:
        return 'Bé kiểm tra và bấm nút gửi bên dưới nhé.';
      case VoiceState.error:
        return 'Bé kiểm tra thông báo bên dưới để thử lại nhé.';
      case VoiceState.unsupported:
        return 'Bé hãy bấm chọn đáp án bằng tay ở bên dưới nhé.';
      default:
        return 'Bấm micro và nói đáp án của bé nhé!';
    }
  }

  Widget _buildRecognizedFeedbackCard() {
    final hasCandidate = _resolvedAnswer != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCandidate ? AppColors.accentGreen : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🦉', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Cú nghe được: "$_recognizedTranscript"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (hasCandidate) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentGreenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.accentGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Đáp án: $_resolvedAnswer',
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasCandidate)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.isBusy ? null : _confirmAnswer,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'XÁC NHẬN GỬI',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.isBusy ? null : _startListening,
                    icon: const Icon(Icons.mic, size: 18),
                    label: const Text('BÉ NÓI LẠI NHÉ'),
                  ),
                ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: widget.isBusy ? null : _stopAndReset,
                child: const Text('Đổi cách khác'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentRedLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.accentRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _speech.lastError?.message ?? 'Có lỗi xảy ra khi nghe.',
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: widget.isBusy ? null : _startListening,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
