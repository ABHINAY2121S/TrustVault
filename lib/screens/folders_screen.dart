import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api.dart';
import 'share_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});
  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<dynamic> _folders = [];
  List<dynamic> _allDocs = [];
  bool _loading = true;
  Map<String, dynamic>? _openFolder;
  List<dynamic> _folderDocs = [];

  static const _colors = ['#7c3aed', '#2563eb', '#059669', '#d97706', '#dc2626', '#db2777'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final folders = await ApiService.getFolders();
    final docs = await ApiService.getDocuments();
    setState(() { _folders = folders; _allDocs = docs; _loading = false; });
  }

  Future<void> _openFolderContent(Map<String, dynamic> folder) async {
    setState(() => _openFolder = folder);
    final data = await ApiService.getFolderDocuments(folder['_id']);
    if (mounted) setState(() => _folderDocs = data?['documents'] ?? []);
  }

  void _showCreateFolder() {
    final nameCtrl = TextEditingController();
    String selectedColor = _colors[0];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0f0f1f),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Folder', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Folder name',
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  filled: true, fillColor: const Color(0xFF1a1a2e),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1e293b))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1e293b))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7c3aed))),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: _colors.map((c) {
                  final color = Color(int.parse('0xFF${c.substring(1)}'));
                  return GestureDetector(
                    onTap: () => set(() => selectedColor = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == c ? Border.all(color: Colors.white, width: 2.5) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDoc(Map<String, dynamic> folder) {
    final unassigned = _allDocs.where((d) => d['folderId'] == null || d['folderId'] != folder['_id']).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0f0f1f),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(children: [
              const Text('Add Document', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${unassigned.length} available', style: const TextStyle(color: Color(0xFF64748b), fontSize: 13)),
            ]),
          ),
          Expanded(
            child: unassigned.isEmpty
                ? const Center(child: Text('No documents to add', style: TextStyle(color: Color(0xFF64748b))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: unassigned.length,
                    itemBuilder: (_, i) {
                      final doc = unassigned[i];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF1a1a2e), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.description_outlined, color: Color(0xFF7c3aed), size: 18),
                        ),
                        title: Text(doc['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(doc['category'] ?? '', style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                        trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF7c3aed)),
                        onTap: () async {
                          Navigator.pop(context);
                          await ApiService.addDocToFolder(folder['_id'], doc['_id']);
                          _openFolderContent(folder);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF7c3aed)));

    if (_openFolder != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1e293b)))),
            child: Row(children: [
              GestureDetector(
                onTap: () => setState(() { _openFolder = null; _folderDocs = []; }),
                child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${(_openFolder!['color'] ?? '#7c3aed').substring(1)}')).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.folder_open, color: Color(int.parse('0xFF${(_openFolder!['color'] ?? '#7c3aed').substring(1)}')), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(_openFolder!['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF7c3aed)),
                onPressed: () => _showAddDoc(_openFolder!),
              ),
              if (_folderDocs.isNotEmpty)
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShareScreen(folder: _openFolder, docs: _folderDocs))),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF7c3aed)),
                ),
            ]),
          ),
          Expanded(
            child: _folderDocs.isEmpty
                ? const Center(child: Text('Folder is empty. Add documents.', style: TextStyle(color: Color(0xFF64748b))))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _folderDocs.length,
                    itemBuilder: (_, i) {
                      final doc = _folderDocs[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFF0f0f1f), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1e293b))),
                        child: Row(children: [
                          const Icon(Icons.description_outlined, color: Color(0xFF7c3aed), size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(doc['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            Text(doc['category'] ?? '', style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                          ])),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF475569), size: 20),
                            onPressed: () async {
                              await ApiService.removeDocFromFolder(doc['_id']);
                              _openFolderContent(_openFolder!);
                            },
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        _folders.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF1a1a2e), shape: BoxShape.circle),
                    child: const Icon(Icons.folder_open_outlined, color: Color(0xFF475569), size: 48)),
                  const SizedBox(height: 20),
                  const Text('No folders yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Create folders to organize\nyour documents.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748b))),
                ]),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1),
                itemCount: _folders.length,
                itemBuilder: (_, i) {
                  final folder = _folders[i];
                  final colorHex = folder['color'] ?? '#7c3aed';
                  final color = Color(int.parse('0xFF${colorHex.substring(1)}'));
                  return GestureDetector(
                    onTap: () => _openFolderContent(folder),
                    onLongPress: () => _confirmDeleteFolder(folder),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0f0f1f),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1e293b)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.folder_rounded, color: color, size: 28),
                          ),
                          const Spacer(),
                          Text(folder['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('${folder['documentCount'] ?? 0} document${(folder['documentCount'] ?? 0) != 1 ? 's' : ''}', style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          bottom: 20, right: 20,
          child: FloatingActionButton(
            onPressed: _showCreateFolder,
            backgroundColor: const Color(0xFF7c3aed),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteFolder(Map<String, dynamic> folder) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0f0f1f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Folder?', style: TextStyle(color: Colors.white)),
        content: const Text('Documents inside will be kept but unlinked.', style: TextStyle(color: Color(0xFF94a3b8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748b)))),
          TextButton(onPressed: () async { Navigator.pop(context); await ApiService.deleteFolder(folder['_id']); _load(); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
