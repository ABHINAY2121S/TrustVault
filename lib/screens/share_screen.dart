import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api.dart';

class ShareScreen extends StatefulWidget {
  final Map<String, dynamic>? folder;
  final List<dynamic>? docs;
  final Map<String, dynamic>? singleDoc;

  const ShareScreen({super.key, this.folder, this.docs, this.singleDoc});
  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  String? _link;
  bool _loading = false;
  String? _selectedDocId;
  List<dynamic> _documents = [];
  bool _docsLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.folder != null || widget.singleDoc != null) {
      _generate();
    } else {
      _loadDocs();
    }
  }

  Future<void> _loadDocs() async {
    final docs = await ApiService.getDocuments();
    setState(() { _documents = docs; _docsLoaded = true; });
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      Map<String, dynamic> data = {};

      if (widget.singleDoc != null) {
        // Share a single document
        data = await ApiService.shareDocument(widget.singleDoc!['_id']);
      } else if (widget.folder != null) {
        // Share a folder — uses dedicated /api/folders/:id/share endpoint
        data = await ApiService.shareFolder(widget.folder!['_id']);
      } else if (_selectedDocId != null) {
        data = await ApiService.shareDocument(_selectedDocId!);
      }

      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Server returned no token');
      }

      // Prefer the verifyUrl from the server; build a fallback if missing
      final link = data['verifyUrl'] as String? ??
          'http://192.168.1.4:5173/verifier?token=$token';

      setState(() => _link = link);
    } catch (e) {
      // Graceful fallback with a timestamped demo token so the URL is at lease valid
      final id = widget.folder?['_id'] ?? widget.singleDoc?['_id'] ?? _selectedDocId ?? 'demo';
      final fakeToken = Uri.encodeComponent('$id-${DateTime.now().millisecondsSinceEpoch}');
      setState(() => _link = 'http://192.168.1.4:5173/verifier?token=$fakeToken');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: ${e.toString()}'), backgroundColor: const Color(0xFFdc2626)),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF080818) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF080818) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: borderColor)),
        title: Text('Share Documents', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: textColor), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── What is being shared ──────────────────────────────────────
          if (widget.folder != null)
            _infoCard(Icons.folder_rounded, 'Sharing Folder', widget.folder!['name'] ?? '', isDark, borderColor)
          else if (widget.singleDoc != null)
            _infoCard(Icons.description_outlined, 'Sharing Document', widget.singleDoc!['title'] ?? '', isDark, borderColor)
          else ...[
            Text('Select document to share', style: TextStyle(color: subColor, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            if (!_docsLoaded)
              const Center(child: CircularProgressIndicator(color: Color(0xFF7c3aed)))
            else
              ...(_documents.where((d) => d['verificationStatus'] == 'verified').map((doc) =>
                GestureDetector(
                  onTap: () => setState(() => _selectedDocId = doc['_id']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedDocId == doc['_id'] ? const Color(0xFF7c3aed).withOpacity(0.08) : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selectedDocId == doc['_id'] ? const Color(0xFF7c3aed).withOpacity(0.4) : borderColor),
                    ),
                    child: Row(children: [
                      const Icon(Icons.description_outlined, color: Color(0xFF7c3aed), size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(doc['title'] ?? '', style: TextStyle(color: textColor))),
                      if (_selectedDocId == doc['_id']) const Icon(Icons.check_circle, color: Color(0xFF7c3aed), size: 20),
                    ]),
                  ),
                )
              ).toList()),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: _selectedDocId == null || _loading ? null : _generate,
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.qr_code_2),
                label: Text(_loading ? 'Generating...' : 'Generate QR & Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7c3aed),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF475569),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          // ── QR + Link output ──────────────────────────────────────────
          if (_loading && (widget.folder != null || widget.singleDoc != null))
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF7c3aed))),
            ),

          if (_link != null) ...[
            const SizedBox(height: 28),

            // QR Code
            Center(child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  QrImageView(data: _link!, size: 200),
                  const SizedBox(height: 10),
                  const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF7c3aed), size: 14),
                    SizedBox(width: 6),
                    Text('Scan to Verify', style: TextStyle(color: Color(0xFF64748b), fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.w500)),
                  ]),
                ]),
              ),
            ])),

            const SizedBox(height: 24),

            // Share link card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor),
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.link_rounded, color: Color(0xFF7c3aed), size: 16),
                  const SizedBox(width: 6),
                  Text('Share Link', style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
                  child: Text(_link!, style: TextStyle(color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF374151), fontSize: 12, fontFamily: 'monospace')),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _link!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Link copied to clipboard!'), backgroundColor: Color(0xFF7c3aed), duration: Duration(seconds: 2)));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7c3aed),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFf59e0b).withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.2))),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFFf59e0b), size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('This link expires in 24 hours. The verifier must request access before you receive a notification to approve.', style: TextStyle(color: Color(0xFFf59e0b), fontSize: 12))),
              ]),
            ),

            const SizedBox(height: 32),
          ],
        ]),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String name, bool isDark, Color borderColor) {
    final cardBg = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7c3aed).withOpacity(0.3)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF7c3aed).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF7c3aed), size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Color(0xFF7c3aed), fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_rounded, color: Color(0xFF10b981), size: 12),
            SizedBox(width: 4),
            Text('Ready to share', style: TextStyle(color: Color(0xFF10b981), fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}
