import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../services/api.dart';
import 'share_screen.dart';

class IssuedDocsScreen extends StatefulWidget {
  const IssuedDocsScreen({super.key});
  @override
  State<IssuedDocsScreen> createState() => _IssuedDocsScreenState();
}

class _IssuedDocsScreenState extends State<IssuedDocsScreen> {
  List<dynamic> _docs = [];
  bool _loading = true;
  String _filter = 'All';

  static const _categories = ['All', 'Education', 'Medical', 'Government', 'Other'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await ApiService.getDocuments();
    setState(() {
      _docs = all.where((d) =>
        d['verificationStatus'] == 'verified' && d['issuerId'] != null
      ).toList();
      _loading = false;
    });
  }

  List<dynamic> get _filtered {
    if (_filter == 'All') return _docs;
    return _docs.where((d) => d['category'] == _filter).toList();
  }

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case 'Education': return Icons.school_rounded;
      case 'Medical': return Icons.local_hospital_rounded;
      case 'Government': return Icons.account_balance_rounded;
      default: return Icons.description_rounded;
    }
  }

  Color _categoryColor(String? cat) {
    switch (cat) {
      case 'Education': return const Color(0xFF3b82f6);
      case 'Medical': return const Color(0xFF10b981);
      case 'Government': return const Color(0xFFf59e0b);
      default: return const Color(0xFF7c3aed);
    }
  }

  String _fmtDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final d = DateTime.parse(dateStr);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _showDetails(Map<String, dynamic> doc, bool isDark) {
    final cat = doc['category'] as String? ?? 'Other';
    final color = _categoryColor(cat);
    final issuer = doc['issuerId'];
    final issuerName = issuer is Map ? (issuer['orgName'] ?? issuer['name'] ?? 'Unknown Issuer') : 'Verified Issuer';
    final meta = (doc['metadata'] as Map?)?.cast<String, dynamic>() ?? {};
    final cardBg = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final sectionBg = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF475569) : const Color(0xFF64748b);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: ctrl,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40, height: 4,
                decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)),
              )),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_categoryIcon(cat), color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(doc['title'] ?? 'Document', style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(cat, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
                  ])),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _detailSection('Issuer Information', sectionBg, borderColor, textColor, subColor, [
                    _detailRow(Icons.business_rounded, 'Organization', issuerName, textColor, subColor),
                    if (issuer is Map && issuer['orgType'] != null)
                      _detailRow(Icons.category_rounded, 'Type', issuer['orgType'].toString(), textColor, subColor),
                  ]),
                  const SizedBox(height: 16),
                  _detailSection('Dates', sectionBg, borderColor, textColor, subColor, [
                    _detailRow(Icons.calendar_today_outlined, 'Issued On', _fmtDate(doc['createdAt']), textColor, subColor),
                    if (doc['expiryDate'] != null)
                      _detailRow(Icons.event_rounded, 'Expires On', _fmtDate(doc['expiryDate']), textColor, subColor),
                  ]),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _detailSection('Document Details', sectionBg, borderColor, textColor, subColor, [
                      for (final e in meta.entries)
                        if (e.key != 'Issued On' && e.value.toString().isNotEmpty)
                          _detailRow(Icons.info_outline_rounded, e.key, e.value.toString(), textColor, subColor),
                    ]),
                  ],
                  if (doc['hash'] != null) ...[
                    const SizedBox(height: 16),
                    _detailSection('Verification', sectionBg, borderColor, textColor, subColor, [
                      _detailRow(Icons.fingerprint_rounded, 'Document Hash',
                        '${(doc['hash'] as String).substring(0, 20)}…', textColor, subColor, mono: true),
                      _detailRow(Icons.lock_rounded, 'Signature', 'Cryptographically Signed ✓', textColor, subColor),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final rawUrl = doc['fileUrl'] as String? ?? '';
                          if (rawUrl.startsWith('/uploads/')) {
                            final fileUrl = Uri.parse('${baseUrl.replaceAll('/api', '')}$rawUrl');
                            if (await canLaunchUrl(fileUrl)) {
                              await launchUrl(fileUrl, mode: LaunchMode.externalApplication);
                            }
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please ask the issuer to re-issue this document.')));
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('View Document'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ShareScreen(singleDoc: doc)));
                      },
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share this Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7c3aed),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, Color bg, Color border, Color textColor, Color subColor, List<Widget> children) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(), style: TextStyle(color: subColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Column(children: children),
      ),
    ]);

  Widget _detailRow(IconData icon, String label, String value, Color textColor, Color subColor, {bool mono = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
          )),
        ])),
      ]),
    );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF080818) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    if (_loading) {
      return Container(color: bgColor, child: const Center(child: CircularProgressIndicator(color: Color(0xFF7c3aed))));
    }

    return RefreshIndicator(
      color: const Color(0xFF7c3aed),
      backgroundColor: cardBg,
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isActive = _filter == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF7c3aed) : cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? const Color(0xFF7c3aed) : borderColor),
                      ),
                      child: Text(cat, style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFF64748b),
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      )),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text('${_filtered.length} verified document${_filtered.length != 1 ? 's' : ''}',
                style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
            ),
          ),
          if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFEDE9FE), shape: BoxShape.circle),
                  child: Icon(Icons.verified_outlined, color: isDark ? const Color(0xFF475569) : const Color(0xFF7c3aed), size: 48),
                ),
                const SizedBox(height: 20),
                Text('No issued documents', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  _filter == 'All' ? 'Documents issued by colleges, hospitals\nor government will appear here.' : 'No $_filter documents found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748b), fontSize: 14),
                ),
              ])),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _docCard(_filtered[i], isDark, cardBg, borderColor, textColor),
                  childCount: _filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _docCard(Map<String, dynamic> doc, bool isDark, Color cardBg, Color borderColor, Color textColor) {
    final cat = doc['category'] as String? ?? 'Other';
    final color = _categoryColor(cat);
    final issuer = doc['issuerId'];
    final issuerName = issuer is Map ? (issuer['orgName'] ?? issuer['name'] ?? 'Unknown Issuer') : 'Verified Issuer';
    final isExpiringSoon = doc['expiryDate'] != null && DateTime.parse(doc['expiryDate']).difference(DateTime.now()).inDays < 30;
    final isExpired = doc['expiryDate'] != null && DateTime.parse(doc['expiryDate']).isBefore(DateTime.now());

    return GestureDetector(
      onTap: () => _showDetails(doc, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0,2))],
        ),
        child: Column(children: [
          Container(height: 4, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.4)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_categoryIcon(cat), color: color, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(doc['title'] ?? 'Document', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(cat, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF10b981), size: 12),
                    SizedBox(width: 4),
                    Text('Verified', style: TextStyle(color: Color(0xFF10b981), fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
                child: Row(children: [
                  const Icon(Icons.business_rounded, color: Color(0xFF475569), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Issued by', style: TextStyle(color: Color(0xFF475569), fontSize: 10, letterSpacing: 0.3)),
                    Text(issuerName, style: TextStyle(color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF374151), fontSize: 13, fontWeight: FontWeight.w500)),
                  ])),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.calendar_today_outlined, color: const Color(0xFF475569), size: 13),
                const SizedBox(width: 6),
                Text('Issued: ${_fmtDate(doc['createdAt'])}', style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                const Spacer(),
                if (doc['expiryDate'] != null)
                  Text(isExpired ? 'Expired' : 'Exp: ${_fmtDate(doc['expiryDate'])}',
                    style: TextStyle(color: isExpired ? Colors.red : isExpiringSoon ? const Color(0xFFf59e0b) : const Color(0xFF475569), fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Text('Tap to view details', style: TextStyle(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), fontSize: 11)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShareScreen(singleDoc: doc))),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Share'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF7c3aed), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: const Color(0xFF7c3aed).withOpacity(0.08)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
