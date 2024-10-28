import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:breeze/styles/app_styles.dart';
import 'package:breeze/screens/user_data_items_screen.dart';
import 'package:breeze/services/storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    final Key? key,
    required this.onReBreeze,
    required this.onSearchEngineChanged,
  }) : super(key: key);
  final VoidCallback onReBreeze;
  final VoidCallback onSearchEngineChanged;

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool simplifiedView = false;
  late String aiBackend;
  late String aiModel;
  final Map<String, List<String>> aiBackendsWithModels = {
    'OpenAI': [
      'gpt-3.5-turbo',
      'gpt-4o',
      'gpt-4o-mini',
      'o1-preview',
      'o1-mini',
      'gpt-4-turbo'
    ],
    'Anthropic': [
      'claude-3-5-sonnet-latest',
      'claude-3-opus-latest',
    ],
    'Nebius AI': ['meta-llama/Meta-Llama-3.1-70B-Instruct'],
  };
  late List<String> availableModels;
  late double actionDelay;
  late String searchEngine;
  final List<String> searchEngines = [
    'DuckDuckGo',
    'Google',
    'Yandex',
    'Google Dev',
  ];

  bool searchEngineChanged = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      aiBackend = BreezeStorage().getString(BreezeStorage.aiBackendKey);
      aiModel = BreezeStorage().getString(BreezeStorage.aiModelKey);
      availableModels = aiBackendsWithModels[aiBackend] ?? [];
      actionDelay = BreezeStorage().getDouble(BreezeStorage.actionDelayKey);
      searchEngine = BreezeStorage().getString(BreezeStorage.searchEngineKey);
    });
  }

  void _resetContext() {
    widget.onReBreeze();
    Navigator.pop(context);
  }

  bool _hasApiKey(final String backend) {
    switch (backend) {
      case 'OpenAI':
        return dotenv.env['OPENAI_API_KEY'] != null &&
            dotenv.env['OPENAI_API_KEY']!.isNotEmpty;
      case 'Anthropic':
        return dotenv.env['ANTHROPIC_API_KEY'] != null &&
            dotenv.env['ANTHROPIC_API_KEY']!.isNotEmpty;
      case 'Nebius AI':
        return dotenv.env['NEBIUS_API_KEY'] != null &&
            dotenv.env['NEBIUS_API_KEY']!.isNotEmpty;
      default:
        return false;
    }
  }

  void _onSearchEngineChanged(final String? value) {
    setState(() {
      searchEngine = value!;
      searchEngineChanged = true;
    });
    unawaited(BreezeStorage().setString(BreezeStorage.searchEngineKey, value!));
    widget.onSearchEngineChanged();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breeze Browser'),
        backgroundColor: AppStyles.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: _resetContext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              ),
            ),
            child: const Text('ReBreeze'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('AI Backend'),
            subtitle: DropdownButtonFormField<String>(
              value: aiBackend,
              items: aiBackendsWithModels.keys.map((final backend) {
                final hasKey = _hasApiKey(backend);
                return DropdownMenuItem(
                  value: backend,
                  enabled: hasKey,
                  child: Text(
                    hasKey ? backend : '$backend (API Key Missing)',
                    style: TextStyle(
                      color: hasKey ? Colors.black : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (final value) {
                if (_hasApiKey(value!)) {
                  setState(() {
                    aiBackend = value;
                    availableModels = aiBackendsWithModels[aiBackend] ?? [];
                    aiModel = availableModels.first;
                  });
                  BreezeStorage().setString(BreezeStorage.aiBackendKey, value);
                  BreezeStorage().setString(BreezeStorage.aiModelKey, aiModel);
                }
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ListTile(
            title: const Text('AI Model'),
            subtitle: DropdownButtonFormField<String>(
              value: aiModel,
              items: availableModels.map((final model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              onChanged: (final value) {
                setState(() {
                  aiModel = value!;
                });
                BreezeStorage().setString(BreezeStorage.aiModelKey, value!);
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ListTile(
            title: const Text('Default Search Engine'),
            subtitle: DropdownButtonFormField<String>(
              value: searchEngine,
              items: searchEngines
                  .map((final engine) => DropdownMenuItem(
                        value: engine,
                        child: Text(engine),
                      ))
                  .toList(),
              onChanged: _onSearchEngineChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ListTile(
            title: const Text('Action Delay (seconds)'),
            subtitle: Slider(
              value: actionDelay,
              min: 0.5,
              max: 10.0,
              divisions: 95, // (10.0 - 0.5) / 0.1
              label: '${actionDelay.toStringAsFixed(1)} s',
              onChanged: (final double value) async {
                setState(() {
                  actionDelay = value;
                });
                await BreezeStorage()
                    .setDouble(BreezeStorage.actionDelayKey, value);
              },
            ),
          ),
          ListTile(
            title: const Text('Personal Data'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (final context) => const UserDataItemsScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          // Spacer to push the footer to the bottom
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: RichText(
              text: TextSpan(
                text: 'Brought to you by ',
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: 'nemi.love',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        const url = 'https://nemi.love';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
