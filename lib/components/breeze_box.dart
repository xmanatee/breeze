import 'package:breeze/models/agent_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breeze/styles/app_styles.dart';

class BreezeBox extends StatelessWidget {
  const BreezeBox({
    final Key? key,
    required this.onUserInput,
    required this.onIntentSubmit,
    required this.onErrorTap,
    required this.onPauseAutomation,
    required this.onResumeAutomation,
  }) : super(key: key);

  final void Function(String) onUserInput;
  final void Function(String) onIntentSubmit;
  final void Function() onErrorTap;
  final void Function() onPauseAutomation;
  final void Function() onResumeAutomation;

  @override
  Widget build(final BuildContext context) {
    final agentState = Provider.of<AgentState>(context);

    return GestureDetector(
      onTap: agentState.isError ? onErrorTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: agentState.isError
              ? AppStyles.pastelYellow
              : AppStyles.primaryColor,
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    agentState.currentAction,
                    style: AppStyles.bodyTextStyle,
                    maxLines: 1, // Prevents text from wrapping
                    overflow: TextOverflow.ellipsis, // Handles overflow
                  ),
                ),
                if (agentState.isAutoAction)
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppStyles.darkGrey),
                        ),
                        IconButton(
                          icon: Icon(Icons.pause,
                              color: AppStyles.darkGrey, size: 20),
                          onPressed: onPauseAutomation,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                if (agentState.isPaused)
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: Icon(Icons.play_arrow,
                          color: AppStyles.darkGrey, size: 20),
                      onPressed: onResumeAutomation,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            if (agentState.isUserIntentInputRequired ||
                agentState.isUserInputRequired)
              TextField(
                onSubmitted: agentState.isUserIntentInputRequired
                    ? onIntentSubmit
                    : onUserInput,
                decoration: InputDecoration(
                  hintText: 'Type here...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }
}
