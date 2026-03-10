import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/device.dart';

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
  late String _selectedCategory;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _ipController = TextEditingController(text: widget.device.ip ?? '');
    _serialController = TextEditingController(text: widget.device.serialNumber ?? '');
    _detailsController = TextEditingController(text: widget.device.details ?? '');
    _selectedCategory = widget.device.category ?? 'Server';
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
          SnackBar(content: Text('Device updated successfully')),
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
        title: Text('Delete Device'),
        content: Text('Are you sure you want to delete "${widget.device.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.deleteDevice(widget.device.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device deleted')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Device'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
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
              TextFormField(
                controller: _serialController,
                decoration: InputDecoration(labelText: 'Serial Number / MAC'),
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
                child: _isSubmitting ? CircularProgressIndicator() : Text('Save Changes'),
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
