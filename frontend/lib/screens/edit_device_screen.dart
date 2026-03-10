import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/device.dart';
import '../providers/settings_provider.dart';
import 'qr_scanner_screen.dart';

class EditDeviceScreen extends StatefulWidget {
  final Device device;

  const EditDeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  _EditDeviceScreenState createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends State<EditDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ipController;
  late TextEditingController _serialController;
  late TextEditingController _detailsController;
  
  String? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _ipController = TextEditingController(text: widget.device.ip ?? '');
    _serialController = TextEditingController(text: widget.device.serialNumber ?? '');
    _detailsController = TextEditingController(text: widget.device.details ?? '');
    _selectedCategory = widget.device.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _serialController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
        return;
      }
      
      setState(() {
        _isSubmitting = true;
      });

      final updatedData = {
        'name': _nameController.text,
        'ip': _ipController.text,
        'category': _selectedCategory,
        'serialNumber': _serialController.text,
        'details': _detailsController.text,
      };

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.updateDevice(widget.device.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device updated successfully')),
        );
        Navigator.pop(context, true); // Return true to signal a refresh
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating device: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete "${widget.device.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.deleteDevice(widget.device.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device deleted')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting device: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> combinedCategories = ['Server', 'Network', 'IoT', 'Mobile', 'Laptop', 'Phone', 'Router/Modem', 'Other'];
    final customCategories = Provider.of<SettingsProvider>(context).customCategories;
    
    // Add custom categories that aren't already in the list
    for (String cat in customCategories) {
      if (!combinedCategories.contains(cat)) {
        combinedCategories.add(cat);
      }
    }

    if (_selectedCategory == null || !combinedCategories.contains(_selectedCategory)) {
      // Set to first if previous category is removed or missing
      _selectedCategory = combinedCategories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteDevice,
            tooltip: 'Delete Device',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Device Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a device name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ipController,
                decoration: const InputDecoration(labelText: 'IP Address (Optional)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: combinedCategories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _serialController,
                      decoration: const InputDecoration(labelText: 'Serial Number / MAC'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                     onPressed: () async {
                      final scannedData = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QRScannerScreen()),
                      );
                      if (scannedData != null && scannedData is String) {
                        setState(() {
                           _serialController.text = scannedData;
                        });
                      }
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(labelText: 'Additional Details'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting ? const CircularProgressIndicator() : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
