import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // For BackdropFilter
import '../services/api_service.dart';
import '../models/device.dart';
import '../providers/settings_provider.dart';
import '../utils/l10n.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<List<Device>>? _devicesFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      _devicesFuture = apiService.getDevices();
      _initialized = true;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      final apiService = Provider.of<ApiService>(context, listen: false);
      _devicesFuture = apiService.getDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageCode;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(L10n.t('appTitle', lang)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/settings');
                if (result == true) {
                  _refresh();
                }
              },
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [
              Color(0xFF1E293B), // Slightly lighter at top left
              Color(0xFF0F172A), // Deep midnight
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            backgroundColor: const Color(0xFF1E293B),
            color: Theme.of(context).colorScheme.primary,
            child: FutureBuilder<List<Device>>(
              future: _devicesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withOpacity(0.1),
                          ),
                          child: const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          L10n.t('failedToLoad', lang),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: Text(L10n.t('retry', lang)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        )
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(L10n.t('noInventoryFound', lang), style: const TextStyle(color: Colors.white54)),
                  );
                }

                final devices = snapshot.data!;
                final onlineCount = devices.where((d) => d.status.toLowerCase() == 'online').length;

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            L10n.t('networkSummary', lang),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white54),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _GlassStatCard(
                                  title: L10n.t('totalDevices', lang),
                                  value: '${devices.length}',
                                  icon: Icons.memory,
                                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF00E5FF)],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _GlassStatCard(
                                  title: L10n.t('online', lang),
                                  value: '$onlineCount',
                                  icon: Icons.wifi,
                                  gradientColors: const [Color(0xFF10B981), Color(0xFF34D399)],
                                  isGlossy: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                L10n.t('recentDevices', lang),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              Text(
                                L10n.t('seeAll', lang),
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...devices.take(6).map((device) => _DeviceListItem(device: device, lang: lang)).toList(),
                          const SizedBox(height: 80), // Padding for FAB
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/add_device').then((_) => _refresh());
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          label: Text(L10n.t('addDevice', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isGlossy;

  const _GlassStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.isGlossy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B).withOpacity(0.8),
            const Color(0xFF0F172A).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        boxShadow: [
          if (isGlossy)
            BoxShadow(
              color: gradientColors.last.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: gradientColors.first.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceListItem extends StatelessWidget {
  final Device device;
  final String lang;

  const _DeviceListItem({required this.device, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isOnline = device.status.toLowerCase() == 'online';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isOnline 
                ? const Color(0xFF10B981).withOpacity(0.1) 
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.dns_outlined,
            color: isOnline ? const Color(0xFF34D399) : Colors.white54,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            device.ip ?? L10n.t('noIpConfig', lang),
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOnline 
                ? const Color(0xFF10B981).withOpacity(0.15)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOnline 
                  ? const Color(0xFF34D399).withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? const Color(0xFF34D399) : Colors.white54,
                  boxShadow: isOnline ? [
                    BoxShadow(color: const Color(0xFF34D399).withOpacity(0.6), blurRadius: 4)
                  ] : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? L10n.t('online', lang).toUpperCase() : device.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isOnline ? const Color(0xFF34D399) : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
