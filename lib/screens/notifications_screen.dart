import 'package:flutter/material.dart';
import '../services/api.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _requests = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getPendingAccessRequests();
    if (mounted) setState(() { _requests = data; _loading = false; });
  }

  Future<void> _respond(String id, String action) async {
    await ApiService.respondToRequest(id, action);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(action == 'approve' ? '✅ Access granted' : '❌ Access denied'),
        backgroundColor: action == 'approve' ? const Color(0xFF059669) : const Color(0xFFdc2626),
        duration: const Duration(seconds: 2),
      ));
    }
  }

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

    if (_requests.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF7c3aed),
        backgroundColor: cardBg,
        onRefresh: _load,
        child: ListView(children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFEDE9FE), shape: BoxShape.circle),
                child: Icon(Icons.notifications_none_outlined, color: isDark ? const Color(0xFF475569) : const Color(0xFF7c3aed), size: 48),
              ),
              const SizedBox(height: 20),
              Text('No pending requests', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('When a verifier requests access\nto your documents, it will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
              const SizedBox(height: 20),
              TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Refresh'), style: TextButton.styleFrom(foregroundColor: const Color(0xFF7c3aed))),
            ])),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF7c3aed),
      backgroundColor: cardBg,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (_, i) {
          final req = _requests[i];
          final isFolder = req['resourceType'] == 'folder';
          final vName = req['verifierName'] ?? 'A Verifier';
          final vOrg = req['verifierEmail'] ?? '';
          final time = DateTime.parse(req['createdAt']);
          final age = DateTime.now().difference(time);
          final ageStr = age.inHours >= 1 ? '${age.inHours}h ago' : '${age.inMinutes}m ago';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF7c3aed).withOpacity(0.25)),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(children: [

              // ── Request info ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF7c3aed).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(isFolder ? Icons.folder_shared_outlined : Icons.description_outlined, color: const Color(0xFF7c3aed), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(vName, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 15)),
                      if (vOrg.isNotEmpty)
                        Text(vOrg, style: const TextStyle(color: Color(0xFF7c3aed), fontSize: 12, fontWeight: FontWeight.w500)),
                    ])),
                    // PENDING badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf59e0b).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.3)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(width: 5, height: 5, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFf59e0b), shape: BoxShape.circle))),
                        SizedBox(width: 5),
                        Text('PENDING', style: TextStyle(color: Color(0xFFf59e0b), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 14),

                  // Message box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '$vName is requesting access to your ${isFolder ? "folder" : "document"}.',
                        style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      const Text('Do you want to allow them to view it?', style: TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(ageStr, style: const TextStyle(color: Color(0xFF475569), fontSize: 11)),
                    ]),
                  ),
                ]),
              ),

              // ── Action buttons ───────────────────────────────────────
              Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: borderColor))),
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  // Allow — prominent green full-width
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _respond(req['_id'], 'approve'),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Allow Access', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Deny — outlined red, less prominent
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => _respond(req['_id'], 'deny'),
                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFf87171)),
                      label: const Text('Deny', style: TextStyle(color: Color(0xFFf87171), fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFdc2626), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
              ),

            ]),
          );
        },
      ),
    );
  }
}
