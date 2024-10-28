import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:breeze/components/breeze_box.dart';
import 'package:breeze/services/agent_logic.dart';
import 'package:breeze/models/agent_state.dart';
import 'package:breeze/styles/app_styles.dart';
import 'package:breeze/screens/settings_screen.dart';
import 'package:breeze/services/storage.dart';

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({final Key? key}) : super(key: key);

  @override
  _WebviewScreenState createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  InAppWebViewController? webViewController;
  AgentState? agentState;
  AgentLogic? agentLogic;
  bool isOverlayVisible = false;
  String? currentUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (agentState == null) {
      agentState = Provider.of<AgentState>(context);
      agentLogic = AgentLogic(agentState!);
      agentLogic!.webViewController = webViewController;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> loadInitialPage() async {
    String searchUrl;

    switch (BreezeStorage().getString(BreezeStorage.searchEngineKey)) {
      case 'Google':
        searchUrl = 'https://www.google.com';
        break;
      case 'Yandex':
        searchUrl = 'https://www.yandex.com';
        break;
      case 'Google Dev':
        searchUrl = 'https://developers.google.com/web/';
        break;
      default:
        searchUrl = 'https://duckduckgo.com';
    }

    setState(() {
      currentUrl = searchUrl;
    });

    await webViewController!.loadUrl(
      urlRequest: URLRequest(url: WebUri(searchUrl)),
    );
  }

  void _toggleOverlay() {
    setState(() {
      isOverlayVisible = !isOverlayVisible;
    });
  }

  Future<void> handleReBreeze() async {
    Provider.of<AgentState>(context, listen: false).reset();
    await loadInitialPage();
  }

  Future<void> handleSearchEngineChanged() async {
    final agentState = Provider.of<AgentState>(context, listen: false);
    if (agentState.status == AgentStatus.idle) {
      await loadInitialPage();
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri('about:blank')),
              initialSettings: InAppWebViewSettings(
                incognito: true,
                javaScriptCanOpenWindowsAutomatically: true,
              ),
              onWebViewCreated: (final controller) {
                webViewController = controller;
                agentLogic!.webViewController = controller;
                loadInitialPage();
              },
              onLoadStop: (final controller, final url) async {
                if (currentUrl != url.toString()) {
                  setState(() {
                    currentUrl = url.toString();
                  });
                  await agentLogic!.processContext();
                }
              },
              onConsoleMessage: (final controller, final consoleMessage) {
                if (consoleMessage.messageLevel ==
                        ConsoleMessageLevel.WARNING ||
                    consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
                  debugPrint(
                      'WebView console message: ${consoleMessage.messageLevel}: ${consoleMessage.message}');
                }
              },
            ),
            // Overlay
            if (isOverlayVisible)
              GestureDetector(
                onTap: () {
                  _toggleOverlay();
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            // Positioned B Button and Breeze Communication Box
            Positioned(
              bottom: 16,
              left: isOverlayVisible || agentState!.status != AgentStatus.idle
                  ? 16
                  : null,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // B Button
                  GestureDetector(
                    onTap: _toggleOverlay,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppStyles.darkGrey,
                        borderRadius:
                            BorderRadius.circular(AppStyles.borderRadius),
                        border: Border.all(
                          color: AppStyles.primaryColor,
                          width: 2.0,
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/icon.png',
                          width: 38,
                          height: 38,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Breeze Communication Box
                  if (isOverlayVisible ||
                      agentState!.status != AgentStatus.idle)
                    Expanded(
                      child: BreezeBox(
                        onErrorTap: () {
                          showDialog(
                            context: context,
                            builder: (final context) => AlertDialog(
                              title: const Text('Error Details'),
                              content: Text(agentState!.errorMessage),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        onUserInput: (final input) async {
                          await agentLogic!.provideUserInput(input);
                        },
                        onIntentSubmit: (final intent) {
                          setState(() {
                            isOverlayVisible = false;
                          });
                          agentState!.setUserIntent(intent);
                          agentLogic!.processContext();
                        },
                        onPauseAutomation: () => agentLogic!.pauseAutomation(),
                        onResumeAutomation: () =>
                            agentLogic!.resumeAutomation(),
                      ),
                    ),
                ],
              ),
            ),
            // Settings Button (Top Right)
            if (isOverlayVisible)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (final context) => SettingsScreen(
                          onReBreeze: handleReBreeze,
                          onSearchEngineChanged: handleSearchEngineChanged,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppStyles.darkGrey,
                      borderRadius:
                          BorderRadius.circular(AppStyles.borderRadius),
                      border: Border.all(
                        color: AppStyles.primaryColor,
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.settings,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
