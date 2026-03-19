import 'package:flutter/material.dart';
import '../services/api.dart';
import 'document_viewer_screen.dart';

class CategoryFolderScreen extends StatefulWidget {
  final String category;
  const CategoryFolderScreen({super.key, required this.category});

  @override
  State<CategoryFolderScreen> createState() => _CategoryFolderScreenState();
}

class _CategoryFolderScreenState extends State<CategoryFolderScreen> {
  List<dynamic> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await ApiService.getDocuments();
    setState(() {
      if (widget.category == 'Others') {
        _docs = all.where((d) {
          final cat = d['category'] ?? 'Other';
          return cat == 'Other' || cat == 'Others';
        }).toList();
      } else {
        _docs = all.where((d) => d['category'] == widget.category).toList();
      }
      _loading = false;
    });
  }

  Color _catColor() {
    switch (widget.category) {
      case 'Government': return const Color(0xFFf59e0b);
      case 'Medical':    return const Color(0xFF10b981);
      case 'Education':  return const Color(0xFF3b82f6);
      default:           return const Color(0xFF7c3aed);
    }
  }

  IconData _catIcon() {
    switch (widget.category) {
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

  Color _statusColor(String status) {
    if (status == 'verified') return const Color(0xFF10b981);
    if (status == 'partially_verified') return const Color(0xFFf59e0b);
    return const Color(0xFF64748b);
  }

  String _statusLabel(String status) {
    if (status == 'verified') return 'Verified';
    if (status == 'partially_verified') return 'Partial';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final color = _catColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF080818) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF64748b) : const Color(0xFF64748b);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF080818) : Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(_catIcon(), color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(widget.category, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7c3aed)))
          : RefreshIndicator(
              color: const Color(0xFF7c3aed),
              onRefresh: _load,
              child: _docs.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(_catIcon(), color: color.withOpacity(0.5), size: 48),
                        ),
                        const SizedBox(height: 20),
                        Text('No ${widget.category} documents', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Documents issued by ${widget.category.toLowerCase()}\nauthorities will appear here.', textAlign: TextAlign.center, style: TextStyle(color: subColor, fontSize: 14)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _docs.length,
                      itemBuilder: (_, i) => _docCard(_docs[i], cardColor, borderColor, textColor, subColor),
                    ),
            ),
    );
  }

  Widget _docCard(Map<String, dynamic> doc, Color cardColor, Color borderColor, Color textColor, Color subColor) {
    final status = doc['verificationStatus'] ?? 'unverified';
    final statusColor = _statusColor(status);
    final issuer = doc['issuerId'];
    final issuerName = issuer is Map ? (issuer['orgName'] ?? 'Unknown') : null;
    final color = _catColor();
    final isExpired = doc['expiryDate'] != null && DateTime.parse(doc['expiryDate']).isBefore(DateTime.now());

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(doc: doc),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          children: [
            // Color top bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.4)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_catIcon(), color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(doc['title'] ?? 'Document', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (issuerName != null)
                      Text(issuerName, style: const TextStyle(color: Color(0xFF7c3aed), fontSize: 12, fontWeight: FontWeight.w500)),
                  ])),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (status == 'verified')
                        const Icon(Icons.verified_rounded, color: Color(0xFF10b981), size: 12)
                      else
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(_statusLabel(status), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ]),

                const SizedBox(height: 12),

                // Footer row
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF64748b), size: 12),
                  const SizedBox(width: 6),
                  Text(_fmtDate(doc['createdAt']), style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                  const Spacer(),
                  if (doc['expiryDate'] != null)
                    Text(isExpired ? 'Expired' : 'Exp: ${_fmtDate(doc['expiryDate'])}',
                      style: TextStyle(color: isExpired ? Colors.red : const Color(0xFF64748b), fontSize: 12)),
                  const SizedBox(width: 8),
                  const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.touch_app_rounded, color: Color(0xFF475569), size: 12),
                    SizedBox(width: 3),
                    Text('Tap to view', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
                  ]),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
