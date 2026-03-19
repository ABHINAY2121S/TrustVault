import 'package:flutter/material.dart';
import '../services/api.dart';
import 'share_screen.dart';
import 'document_viewer_screen.dart';

class CustomFolderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> folder;
  final List<dynamic> allDocs;

  const CustomFolderDetailScreen({super.key, required this.folder, required this.allDocs});
  @override
  State<CustomFolderDetailScreen> createState() => _CustomFolderDetailScreenState();
}

class _CustomFolderDetailScreenState extends State<CustomFolderDetailScreen> {
  List<dynamic> _folderDocs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    setState(() => _loading = true);
    final data = await ApiService.getFolderDocuments(widget.folder['_id']);
    if (mounted) setState(() {
      _folderDocs = data?['documents'] ?? [];
      _loading = false;
    });
  }

  Color get _folderColor {
    final hex = widget.folder['color'] ?? '#7c3aed';
    return Color(int.parse('0xFF${hex.substring(1)}'));
  }

  // ── Add document bottom sheet ─────────────────────────────────────────
  void _showAddDocs(bool isDark) {
    // All docs not already in this folder
    final folderDocIds = _folderDocs.map((d) => d['_id']).toSet();
    final available = widget.allDocs.where((d) => !folderDocIds.contains(d['_id'])).toList();

    final sheetBg = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1a1a2e) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Set<String> selected = {};

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(children: [
            // Handle
            Container(margin: const EdgeInsets.only(top: 12, bottom: 4), width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(children: [
                Text('Add Documents', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${selected.length} selected', style: const TextStyle(color: Color(0xFF7c3aed), fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            ),
            Divider(height: 1, color: borderColor),
            Expanded(
              child: available.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.description_outlined, color: Color(0xFF475569), size: 40),
                      const SizedBox(height: 12),
                      Text('All documents already added', style: TextStyle(color: textColor, fontSize: 14)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: available.length,
                      itemBuilder: (_, i) {
                        final doc = available[i];
                        final id = doc['_id'] as String;
                        final isSelected = selected.contains(id);
                        final cat = doc['category'] ?? 'Other';

                        return GestureDetector(
                          onTap: () => set(() => isSelected ? selected.remove(id) : selected.add(id)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF7c3aed).withOpacity(0.08) : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isSelected ? const Color(0xFF7c3aed).withOpacity(0.4) : borderColor),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFF7c3aed).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Icon(_catIcon(cat), color: const Color(0xFF7c3aed), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(doc['title'] ?? '', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
                                Text(cat, style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                              ])),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF7c3aed) : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? const Color(0xFF7c3aed) : const Color(0xFF475569), width: 2),
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: selected.isEmpty ? null : () async {
                    Navigator.pop(context);
                    for (final id in selected) {
                      await ApiService.addDocToFolder(widget.folder['_id'], id);
                    }
                    _loadDocs();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(selected.isEmpty ? 'Select documents' : 'Add ${selected.length} document${selected.length > 1 ? 's' : ''}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7c3aed),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF475569),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Education': return Icons.school_outlined;
      case 'Medical': return Icons.local_hospital_outlined;
      case 'Government': return Icons.account_balance_outlined;
      default: return Icons.description_outlined;
    }
  }

  Color _statusColor(String s) {
    if (s == 'verified') return const Color(0xFF10b981);
    if (s == 'partially_verified') return const Color(0xFFf59e0b);
    return const Color(0xFF64748b);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF080818) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final color = _folderColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF080818) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: borderColor)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.folder_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.folder['name'] ?? '', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          // ── Add documents button ─────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF7c3aed)),
            tooltip: 'Add document',
            onPressed: () => _showAddDocs(isDark),
          ),
          // ── Share button (visible when folder has docs) ──────────────
          if (_folderDocs.isNotEmpty)
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ShareScreen(folder: widget.folder, docs: _folderDocs),
              )),
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Share'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7c3aed),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: color))
          : RefreshIndicator(
              color: color,
              onRefresh: _loadDocs,
              child: _folderDocs.isEmpty
                  ? ListView(children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.65,
                        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: color.withOpacity(0.10), shape: BoxShape.circle),
                            child: Icon(Icons.folder_open_rounded, color: color.withOpacity(0.5), size: 48)),
                          const SizedBox(height: 20),
                          Text('Folder is empty', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('Tap the + button to add documents\nfrom any category.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748b), fontSize: 13)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showAddDocs(isDark),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Documents'),
                            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ])),
                      ),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _folderDocs.length,
                      itemBuilder: (_, i) {
                        final doc = _folderDocs[i];
                        final status = doc['verificationStatus'] ?? 'unverified';
                        final statusColor = _statusColor(status);
                        final cat = doc['category'] ?? 'Other';
                        final issuer = doc['issuerId'];
                        final issuerName = issuer is Map ? (issuer['orgName'] ?? '') : '';

                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentViewerScreen(doc: doc))),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0,2))],
                            ),
                            child: Row(children: [
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF7c3aed).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(_catIcon(cat), color: const Color(0xFF7c3aed), size: 20)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(doc['title'] ?? '', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Row(children: [
                                  Text(cat, style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                                  if (issuerName.isNotEmpty) ...[
                                    const Text(' · ', style: TextStyle(color: Color(0xFF475569))),
                                    Expanded(child: Text(issuerName, style: const TextStyle(color: Color(0xFF7c3aed), fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  ],
                                ]),
                              ])),
                              const SizedBox(width: 8),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  if (status == 'verified')
                                    const Icon(Icons.verified_rounded, color: Color(0xFF10b981), size: 11)
                                  else
                                    Container(width: 5, height: 5, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Text(status == 'verified' ? 'Verified' : status == 'partially_verified' ? 'Partial' : 'Pending',
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ]),
                              ),
                              const SizedBox(width: 4),
                              // Remove button
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF475569), size: 20),
                                onPressed: () async {
                                  await ApiService.removeDocFromFolder(doc['_id']);
                                  _loadDocs();
                                },
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
