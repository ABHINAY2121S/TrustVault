import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/api.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with TickerProviderStateMixin {
  File? _file;
  String? _fileName;
  final _titleCtrl = TextEditingController();
  String _category = 'Other';
  DateTime? _expiry;
  bool _uploading = false;
  int _scanStep = -1;
  String? _result;
  late AnimationController _pulseCtrl;

  static const _steps = [
    ('upload', 'Uploading document...'),
    ('scan', 'Running OCR scan...'),
    ('verify', 'Verifying identity...'),
    ('save', 'Saving to vault...'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) setState(() { _file = File(img.path); _fileName = img.name; if (_titleCtrl.text.isEmpty) _titleCtrl.text = img.name.replaceAll(RegExp(r'\.[^.]+$'), '').replaceAll(RegExp(r'[-_]'), ' '); });
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (res != null && res.files.single.path != null) {
      setState(() { _file = File(res.files.single.path!); _fileName = res.files.single.name; if (_titleCtrl.text.isEmpty) _titleCtrl.text = res.files.single.name.replaceAll(RegExp(r'\.[^.]+$'), '').replaceAll(RegExp(r'[-_]'), ' '); });
    }
  }

  Future<void> _upload() async {
    if (_file == null || _titleCtrl.text.trim().isEmpty) return;
    setState(() { _uploading = true; _scanStep = 0; });

    // Animate steps
    for (int i = 1; i <= _steps.length - 2; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _scanStep = i);
    }

    try {
      final token = await ApiService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/documents'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = _titleCtrl.text.trim();
      request.fields['category'] = _category;
      if (_expiry != null) request.fields['expiryDate'] = _expiry!.toIso8601String();
      request.files.add(await http.MultipartFile.fromPath('file', _file!.path));
      final response = await request.send();
      final body = jsonDecode(await response.stream.bytesToString());
      if (mounted) setState(() { _scanStep = _steps.length - 1; _result = body['verificationStatus'] ?? 'unverified'; });
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _uploading = false; _scanStep = -1; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF7c3aed))), child: child!),
    );
    if (d != null) setState(() => _expiry = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080818),
        title: const Text('Upload Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _uploading ? _buildScanProgress() : _buildForm(),
      ),
    );
  }

  Widget _buildScanProgress() {
    return Column(
      children: [
        const SizedBox(height: 30),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFF6d28d9)]),
              boxShadow: [BoxShadow(color: const Color(0xFF7c3aed).withOpacity(0.3 + 0.2 * _pulseCtrl.value), blurRadius: 20 + 10 * _pulseCtrl.value, spreadRadius: 2)],
            ),
            child: const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 24),
        const Text('AI is scanning your document', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Extracting text and verifying identity...', style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
        const SizedBox(height: 36),
        ..._steps.asMap().entries.map((e) {
          final i = e.key;
          final step = e.value;
          final isDone = i < _scanStep;
          final isCurrent = i == _scanStep;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF059669).withOpacity(0.08) : isCurrent ? const Color(0xFF7c3aed).withOpacity(0.08) : const Color(0xFF0f0f1f),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDone ? const Color(0xFF059669).withOpacity(0.2) : isCurrent ? const Color(0xFF7c3aed).withOpacity(0.2) : const Color(0xFF1e293b)),
            ),
            child: Row(children: [
              Icon(isDone ? Icons.check_circle : isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isDone ? const Color(0xFF059669) : isCurrent ? const Color(0xFF7c3aed) : const Color(0xFF334155), size: 20),
              const SizedBox(width: 12),
              Text(step.$2, style: TextStyle(color: isDone ? const Color(0xFF10b981) : isCurrent ? const Color(0xFFa78bfa) : const Color(0xFF475569), fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal)),
            ]),
          );
        }),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File picker area
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF0f0f1f),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _file != null ? const Color(0xFF7c3aed).withOpacity(0.5) : const Color(0xFF1e293b), style: BorderStyle.solid, width: _file != null ? 1.5 : 1),
            ),
            child: _file != null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 36),
                    const SizedBox(height: 8),
                    Text(_fileName ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    const Text('Tap to change', style: TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                  ]))
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cloud_upload_outlined, color: Color(0xFF475569), size: 36),
                    const SizedBox(height: 8),
                    const Text('Tap to select image', style: TextStyle(color: Color(0xFF94a3b8))),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      TextButton(onPressed: _pickImage, child: const Text('Gallery', style: TextStyle(color: Color(0xFF7c3aed), fontSize: 13))),
                      const Text('·', style: TextStyle(color: Color(0xFF475569))),
                      TextButton(onPressed: _pickFile, child: const Text('Files (PDF)', style: TextStyle(color: Color(0xFF7c3aed), fontSize: 13))),
                    ]),
                  ]),
          ),
        ),
        const SizedBox(height: 20),
        _label('Document Title'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('e.g. Aadhaar Card'),
        ),
        const SizedBox(height: 16),
        _label('Category'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF1a1a2e), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1e293b))),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              dropdownColor: const Color(0xFF1a1a2e),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              items: ['Education', 'Medical', 'Government', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Other'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _label('Expiry Date (Optional)'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1a1a2e), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1e293b))),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, color: Color(0xFF475569), size: 18),
              const SizedBox(width: 12),
              Text(_expiry == null ? 'Select expiry date' : '${_expiry!.day}/${_expiry!.month}/${_expiry!.year}',
                style: TextStyle(color: _expiry == null ? const Color(0xFF475569) : Colors.white)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFf59e0b).withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.2))),
          child: const Row(children: [
            Icon(Icons.document_scanner_outlined, color: Color(0xFFf59e0b), size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('AI will scan this document and extract text to verify your identity. Name matches = Partially Verified.', style: TextStyle(color: Color(0xFFf59e0b), fontSize: 12))),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _file == null || _titleCtrl.text.isEmpty ? null : _upload,
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Scan & Upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7c3aed), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: const Color(0xFF1e293b), disabledForegroundColor: const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13, fontWeight: FontWeight.w500));

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Color(0xFF475569)),
    filled: true, fillColor: const Color(0xFF1a1a2e),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1e293b))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1e293b))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7c3aed))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
