import 'package:flutter/foundation.dart';

enum AgentStatus {
  idle,
  processing,
  waitingForUserInput,
  waitingForUserAction,
  error,
  automating,
  paused,
}

class AgentState extends ChangeNotifier {
  AgentStatus status = AgentStatus.idle;
  AgentStatus? _previousStatus;
  String currentAction = 'How can I help?';
  String errorMessage = '';
  String userInputPrompt = '';
  String userActionPrompt = '';
  String? userIntent;
  String intentFulfillmentState = '';

  bool get isUserIntentInputRequired => status == AgentStatus.idle;
  bool get isUserInputRequired => status == AgentStatus.waitingForUserInput;
  bool get isUserActionRequired => status == AgentStatus.waitingForUserAction;
  bool get isAutoAction => status == AgentStatus.automating;
  bool get isPaused => status == AgentStatus.paused;
  bool get isError => status == AgentStatus.error;

  void updateStatus(final AgentStatus newStatus,
      {final String message = '', final bool isAuto = false}) {
    debugPrint('AgentState: Transitioning to $newStatus state.');

    status = newStatus;
    currentAction =
        message.isNotEmpty ? message : _defaultMessageForStatus(newStatus);
    notifyListeners();
  }

  String _defaultMessageForStatus(final AgentStatus status) {
    switch (status) {
      case AgentStatus.idle:
        return 'How can I help?';
      case AgentStatus.processing:
        return 'Processing...';
      case AgentStatus.automating:
        return 'Automating actions...';
      case AgentStatus.waitingForUserInput:
        return userInputPrompt;
      case AgentStatus.waitingForUserAction:
        return userActionPrompt;
      case AgentStatus.error:
        return errorMessage;
      case AgentStatus.paused:
        return 'Paused.';
      default:
        throw Exception('Unknown status: $status');
    }
  }

  void handleIdle() {
    updateStatus(AgentStatus.idle);
  }

  void handleUserInputRequired(final String prompt,
      {final List<String>? dataKeysNeeded}) {
    userInputPrompt = prompt;
    updateStatus(AgentStatus.waitingForUserInput);
  }

  void handleUserActionRequired(final String prompt) {
    userActionPrompt = prompt;
    updateStatus(AgentStatus.waitingForUserAction);
  }

  void handleError(final String message) {
    errorMessage = message;
    updateStatus(AgentStatus.error);
  }

  void setUserIntent(final String intent) {
    userIntent = intent;
    updateStatus(AgentStatus.processing);
  }

  void setIntentFulfillmentState(final String state) {
    intentFulfillmentState = state;
    notifyListeners();
  }

  void pauseAutomation() {
    if (status != AgentStatus.paused) {
      _previousStatus = status;
      updateStatus(AgentStatus.paused);
    }
  }

  void resumeAutomation() {
    if (status == AgentStatus.paused) {
      status = _previousStatus!;
      _previousStatus = null;
      currentAction = _defaultMessageForStatus(status);
      notifyListeners();
    }
  }

  void reset() {
    status = AgentStatus.idle;
    _previousStatus = null;
    currentAction = 'How can I help?';
    errorMessage = '';
    userInputPrompt = '';
    userActionPrompt = '';
    userIntent = '';
    intentFulfillmentState = '';
    notifyListeners();
  }
}
