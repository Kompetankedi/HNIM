import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/l10n.dart';

import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _customCatsController = TextEditingController();
  bool _isTesting = false;

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final url = _urlController.text.trim();
    final isSuccess = await apiService.testConnection(url);
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageCode;

    setState(() {
      _isTesting = false;
    });

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.t('connectionSuccess', lang)),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.t('connectionFailed', lang)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Default or current URL loaded from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _urlController.text = settings.serverUrl;
      _customCatsController.text = settings.customCategories.join(', ');
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _customCatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.t('settings', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.t('language', lang),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: lang,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  settings.setLanguage(newValue);
                }
              },
            ),
            const SizedBox(height: 32),
            Text(
              L10n.t('customCategories', lang),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              L10n.t('customCategoriesHint', lang),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customCatsController,
              decoration: InputDecoration(
                labelText: L10n.t('customCategories', lang),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              L10n.t('apiConfig', lang),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              L10n.t('apiHint', lang),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: L10n.t('serverUrl', lang),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.dns),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    child: _isTesting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(L10n.t('testConnection', lang)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      settings.setServerUrl(_urlController.text);
                      
                      final catsInput = _customCatsController.text;
                      final catsList = catsInput.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                      settings.setCustomCategories(catsList);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(L10n.t('settingsSaved', lang))),
                      );
                      // Return true to indicate settings changed and a refresh might be needed
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(L10n.t('saveSettings', lang)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
