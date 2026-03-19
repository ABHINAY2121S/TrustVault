import 'package:flutter/material.dart';
import '../services/api.dart';

class FloatingAIWidget extends StatefulWidget {
  const FloatingAIWidget({super.key});
  @override
  State<FloatingAIWidget> createState() => _FloatingAIWidgetState();
}

class _FloatingAIWidgetState extends State<FloatingAIWidget> with TickerProviderStateMixin {
  bool _isOpen = false;
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': "Hi! I'm your TrustVault AI. Ask me anything about your documents!"}
  ];
  final _inputCtrl = TextEditingController();
  bool _loading = false;
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) _slideCtrl.forward(); else _slideCtrl.reverse();
  }

  Future<void> _send() async {
    final q = _inputCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': q});
      _inputCtrl.clear();
      _loading = true;
    });
    _scroll();
    final reply = await ApiService.queryAI(q);
    setState(() {
      _messages.add({'role': 'assistant', 'content': reply});
      _loading = false;
    });
    _scroll();
  }

  void _scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Chat Drawer
        if (_isOpen)
          Positioned(
            bottom: 90, right: 16, left: 16,
            child: SlideTransition(
              position: _slideAnim,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 380,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0f0f1f), Color(0xFF1a1030)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7c3aed).withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: const Color(0xFF7c3aed).withOpacity(0.15), blurRadius: 30, spreadRadius: 2)],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7c3aed).withOpacity(0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: const BoxDecoration(color: Color(0xFF7c3aed), shape: BoxShape.circle),
                            child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('TrustVault AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('Document intelligence', style: TextStyle(color: Color(0xFF7c3aed), fontSize: 11)),
                          ]),
                          const Spacer(),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10b981), shape: BoxShape.circle)),
                        ]),
                      ),
                      // Messages
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length + (_loading ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _messages.length) {
                              return Row(children: [
                                Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFF7c3aed), shape: BoxShape.circle), child: const Icon(Icons.smart_toy_outlined, size: 12, color: Colors.white)),
                                const SizedBox(width: 8),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(16)),
                                  child: const SizedBox(width: 40, height: 12, child: LinearProgressIndicator(backgroundColor: Color(0xFF334155), color: Color(0xFF7c3aed)))),
                              ]);
                            }
                            final msg = _messages[i];
                            final isUser = msg['role'] == 'user';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isUser) ...[
                                    Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFF7c3aed), shape: BoxShape.circle), child: const Icon(Icons.smart_toy_outlined, size: 12, color: Colors.white)),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isUser ? const Color(0xFF7c3aed).withOpacity(0.2) : const Color(0xFF1e293b),
                                        borderRadius: BorderRadius.circular(16).copyWith(
                                          bottomRight: isUser ? const Radius.circular(4) : null,
                                          bottomLeft: !isUser ? const Radius.circular(4) : null,
                                        ),
                                        border: Border.all(color: isUser ? const Color(0xFF7c3aed).withOpacity(0.3) : const Color(0xFF334155)),
                                      ),
                                      child: Text(msg['content'] ?? '', style: TextStyle(color: isUser ? const Color(0xFFc4b5fd) : const Color(0xFFcbd5e1), fontSize: 13)),
                                    ),
                                  ),
                                  if (isUser) ...[
                                    const SizedBox(width: 6),
                                    Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFF4f46e5), shape: BoxShape.circle), child: const Icon(Icons.person, size: 12, color: Colors.white)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Input
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1e293b))), borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _inputCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Ask about your documents...',
                                hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                                isDense: true,
                                filled: true, fillColor: const Color(0xFF1e293b),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _send,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Color(0xFF7c3aed), shape: BoxShape.circle),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Floating Button
        Positioned(
          bottom: 20, right: 20,
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFF6d28d9)]),
                  boxShadow: _isOpen ? [] : [
                    BoxShadow(color: const Color(0xFF7c3aed).withOpacity(0.3 + 0.25 * _pulseCtrl.value), blurRadius: 12 + 10 * _pulseCtrl.value, spreadRadius: 1 + 2 * _pulseCtrl.value),
                  ],
                ),
                child: Icon(_isOpen ? Icons.close_rounded : Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
