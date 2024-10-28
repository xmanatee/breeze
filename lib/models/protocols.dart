class AIResponse {
  AIResponse({
    required this.action,
    required this.userIntent,
    required this.intentFulfillmentState,
    required this.details,
  });

  factory AIResponse.fromJson(final Map<String, dynamic> json) {
    if (!json.containsKey('action') || !json.containsKey('details')) {
      throw Exception('Invalid AI response structure.');
    }

    AIResponseDetails details;
    switch (json['action']) {
      case 'idle':
        details = IdleActionDetails.fromJson(json['details']);
        break;
      case 'auto':
        details = AutoActionDetails.fromJson(json['details']);
        break;
      case 'ask_user_input':
        details = AskUserInputDetails.fromJson(json['details']);
        break;
      case 'ask_user_action':
        details = AskUserActionDetails.fromJson(json['details']);
        break;
      default:
        throw Exception('Unknown action type: ${json['action']}');
    }

    return AIResponse(
      action: json['action'],
      userIntent: json['user_intent'],
      intentFulfillmentState: json['intent_fulfillment_state'],
      details: details,
    );
  }

  final String action;
  final String userIntent;
  final String intentFulfillmentState;
  final AIResponseDetails details;
}

abstract class AIResponseDetails {}

class IdleActionDetails extends AIResponseDetails {
  IdleActionDetails();

  factory IdleActionDetails.fromJson(final dynamic json) {
    return IdleActionDetails();
  }
}

class AutoActionDetails extends AIResponseDetails {
  AutoActionDetails({required this.actions});

  factory AutoActionDetails.fromJson(final List<dynamic> json) {
    return AutoActionDetails(
      actions: json.map((final e) => AutomationStep.fromJson(e)).toList(),
    );
  }
  final List<AutomationStep> actions;
}

class AskUserInputDetails extends AIResponseDetails {
  AskUserInputDetails({required this.prompt, required this.dataKeysNeeded});

  factory AskUserInputDetails.fromJson(final Map<String, dynamic> json) {
    return AskUserInputDetails(
      prompt: json['prompt'] ?? '',
      dataKeysNeeded: List<String>.from(json['data_keys_needed'] ?? []),
    );
  }
  final String prompt;
  final List<String> dataKeysNeeded;
}

class AskUserActionDetails extends AIResponseDetails {
  AskUserActionDetails({
    required this.instruction,
    required this.conditionForResume,
  });

  factory AskUserActionDetails.fromJson(final Map<String, dynamic> json) {
    return AskUserActionDetails(
      instruction: json['instruction'] ?? '',
      conditionForResume: json['condition_for_resume'] ?? '',
    );
  }
  final String instruction;
  final String conditionForResume;
}

class AutomationStep {
  AutomationStep({
    required this.actionIdentifier,
    required this.selector,
    required this.description,
    required this.verifyCondition,
    this.fillDataKey,
    this.fillDataValue,
  });

  factory AutomationStep.fromJson(final Map<String, dynamic> json) {
    return AutomationStep(
      actionIdentifier: json['action_identifier']!,
      selector: json['selector']!,
      description: json['action_description']!,
      verifyCondition: json['verify_condition']!,
      fillDataKey: json['dataKey'],
      fillDataValue: json['dataValue'],
    );
  }
  final String actionIdentifier;
  final String selector;
  final String description;
  final String verifyCondition;
  final String? fillDataKey;
  final String? fillDataValue;
}
