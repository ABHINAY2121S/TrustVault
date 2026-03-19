import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/issued_docs_screen.dart';
import 'screens/share_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/upload_screen.dart';
import 'widgets/floating_ai.dart';
import 'services/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const TrustVaultApp(),
    ),
  );
}

class TrustVaultApp extends StatelessWidget {
  const TrustVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'TrustVault',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      // ── Dark theme (unchanged purple/black) ──────────────────────────────
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080818),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7c3aed),
          secondary: Color(0xFF6d28d9),
          surface: Color(0xFF0f0f1f),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF080818),
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),

      // ── Light theme (white/grey/purple accent) ───────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF7c3aed),
          secondary: Color(0xFF6d28d9),
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        ),
      ),

      home: const AppGate(),
    );
  }
}

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const AuthScreen();
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  int _pendingCount = 0;
  Timer? _pollTimer;

  final _pages = const [
    WalletScreen(),
    IssuedDocsScreen(),
    ShareScreen(),
    NotificationsScreen(),
  ];

  final _labels = const ['Wallet', 'Issued', 'Share', 'Requests'];
  final _icons = const [
    Icons.account_balance_wallet_outlined,
    Icons.verified_outlined,
    Icons.qr_code_2_outlined,
    Icons.notifications_outlined,
  ];
  final _activeIcons = const [
    Icons.account_balance_wallet_rounded,
    Icons.verified_rounded,
    Icons.qr_code_2_rounded,
    Icons.notifications_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollPending();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollPending());
  }

  Future<void> _pollPending() async {
    final requests = await ApiService.getPendingAccessRequests();
    if (mounted) setState(() => _pendingCount = requests.length);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final appBarBg = isDark ? const Color(0xFF080818) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF1e293b) : const Color(0xFFE2E8F0);
    final navBg = isDark ? const Color(0xFF0a0a1a) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF080818) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
        title: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFF4f46e5)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text('TrustVault', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        actions: [
          // ── Theme Toggle ─────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF2d2d4e) : const Color(0xFFE2E8F0)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              // Light mode button
              GestureDetector(
                onTap: isDark ? () => themeProvider.toggle() : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: !isDark ? const Color(0xFF7c3aed) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.wb_sunny_rounded, size: 14, color: !isDark ? Colors.white : const Color(0xFF64748b)),
                    if (!isDark) ...[
                      const SizedBox(width: 4),
                      const Text('Light', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ),
              ),
              // Dark mode button
              GestureDetector(
                onTap: !isDark ? () => themeProvider.toggle() : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF7c3aed) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.dark_mode_rounded, size: 14, color: isDark ? Colors.white : const Color(0xFF64748b)),
                    if (isDark) ...[
                      const SizedBox(width: 4),
                      const Text('Dark', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
          // ── Upload ───────────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.upload_file_outlined, color: Color(0xFF7c3aed)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen())),
            tooltip: 'Upload document',
          ),
          // ── Logout ───────────────────────────────────────────────────────
          IconButton(
            icon: Icon(Icons.logout_outlined, color: isDark ? const Color(0xFF475569) : const Color(0xFF94a3b8)),
            onPressed: () => context.read<AuthProvider>().logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(index: _tab, children: _pages),
          const FloatingAIWidget(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (i) {
                final isActive = _tab == i;
                final hasNotif = i == 3 && _pendingCount > 0;
                final activeColor = const Color(0xFF7c3aed);
                final inactiveColor = isDark ? const Color(0xFF475569) : const Color(0xFF94a3b8);

                return GestureDetector(
                  onTap: () { setState(() => _tab = i); if (i == 3) _pollPending(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Icon(
                          isActive ? _activeIcons[i] : _icons[i],
                          color: isActive ? activeColor : inactiveColor,
                          size: 22,
                        ),
                        if (hasNotif)
                          Positioned(
                            top: -4, right: -4,
                            child: Container(
                              width: 16, height: 16,
                              decoration: const BoxDecoration(color: Color(0xFFef4444), shape: BoxShape.circle),
                              child: Center(child: Text('$_pendingCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 3),
                      Text(_labels[i], style: TextStyle(
                        color: isActive ? activeColor : inactiveColor,
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      )),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
