import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';

class DocumentViewerScreen extends StatelessWidget {
  final Map<String, dynamic> doc;
  const DocumentViewerScreen({super.key, required this.doc});

  Color _catColor(String? cat) {
    switch (cat) {
      case 'Government': return const Color(0xFFf59e0b);
      case 'Medical':    return const Color(0xFF10b981);
      case 'Education':  return const Color(0xFF3b82f6);
      default:           return const Color(0xFF7c3aed);
    }
  }

  IconData _catIcon(String? cat) {
    switch (cat) {
      case 'Government': return Icons.account_balance_rounded;
      case 'Medical':    return Icons.local_hospital_rounded;
      case 'Education':  return Icons.school_rounded;
      default:           return Icons.description_rounded;
    }
  }

  String _fmtDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final d = DateTime.parse(dateStr);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  bool get _hasRealFile {
    final url = doc['fileUrl'] as String? ?? '';
    return url.startsWith('/uploads/');
  }

  bool get _isImage {
    final url = doc['fileUrl'] as String? ?? '';
    return url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.webp');
  }

  String get _fileHttpUrl {
    final raw = doc['fileUrl'] as String? ?? '';
    final base = baseUrl.replaceAll('/api', '');
    return '$base$raw';
  }

  @override
  Widget build(BuildContext context) {
    final cat = doc['category'] as String? ?? 'Other';
    final color = _catColor(cat);
    final status = doc['verificationStatus'] ?? 'unverified';
    final issuer = doc['issuerId'];
    final issuerName = issuer is Map ? (issuer['orgName'] ?? 'Unknown Issuer') : null;
    final meta = (doc['metadata'] as Map?)?.cast<String, dynamic>() ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF080818) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF64748b) : const Color(0xFF64748b);
    final sectionBg = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF080818) : Colors.white,
        title: Text(doc['title'] ?? 'Document', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: textColor), onPressed: () => Navigator.pop(context)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Hero card ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(_catIcon(cat), color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doc['title'] ?? 'Document', style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(cat, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
              ])),
              // Status chip
              if (status == 'verified')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF10b981), size: 13),
                    SizedBox(width: 4),
                    Text('Verified', style: TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Document preview ───────────────────────────────────────────────
          if (_hasRealFile) ...[
            Text('DOCUMENT', style: TextStyle(color: subColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            if (_isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  _fileHttpUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: CircularProgressIndicator(color: Color(0xFF7c3aed))),
                    );
                  },
                  errorBuilder: (_, __, ___) => _docPlaceholder(cardColor, borderColor, textColor),
                ),
              )
            else
              // PDF — open in browser
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(_fileHttpUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFef4444).withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFef4444), size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text('Tap to open PDF', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Opens in your browser / PDF viewer', style: TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                  ])),
                ),
              ),
            const SizedBox(height: 20),
          ],

          // ── Details section ────────────────────────────────────────────────
          if (issuerName != null) ...[
            _sectionHeader('ISSUER INFORMATION', subColor),
            const SizedBox(height: 8),
            _infoCard(sectionBg, borderColor, [
              _infoRow(Icons.business_rounded, 'Organization', issuerName, textColor, subColor),
              if (issuer is Map && issuer['orgType'] != null)
                _infoRow(Icons.category_rounded, 'Type', issuer['orgType'].toString(), textColor, subColor),
            ]),
            const SizedBox(height: 16),
          ],

          _sectionHeader('DATES', subColor),
          const SizedBox(height: 8),
          _infoCard(sectionBg, borderColor, [
            _infoRow(Icons.calendar_today_outlined, 'Issued On', _fmtDate(doc['createdAt']), textColor, subColor),
            if (doc['expiryDate'] != null)
              _infoRow(Icons.event_rounded, 'Expires On', _fmtDate(doc['expiryDate']), textColor, subColor),
          ]),

          if (meta.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionHeader('DOCUMENT DETAILS', subColor),
            const SizedBox(height: 8),
            _infoCard(sectionBg, borderColor, [
              for (final e in meta.entries)
                if (e.value.toString().isNotEmpty)
                  _infoRow(Icons.info_outline_rounded, e.key, e.value.toString(), textColor, subColor),
            ]),
          ],

          if (doc['hash'] != null) ...[
            const SizedBox(height: 16),
            _sectionHeader('VERIFICATION', subColor),
            const SizedBox(height: 8),
            _infoCard(sectionBg, borderColor, [
              _infoRow(Icons.fingerprint_rounded, 'Document Hash',
                '${(doc['hash'] as String).substring(0, 20)}…', textColor, subColor, mono: true),
              _infoRow(Icons.lock_rounded, 'Signature', 'Cryptographically Signed ✓', textColor, subColor),
            ]),
          ],

          // ── Open button ────────────────────────────────────────────────────
          if (_hasRealFile) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(_fileHttpUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(_isImage ? 'Open Full Image' : 'Open PDF Document', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7c3aed),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFf59e0b).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.25)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFf59e0b), size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('File not available for preview. Please ask the issuer to re-issue this document.', style: TextStyle(color: Color(0xFFf59e0b), fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _docPlaceholder(Color cardColor, Color borderColor, Color textColor) {
    return Container(
      height: 160,
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.broken_image_rounded, color: Color(0xFF475569), size: 40),
        const SizedBox(height: 8),
        Text('Could not load image', style: TextStyle(color: textColor, fontSize: 13)),
      ])),
    );
  }

  Widget _sectionHeader(String title, Color color) => Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8));

  Widget _infoCard(Color bg, Color border, List<Widget> rows) => Container(
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
    child: Column(children: rows),
  );

  Widget _infoRow(IconData icon, String label, String value, Color textColor, Color subColor, {bool mono = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(children: [
      Icon(icon, color: subColor, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: subColor, fontSize: 10, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
          color: mono ? const Color(0xFF7c3aed) : textColor,
          fontSize: 13,
          fontFamily: mono ? 'monospace' : null,
          fontWeight: FontWeight.w500,
        )),
      ])),
    ]),
  );
}
