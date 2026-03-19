import 'package:flutter/material.dart';
import '../services/api.dart';
import 'upload_screen.dart';
import 'category_folder_screen.dart';
import 'document_viewer_screen.dart';
import 'custom_folder_detail_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<dynamic> _docs = [];
  List<dynamic> _expiring = [];
  List<dynamic> _customFolders = [];
  bool _loading = true;
  bool _offline = false;

  static const _categoryFolders = [
    {'name': 'Government', 'icon': Icons.account_balance_rounded,  'color': 0xFFf59e0b},
    {'name': 'Medical',    'icon': Icons.local_hospital_rounded,   'color': 0xFF10b981},
    {'name': 'Education',  'icon': Icons.school_rounded,           'color': 0xFF3b82f6},
    {'name': 'Others',     'icon': Icons.description_rounded,      'color': 0xFF7c3aed},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _offline = false; });
    try {
      final docs = await ApiService.getDocuments();
      final expiring = await ApiService.getExpiringDocuments();
      final folders = await ApiService.getFolders();
      if (mounted) setState(() {
        _docs = docs;
        _expiring = expiring;
        _customFolders = folders;
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _offline = true; });
    }
  }

  int _docCount(String category) {
    if (category == 'Others') return _docs.where((d) { final c = d['category'] ?? 'Other'; return c == 'Other' || c == 'Others'; }).length;
    return _docs.where((d) => d['category'] == category).length;
  }

  Color _statusColor(String status) {
    if (status == 'verified') return const Color(0xFF10b981);
    if (status == 'partially_verified') return const Color(0xFFf59e0b);
    return const Color(0xFF64748b);
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Education': return Icons.school_outlined;
      case 'Medical': return Icons.local_hospital_outlined;
      case 'Government': return Icons.account_balance_outlined;
      default: return Icons.description_outlined;
    }
  }

  // ─── Create folder bottom sheet ─────────────────────────────────────────
  void _showCreateFolder(bool isDark) {
    final nameCtrl = TextEditingController();
    const colors = ['#7c3aed', '#2563eb', '#059669', '#d97706', '#dc2626', '#db2777'];
    String selectedColor = colors[0];
    final sheetBg = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final borderCol = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);
    final fillCol = isDark ? const Color(0xFF1a1a2e) : const Color(0xFFF8FAFC);
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('New Folder', style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: TextStyle(color: textCol),
              decoration: InputDecoration(
                hintText: 'Folder name (e.g. Interview, Visa)',
                hintStyle: const TextStyle(color: Color(0xFF475569)),
                filled: true, fillColor: fillCol,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderCol)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderCol)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7c3aed))),
              ),
            ),
            const SizedBox(height: 16),
            Text('Color', style: TextStyle(color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 13)),
            const SizedBox(height: 10),
            Row(children: colors.map((c) {
              final color = Color(int.parse('0xFF${c.substring(1)}'));
              return GestureDetector(
                onTap: () => set(() => selectedColor = c),
                child: Container(margin: const EdgeInsets.only(right: 10), width: 32, height: 32,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: selectedColor == c ? Border.all(color: isDark ? Colors.white : const Color(0xFF7c3aed), width: 2.5) : null)),
              );
            }).toList()),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await ApiService.createFolder(nameCtrl.text.trim(), selectedColor);
                  _load();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7c3aed), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Create Folder', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF080818) : const Color(0xFFF1F5F9);

    if (_loading) {
      return Container(color: bgColor, child: const Center(child: CircularProgressIndicator(color: Color(0xFF7c3aed))));
    }

    if (_offline) {
      return Container(
        color: bgColor,
        child: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFef4444).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFef4444), size: 48)),
            const SizedBox(height: 20),
            Text('Server unreachable', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Make sure your backend is running\nand you are on the same Wi-Fi.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748b), fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7c3aed), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ]),
        )),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF7c3aed),
      backgroundColor: isDark ? const Color(0xFF0f0f1f) : Colors.white,
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // ── Expiry alert ──────────────────────────────────────────────
          if (_expiring.isNotEmpty)
            SliverToBoxAdapter(child: _expiryBanner()),

          // ── Folder section ────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildFoldersSection(isDark)),

          // ── All docs ──────────────────────────────────────────────────
          if (_docs.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: _sectionHeader(isDark),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _docCard(_docs[i], isDark),
                  childCount: _docs.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
              ),
            ),
          ] else
            SliverToBoxAdapter(child: _emptyState(isDark)),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _expiryBanner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFf59e0b).withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.notifications_active_outlined, color: Color(0xFFf59e0b), size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text('${_expiring.length} document${_expiring.length > 1 ? 's' : ''} expiring within 30 days', style: const TextStyle(color: Color(0xFFf59e0b), fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );

  Widget _buildFoldersSection(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        Row(children: [
          const Icon(Icons.folder_rounded, color: Color(0xFF7c3aed), size: 20),
          const SizedBox(width: 8),
          Text('Folders', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showCreateFolder(isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF7c3aed).withOpacity(0.10), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF7c3aed).withOpacity(0.3))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.create_new_folder_rounded, color: Color(0xFF7c3aed), size: 14),
                SizedBox(width: 5),
                Text('Create Folder', style: TextStyle(color: Color(0xFF7c3aed), fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),

        const SizedBox(height: 14),

        // ── Pre-built category folders ──
        Container(
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor),
            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))]),
          child: Column(children: _categoryFolders.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final name = cat['name'] as String;
            final icon = cat['icon'] as IconData;
            final color = Color(cat['color'] as int);
            final count = _docCount(name);
            final isLast = i == _categoryFolders.length - 1;

            return Column(children: [
              InkWell(
                borderRadius: BorderRadius.vertical(top: i == 0 ? const Radius.circular(18) : Radius.zero, bottom: isLast ? const Radius.circular(18) : Radius.zero),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryFolderScreen(category: name))).then((_) => _load()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: color, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(name, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Text('$count', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), size: 20),
                  ]),
                ),
              ),
              if (!isLast) Divider(height: 1, thickness: 1, indent: 74, color: borderColor),
            ]);
          }).toList()),
        ),

        // ── Custom folders (user-created) ──
        if (_customFolders.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('MY FOLDERS', style: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFF94a3b8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))]),
            child: Column(children: _customFolders.asMap().entries.map((entry) {
              final i = entry.key;
              final folder = entry.value;
              final colorHex = folder['color'] ?? '#7c3aed';
              final color = Color(int.parse('0xFF${colorHex.substring(1)}'));
              final count = folder['documentCount'] ?? 0;
              final isLast = i == _customFolders.length - 1;

              return Column(children: [
                InkWell(
                  borderRadius: BorderRadius.vertical(top: i == 0 ? const Radius.circular(18) : Radius.zero, bottom: isLast ? const Radius.circular(18) : Radius.zero),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomFolderDetailScreen(folder: folder, allDocs: _docs))).then((_) => _load()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.folder_rounded, color: color, size: 22)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(folder['name'] ?? '', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                        Text('$count doc${count != 1 ? 's' : ''}', style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                      ])),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Text('$count', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), size: 20),
                    ]),
                  ),
                ),
                if (!isLast) Divider(height: 1, thickness: 1, indent: 74, color: borderColor),
              ]);
            }).toList()),
          ),
        ],
      ]),
    );
  }

  Widget _sectionHeader(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Row(children: [
      Text('All Documents', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(width: 12),
      Expanded(child: Container(height: 1, color: isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0))),
      const SizedBox(width: 12),
      Text('${_docs.length} doc${_docs.length != 1 ? 's' : ''}', style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
    ]);
  }

  Widget _emptyState(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: Icon(Icons.account_balance_wallet_outlined, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), size: 48)),
        const SizedBox(height: 20),
        Text('Your wallet is empty', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Upload a document or wait for\nan issuer to send one.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen())).then((_) => _load()),
          icon: const Icon(Icons.upload_outlined, size: 18),
          label: const Text('Upload Document'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7c3aed), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ])),
    );
  }

  Widget _docCard(Map<String, dynamic> doc, bool isDark) {
    final status = doc['verificationStatus'] ?? 'unverified';
    final isExpired = doc['expiryDate'] != null && DateTime.parse(doc['expiryDate']).isBefore(DateTime.now());
    final cardColor = isDark ? const Color(0xFF0f0f1f) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentViewerScreen(doc: doc))),
      child: Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0,2))]),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: Icon(_categoryIcon(doc['category'] ?? 'Other'), color: const Color(0xFF7c3aed), size: 20)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: _statusColor(status).withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 5, height: 5, decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(status == 'verified' ? 'Verified' : status == 'partially_verified' ? 'Partial' : 'Pending', style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const Spacer(),
            Text(doc['title'] ?? '', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(doc['category'] ?? 'Other', style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
            if (doc['issuerId'] != null && doc['issuerId'] is Map)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('${doc['issuerId']['orgName']}', style: const TextStyle(color: Color(0xFF7c3aed), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (doc['expiryDate'] != null)
              Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [
                Icon(Icons.access_time, size: 11, color: isExpired ? Colors.red : const Color(0xFF64748b)),
                const SizedBox(width: 3),
                Text(isExpired ? 'Expired' : 'Exp: ${_fmtDate(doc['expiryDate'])}', style: TextStyle(color: isExpired ? Colors.red : const Color(0xFF64748b), fontSize: 11)),
              ])),
          ]),
        ),
      ),
    );
  }

  String _fmtDate(String dateStr) {
    final d = DateTime.parse(dateStr);
    return '${d.day}/${d.month}/${d.year}';
  }
}
