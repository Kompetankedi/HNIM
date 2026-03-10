import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/device.dart';
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
      // Reload devices to get updated status from DB
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by Name or IP',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterDevices();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text('Category: '),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: ['All', 'Server', 'Network', 'IoT', 'Mobile', 'Other']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      _selectedCategory = newValue;
                      _filterDevices();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Device>>(
              future: _devicesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _allDevices.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError && _allDevices.isEmpty) {
                  return Center(child: Text('Error loading inventory'));
                } else if (_filteredDevices.isEmpty) {
                  return Center(child: Text('No devices match your search/filter.'));
                }

                return ListView.builder(
                  itemCount: _filteredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _filteredDevices[index];
                    final pingStatus = _pingResults[device.ip];

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: device.status.toLowerCase() == 'online'
                              ? Colors.green
                              : device.status.toLowerCase() == 'offline'
                                  ? Colors.red
                                  : Colors.grey,
                          child: Icon(Icons.memory, color: Colors.white),
                        ),
                        title: Text(device.name),
                        subtitle: Text('${device.ip ?? "No IP"} • ${device.category ?? "Unknown"}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Ping button
                            if (device.ip != null && device.ip!.isNotEmpty)
                              pingStatus == 'checking'
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        Icons.wifi_find,
                                        color: pingStatus == 'online'
                                            ? Colors.green
                                            : pingStatus == 'offline'
                                                ? Colors.red
                                                : Colors.grey,
                                      ),
                                      onPressed: () => _pingDevice(device.ip!),
                                      tooltip: 'Check Status',
                                    ),
                            // Edit button
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => _editDevice(device),
                              tooltip: 'Edit Device',
                            ),
                          ],
                        ),
                        onTap: () => _editDevice(device),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_device').then((_) => _loadDevices());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
