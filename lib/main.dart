import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:breeze/screens/webview_screen.dart';
import 'package:breeze/styles/app_styles.dart';
import 'package:breeze/models/agent_state.dart';
import 'package:breeze/services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'api_keys.env');
  await BreezeStorage().init();
  runApp(const BreezeBrowserApp());
}

class BreezeBrowserApp extends StatelessWidget {
  const BreezeBrowserApp({final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return ChangeNotifierProvider(
      create: (final _) => AgentState(),
      child: MaterialApp(
        title: 'Breeze Browser',
        theme: AppStyles.appTheme,
        home: const WebviewScreen(),
      ),
    );
  }
}
