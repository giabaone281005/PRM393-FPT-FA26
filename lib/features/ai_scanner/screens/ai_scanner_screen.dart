import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/ai_tutor_repository.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/study_repository.dart';

class AiScannerScreen extends StatefulWidget {
  const AiScannerScreen({super.key});
  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> {
  final _problem = TextEditingController();
  Uint8List? _image;
  String _mime = 'image/jpeg';
  List<String> _hints = [];
  int _step = 0;
  bool _busy = false;
  bool? _enabled;
  String? _error, _notice;
  String? _request, _phase;
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final enabled = await AiTutorRepository.isEnabled();
      if (mounted) {
        setState(() {
          _enabled = enabled;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa kiểm tra được trạng thái AI. Vui lòng thử lại.',
        );
      }
    }
  }

  @override
  void dispose() {
    _problem.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 3 * 1024 * 1024) {
        throw StateError('Ảnh cần dưới 3 MB.');
      }
      if (!mounted) return;
      setState(() {
        _image = bytes;
        _mime = bytes.length > 3 && bytes[0] == 137
            ? 'image/png'
            : 'image/jpeg';
        _request = null;
        _hints = [];
        _notice = null;
      });
      await _send('ocr');
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không mở được ảnh. Cho phép truy cập camera/thư viện hoặc nhập đề bằng tay.',
        );
      }
    }
  }

  Future<void> _send(String phase) async {
    if (_busy || _enabled != true) return;
    final state = context.read<AppStateProvider>();
    if (!state.hasKids) return;
    if (phase == 'hint' && _problem.text.trim().length < 5) {
      setState(() => _error = 'Hãy nhập hoặc sửa lại đề toán trước.');
      return;
    }
    if (_phase != phase) {
      _request = null;
      _phase = phase;
    }
    _request ??= StudyRepository.requestId();
    final kidId = state.currentKid.id;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await AiTutorRepository.request(
        kidId: kidId,
        requestId: _request!,
        phase: phase,
        image: _image,
        mime: _mime,
        problem: _problem.text,
      );
      if (!mounted) return;
      if (!state.hasKids || state.currentKid.id != kidId) {
        setState(() {
          _hints = [];
          _notice = null;
          _request = null;
        });
        return;
      }
      setState(() {
        _request = null;
        if (phase == 'ocr') {
          _problem.text = data['problem'] ?? '';
          _notice = 'Kiểm tra và sửa đề trước khi nhận gợi ý.';
        } else {
          _hints = List<String>.from(data['hints'] ?? []);
          _step = 1;
          _notice = data['notice'];
        }
      });
    } on FunctionException catch (e) {
      if (mounted) {
        setState(
          () => _error =
              (e.status == 404
                  ? 'Dịch vụ AI chưa được triển khai. Em có thể tiếp tục học bài có sẵn.'
                  : (e.details is Map ? e.details['error'] : null)
                        ?.toString()) ??
              'AI tạm thời chưa sẵn sàng.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Mất kết nối. Ảnh được giữ trên màn hình để thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cùng suy nghĩ với Cú AI')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_enabled == null && _error == null) const LinearProgressIndicator(),
        if (_enabled == false)
          const Text(
            'AI chưa được bật. Em vẫn có thể học các bài trong bản đồ.',
          ),
        if (_enabled != true)
          TextButton(
            onPressed: _loadSettings,
            child: const Text('Kiểm tra lại trạng thái AI'),
          ),
        const Text(
          'Ảnh sẽ được gửi tới dịch vụ AI để đọc đề, không lưu vào kho ảnh của ứng dụng. Chỉ chụp đề toán, tránh thông tin cá nhân.',
        ),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: _busy || _enabled != true
                  ? null
                  : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Chụp đề'),
            ),
            OutlinedButton.icon(
              onPressed: _busy || _enabled != true
                  ? null
                  : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Chọn ảnh'),
            ),
          ],
        ),
        if (_image != null)
          Image.memory(_image!, height: 180, fit: BoxFit.contain),
        TextField(
          controller: _problem,
          maxLines: 5,
          maxLength: 3000,
          decoration: const InputDecoration(
            labelText: 'Đề toán (kiểm tra hoặc nhập bằng tay)',
          ),
          onChanged: (_) {
            _request = null;
            _hints = [];
          },
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) Text(_error!),
        if (_notice?.isNotEmpty == true) Text(_notice!),
        if (_image != null)
          TextButton(
            onPressed: _busy || _enabled != true ? null : () => _send('ocr'),
            child: const Text('Đọc lại ảnh'),
          ),
        FilledButton(
          onPressed: _busy || _enabled != true ? null : () => _send('hint'),
          child: const Text('Gợi ý cách suy nghĩ'),
        ),
        for (var i = 0; i < _hints.length && i < _step; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Bước ${i + 1}: ${_hints[i]}'),
            ),
          ),
        if (_step < _hints.length)
          TextButton(
            onPressed: () => setState(() => _step++),
            child: const Text('Xem gợi ý tiếp theo'),
          ),
        const Text(
          'Gợi ý AI có thể sai. Em hãy đối chiếu dữ kiện, tự kiểm tra phép tính và hỏi phụ huynh hoặc giáo viên khi chưa chắc chắn.',
        ),
      ],
    ),
  );
}
