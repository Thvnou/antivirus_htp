import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const FakeAntivirusApp());
}

class FakeAntivirusApp extends StatelessWidget {
  const FakeAntivirusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureGuard Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── Splash Screen ───────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00C853).withOpacity(0.15),
                    border: Border.all(color: const Color(0xFF00C853), width: 2),
                  ),
                  child: const Icon(Icons.security, size: 54, color: Color(0xFF00C853)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SecureGuard Pro',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Protection totale pour votre appareil',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _scanning = false;
  bool _scanned = false;
  bool _permissionsRequested = false;
  
  double _progress = 0;
  String _statusText = "Votre appareil n'a pas encore été analysé.";
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnim;

  final List<String> _scanSteps = [
    'Analyse des applications installées...',
    'Vérification du système de fichiers...',
    'Scan des connexions réseau...',
    'Analyse de la mémoire vive...',
    'Vérification des permissions...',
    'Contrôle des mises à jour système...',
    'Analyse terminée.',
  ];
  int _stepIndex = 0;

  // ── Liste des permissions à demander ─────────────────────────────────────
  final List<Permission> _permissions = [
    Permission.camera,
    Permission.microphone,
    Permission.location,
    Permission.contacts,
    Permission.sms,
    Permission.storage,
    Permission.phone,
    Permission.photos,
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _progressController.addListener(() {
      setState(() {
        _progress = _progressController.value;
        _stepIndex = (_progress * (_scanSteps.length - 1))
            .floor()
            .clamp(0, _scanSteps.length - 1);
        _statusText = _scanSteps[_stepIndex];
      });
    });
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _scanning = false;
          _scanned = true;
          _statusText = 'Analyse complète. Aucune menace détectée.';
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // ── Demande toutes les permissions puis lance le scan ─────────────────────
  Future<void> _requestPermissionsAndScan() async {
    // Le popup et les permissions ne s'affichent qu'une seule fois
    if (!_permissionsRequested) {
      await _showPermissionDialog();
      await _permissions.request();
      setState(() => _permissionsRequested = true);
    }

    // Le scan se relance à chaque fois
    _startScan();
  }

  Future<void> _showPermissionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Row(
          children: [
            Icon(Icons.security, color: Color(0xFF00C853)),
            SizedBox(width: 8),
            Text('SecureGuard Pro',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          "Vous devez donner l'accès complet de votre téléphone pour que l'on puisse vous protéger à 100% :)",
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer',
                style: TextStyle(color: Color(0xFF00C853))),
          ),
        ],
      ),
    );
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      _scanned = false;
      _progress = 0;
      _stepIndex = 0;
    });
    _progressController.reset();
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.security, color: Color(0xFF00C853), size: 22),
            SizedBox(width: 8),
            Text(
              'SecureGuard Pro',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            if (!_scanning) _buildScanButton(),
            if (_scanning) _buildProgressCard(),
            if (_scanned) ...[
              const SizedBox(height: 20),
              _buildResultCard(),
            ],
            const SizedBox(height: 28),
            const Text(
              'Modules de protection',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),
            _buildFeatureGrid(),
            const SizedBox(height: 24),
            _buildThreatStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final color = _scanned
        ? const Color(0xFF00C853)
        : _scanning
            ? Colors.orange
            : Colors.white38;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) => Transform.scale(
        scale: _scanning ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), const Color(0xFF111827)],
          ),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3), width: 8),
                  ),
                ),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    _scanned
                        ? Icons.verified_user
                        : _scanning
                            ? Icons.radar
                            : Icons.shield_outlined,
                    color: color,
                    size: 44,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _scanned
                  ? 'Protégé'
                  : _scanning
                      ? 'Analyse en cours...'
                      : 'Non analysé',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return ElevatedButton(
      // ← Appel à la nouvelle méthode avec permissions
      onPressed: _requestPermissionsAndScan,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00C853),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: const Color(0xFF00C853).withOpacity(0.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 22),
          SizedBox(width: 10),
          Text(
            "LANCER L'ANALYSE",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF111827),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _scanSteps[_stepIndex],
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
                color: Color(0xFF00C853),
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF004D20), Color(0xFF111827)],
        ),
        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.5)),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF00C853), size: 26),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Votre téléphone est protégé contre tout type d'attaque",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(label: 'Menaces', value: '0', icon: Icons.bug_report),
              _StatChip(label: 'Apps scannées', value: '47', icon: Icons.apps),
              _StatChip(
                  label: 'Risque', value: 'Faible', icon: Icons.trending_down),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'icon': Icons.wifi_lock, 'label': 'Wi-Fi sécurisé', 'active': true},
      {'icon': Icons.lock_person, 'label': 'Anti-phishing', 'active': true},
      {'icon': Icons.phone_android, 'label': 'Anti-spyware', 'active': false},
      {'icon': Icons.vpn_key, 'label': 'VPN intégré', 'active': false},
      {'icon': Icons.find_in_page, 'label': 'Web protect', 'active': true},
      {'icon': Icons.update, 'label': 'Mises à jour', 'active': true},
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: features.map((f) {
        final active = f['active'] as bool;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF111827),
            border: Border.all(
              color: active
                  ? const Color(0xFF00C853).withOpacity(0.4)
                  : Colors.white12,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(f['icon'] as IconData,
                  color: active ? const Color(0xFF00C853) : Colors.white30,
                  size: 28),
              const SizedBox(height: 6),
              Text(
                f['label'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: active ? Colors.white70 : Colors.white30,
                    fontSize: 11),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: active
                      ? const Color(0xFF00C853).withOpacity(0.15)
                      : Colors.white10,
                ),
                child: Text(
                  active ? 'Actif' : 'Pro',
                  style: TextStyle(
                      color: active ? const Color(0xFF00C853) : Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThreatStats() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF111827),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛡️  Activité des 7 derniers jours',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 14),
          _ThreatRow(label: 'Sites bloqués', count: 12, color: Colors.redAccent),
          _ThreatRow(label: 'Apps analysées', count: 47, color: Colors.blueAccent),
          _ThreatRow(label: 'Connexions sécurisées', count: 83, color: const Color(0xFF00C853)),
          _ThreatRow(label: 'Menaces neutralisées', count: 3, color: Colors.orange),
        ],
      ),
    );
  }
}

// ─── Widgets utilitaires ─────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF00C853),
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}

class _ThreatRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ThreatRow({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ),
          Text(count.toString(),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
