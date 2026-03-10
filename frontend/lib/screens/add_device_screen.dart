import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/settings_provider.dart';
import 'qr_scanner_screen.dart';

class AddDeviceScreen extends StatefulWidget {
  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _serialController = TextEditingController();
  final _detailsController = TextEditingController();
  
  String? _selectedCategory;
  bool _isSubmitting = false;

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

      final newDeviceData = {
        'name': _nameController.text,
        'ip': _ipController.text,
        'category': _selectedCategory,
        'serialNumber': _serialController.text,
        'details': _detailsController.text,
      };

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.addDevice(newDeviceData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device added successfully')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding device: $e')));
      } finally {
        setState(() {
          _isSubmitting = false;
        });
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
      _selectedCategory = combinedCategories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Device'),
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
                child: _isSubmitting ? const CircularProgressIndicator() : const Text('Save Device'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
