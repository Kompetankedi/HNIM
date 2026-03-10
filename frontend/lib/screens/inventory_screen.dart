import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/device.dart';
import '../providers/settings_provider.dart';
import '../utils/l10n.dart';
import 'edit_device_screen.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<Device>> _devicesFuture;
  List<Device> _allDevices = [];
  List<Device> _filteredDevices = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Map<String, String> _pingResults = {}; // IP -> status

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    _devicesFuture = apiService.getDevices().then((devices) {
      setState(() {
        _allDevices = devices;
        _filterDevices();
      });
      return devices;
    });
  }

  void _filterDevices() {
    setState(() {
      _filteredDevices = _allDevices.where((device) {
        final matchesSearch = device.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (device.ip?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        // Translate "All" properly later if needed, conceptually keep internal state as 'All'
        final matchesCategory = _selectedCategory == 'All' || device.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _pingDevice(String ip) async {
    setState(() {
      _pingResults[ip] = 'checking';
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.checkDeviceStatus(ip);
      setState(() {
        _pingResults[ip] = result['status'];
      });
      _loadDevices();
    } catch (e) {
      setState(() {
        _pingResults[ip] = 'error';
      });
    }
  }

  void _editDevice(Device device) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditDeviceScreen(device: device)),
    );
    if (result == true) {
      _loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageCode;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(L10n.t('inventory', lang)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadDevices,
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
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: L10n.t('searchHint', lang),
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterDevices();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Row(
                  children: [
                    Text(L10n.t('category', lang), style: const TextStyle(color: Colors.white70)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                            isExpanded: true,
                            items: () {
                              List<String> combinedCategories = ['All', 'Server', 'Network', 'IoT', 'Mobile', 'Laptop', 'Phone', 'Router/Modem', 'Other'];
                              final customCategories = Provider.of<SettingsProvider>(context).customCategories;
                              for (String cat in customCategories) {
                                if (!combinedCategories.contains(cat)) {
                                  combinedCategories.add(cat);
                                }
                              }
                              
                              return combinedCategories.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value == 'All' ? L10n.t('all', lang) : 
                                    value == 'Server' ? L10n.t('server', lang) : 
                                    value == 'Network' ? L10n.t('network', lang) :
                                    value == 'IoT' ? L10n.t('iot', lang) :
                                    value == 'Mobile' ? L10n.t('mobile', lang) : 
                                    value == 'Laptop' ? L10n.t('laptop', lang) :
                                    value == 'Phone' ? L10n.t('phone', lang) :
                                    value == 'Router/Modem' ? L10n.t('router', lang) :
                                    value == 'Other' ? L10n.t('other', lang) : 
                                    value, // fallback for custom categories
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList();
                            }(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                _selectedCategory = newValue;
                                _filterDevices();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Device>>(
                  future: _devicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && _allDevices.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError && _allDevices.isEmpty) {
                      return Center(child: Text(L10n.t('errorLoading', lang), style: const TextStyle(color: Colors.redAccent)));
                    } else if (_filteredDevices.isEmpty) {
                      return Center(child: Text(L10n.t('noDevicesMatch', lang), style: const TextStyle(color: Colors.white54)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredDevices.length,
                      itemBuilder: (context, index) {
                        final device = _filteredDevices[index];
                        final pingStatus = _pingResults[device.ip];
                        final isOnline = device.status.toLowerCase() == 'online';

                        // Derive display category with localization
                        String displayCategory = device.category ?? L10n.t('unknown', lang);
                        if (displayCategory == 'Server') displayCategory = L10n.t('server', lang);
                        if (displayCategory == 'Network') displayCategory = L10n.t('network', lang);
                        if (displayCategory == 'IoT') displayCategory = L10n.t('iot', lang);
                        if (displayCategory == 'Mobile') displayCategory = L10n.t('mobile', lang);
                        if (displayCategory == 'Other') displayCategory = L10n.t('other', lang);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.03), width: 1),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _editDevice(device),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isOnline 
                                          ? const Color(0xFF10B981).withOpacity(0.1) 
                                          : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.memory,
                                      color: isOnline ? const Color(0xFF34D399) : Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          device.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${device.ip ?? L10n.t('noIpConfig', lang)} • $displayCategory',
                                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (device.ip != null && device.ip!.isNotEmpty)
                                    pingStatus == 'checking'
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : IconButton(
                                            icon: Icon(
                                              Icons.wifi_find,
                                              color: pingStatus == 'online'
                                                  ? const Color(0xFF34D399)
                                                  : pingStatus == 'offline'
                                                      ? Colors.redAccent
                                                      : Colors.white54,
                                            ),
                                            onPressed: () => _pingDevice(device.ip!),
                                            tooltip: 'Check Status',
                                          ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.white54),
                                    onPressed: () => _editDevice(device),
                                    tooltip: 'Edit Device',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
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
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/add_device').then((_) => _loadDevices());
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
