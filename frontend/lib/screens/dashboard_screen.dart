import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/device.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Device>> _devicesFuture;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _devicesFuture = apiService.getDevices();
  }

  Future<void> _refresh() async {
    setState(() {
       final apiService = Provider.of<ApiService>(context, listen: false);
      _devicesFuture = apiService.getDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HNIM Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Device>>(
          future: _devicesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    SizedBox(height: 16),
                    Text('Failed to load devices.\nCheck settings and server connection.', textAlign: TextAlign.center),
                    ElevatedButton(onPressed: _refresh, child: Text('Retry'))
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No devices found in inventory.'));
            }

            final devices = snapshot.data!;
            final onlineCount = devices.where((d) => d.status.toLowerCase() == 'online').length;
            final offlineCount = devices.length - onlineCount; // Simplify for now

            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Network Summary', style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Devices',
                          value: '${devices.length}',
                          icon: Icons.computer,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Online',
                          value: '$onlineCount',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Text('Recent Additions', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  // List the top 5 most recently added devices
                  ...devices.take(5).map((device) => ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.devices_other),
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        title: Text(device.name),
                        subtitle: Text(device.ip ?? 'No IP'),
                        trailing: Text(
                          device.status,
                          style: TextStyle(
                            color: device.status.toLowerCase() == 'online' ? Colors.green : Colors.grey,
                          ),
                        ),
                      )).toList(),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_device').then((_) => _refresh());
        },
        child: Icon(Icons.add),
        tooltip: 'Add Device',
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
