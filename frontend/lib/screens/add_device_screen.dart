import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

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
  String _selectedCategory = 'Server';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device added successfully')));
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Device'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
               TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Device Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a device name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ipController,
                decoration: InputDecoration(labelText: 'IP Address (Optional)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
               SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'Category'),
                items: ['Server', 'Network', 'IoT', 'Mobile', 'Other']
                    .map((String value) {
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
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _serialController,
                      decoration: InputDecoration(labelText: 'Serial Number / MAC'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                     onPressed: () async {
                      final scannedData = await Navigator.pushNamed(context, '/qr_scanner');
                      if (scannedData != null && scannedData is String) {
                        setState(() {
                           _serialController.text = scannedData;
                        });
                      }
                    },
                  )
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _detailsController,
                decoration: InputDecoration(labelText: 'Additional Details'),
                maxLines: 3,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting ? CircularProgressIndicator() : Text('Save Device'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
