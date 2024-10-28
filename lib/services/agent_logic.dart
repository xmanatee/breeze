import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:breeze/services/ai_service.dart';
import 'package:breeze/models/protocols.dart';
import 'package:breeze/services/web_interaction_helper.dart';
import 'package:breeze/models/agent_state.dart';
import 'package:breeze/services/content_cleaner.dart';
import 'package:breeze/services/storage.dart';

class AgentLogic {
  AgentLogic(this.agentState);

  final AgentState agentState;
  InAppWebViewController? webViewController;
  AIService aiService = AIService();
  BreezeStorage storage = BreezeStorage();
  List<String>? dataKeysNeeded;

  Future<void> processContext() async {
    if (agentState.status == AgentStatus.paused) {
      return;
    }

    agentState.updateStatus(AgentStatus.processing, message: 'Planning...');

    final rawHtmlContent = await webViewController!.evaluateJavascript(
      source: 'document.documentElement.innerHTML;',
    );

    final cleanedContent =
        ContentCleaner.cleanHtmlContent(rawHtmlContent ?? '');

    var userDataInfo = '';
    if (storage.userDataItems.isEmpty) {
      userDataInfo = '- No Available user_data_items';
    } else if (storage.getBool(BreezeStorage.privacyModeKey)) {
      userDataInfo =
          '- Available user_data_item Keys: ${storage.userDataItems.keys.join(',')}';
    } else {
      final allUserData = storage.userDataItems.entries
          .map((final kv) => '${kv.key}=${kv.value}')
          .join(',');
      userDataInfo = '- Available user_data_items: $allUserData';
    }

    final prompt = '''
Task:

1. Analyze the current page content in the context of the user_intent and the intent_fulfillment_state.
2. Determine the best action to take next to fulfill the user's intent.
3. Choose one of the following actions: "idle", "auto", "ask_user_input", "ask_user_action".
4. Provide the necessary details for the chosen action as per the response structure.

Instructions:

- If there is potential ambiguity, ask the user to provide values to use.
- Keep the language concise and to the point. Do not use filler words (e.g., "please") in the response.
- "user_intent" should contain a goal description of what user wants to achieve in this browsing session.
- "user_intent" should be inferred from existing intent and current page (empty string if no intent identified).
- "intent_fulfillment_state" should contain an aggregation of all the steps that were taken until now in order to fulfill the intent.
- **IMPORTANT:** If `user_intent` is empty, the action **must** be "idle".
- **Response must be a valid JSON format as specified without any additional text or explanations.**

- For "idle":
  - Indicate that no action is required at this time and the system is waiting to identify user intent.
  - Should be used as long as user intent is unknown.
  - Example Response:
    {
      "action": "idle",
      "user_intent": "",
      "intent_fulfillment_state": "",
      "details": {}
    }

- For "auto":
  - Provide a list of actions to be performed on the current page to fulfill user's intent.
  - Each action should include:
    - "action_identifier": "fill", "click", or "press".
    - "action_description": Short description (1-2 words).
    - "selector": CSS selector of the element to interact with.
    - "dataKey": For "fill" actions, the corresponding user_data_item key to use to fill the form (must be present in user_data_item)
    - "dataValue": For "fill" actions, literal value to fill into the field (exactly one of "dataKey" or "dataValue" must be set)
    - "verify_condition": JavaScript expression that evaluates to true when the action is successful.
  - The list should end with an action that progresses navigation to the next stage.
  - Example Response:
    {
      "action": "auto",
      "user_intent": "Book flight",
      "intent_fulfillment_state": "Registered on the booking website. Selected flight destination.",
      "details": [
        {
          "action_identifier": "fill",
          "action_description": "Filling destination",
          "selector": "#destination",
          "dataKey": "flight_destination",
          "verify_condition": "document.querySelector('#destination').value !== ''"
        },
        {
          "action_identifier": "click",
          "action_description": "Submitting Form",
          "selector": "#submit",
          "verify_condition": "window.location.href.includes('confirmation')"
        }
      ]
    }

- For "ask_user_input":
  - In "prompt" request specific information from the user.
  - Specify the "data_keys_needed" to update user_data_items.
  - Only use when it is needed to fill in a form and is missing from user_data_items.
  - Example Response:
    {
      "action": "ask_user_input",
      "user_intent": "Book flight",
      "intent_fulfillment_state": "Registered on the booking website. Awaiting flight destination from user.",
      "details": {
        "prompt": "Where are you flying?",
        "data_keys_needed": ["flight_destination"]
      }
    }

- For "ask_user_action":
  - In "instruction" provide clear instructions for the user to perform on the page.
  - Optionally include a "condition_for_resume" that can be evaluated in JavaScript to determine when the user has completed the action.
  - Optionally include a "selector" to be highlighted to user.
  - Only use when it is actually needed to progress.
  - Example Response:
    {
      "action": "ask_user_action",
      "user_intent": "Book flight",
      "intent_fulfillment_state": "Booked a flight. Awaiting final confirmation from user through payment.",
      "details": {
        "instruction": "Confirm your flight booking.",
        "selector": "#pay_button",
        "condition_for_resume": "document.querySelector('.confirmation-button') !== null"
      }
    }

- Output format:
{
  "action": "idle" | "auto" | "ask_user_input" | "ask_user_action",
  "user_intent": "<updated_user_intent>",
  "intent_fulfillment_state": "<updated_intent_fulfillment_state>",
  "details": { ... }
}

Data:
- Current user_intent: "${agentState.userIntent}"
- Current intent_fulfillment_state: "${agentState.intentFulfillmentState}"
$userDataInfo
- Current Page Content: "$cleanedContent"
''';

    try {
      final aiResponse = await aiService.getChatCompletion(prompt: prompt);
      _handleAIResponse(aiResponse);
    } catch (e) {
      agentState.updateStatus(AgentStatus.error,
          message: 'Failed to get valid AI response. $e');
      throw Exception('Failed to get valid AI response from AI service. $e');
    }
  }

  void _handleAIResponse(final AIResponse aiResponse) {
    agentState.setUserIntent(aiResponse.userIntent);
    agentState.setIntentFulfillmentState(aiResponse.intentFulfillmentState);
    switch (aiResponse.action) {
      case 'idle':
        agentState.handleIdle();
        break;
      case 'auto':
        final details = aiResponse.details as AutoActionDetails;
        _performAutoActions(details.actions);
        break;
      case 'ask_user_input':
        final details = aiResponse.details as AskUserInputDetails;
        dataKeysNeeded = details.dataKeysNeeded;
        agentState.handleUserInputRequired(
          details.prompt,
          dataKeysNeeded: dataKeysNeeded,
        );
        break;
      case 'ask_user_action':
        final details = aiResponse.details as AskUserActionDetails;
        _handleUserAction(
          details.instruction,
          details.conditionForResume,
        );
        break;
      default:
        throw Exception('Unsupported action type: ${aiResponse.action}');
    }
  }

  Future<void> _performAutoActions(final List<AutomationStep> actions) async {
    if (webViewController == null) {
      throw Exception('WebViewController is not initialized.');
    }

    final webInteractionHelper = WebInteractionHelper(webViewController!);
    agentState.updateStatus(AgentStatus.automating,
        message: 'Automating actions...', isAuto: true);

    for (var action in actions) {
      if (agentState.status == AgentStatus.paused) {
        agentState.updateStatus(AgentStatus.paused, message: 'Paused.');
        return;
      }

      agentState.updateStatus(AgentStatus.automating,
          message: action.description, isAuto: true);
      await webInteractionHelper.scrollIntoView(action.selector);
      await webInteractionHelper.highlightElement(action.selector);

      await Future.delayed(Duration(
        milliseconds:
            (storage.getDouble(BreezeStorage.actionDelayKey) * 1000).toInt(),
      ));

      try {
        switch (action.actionIdentifier) {
          case 'fill':
            final value = action.fillDataKey != null
                ? storage.userDataItems[action.fillDataKey]!
                : action.fillDataValue!;
            await webInteractionHelper.focus(action.selector);
            await webInteractionHelper.type(action.selector, value);
            break;
          case 'click':
            await webInteractionHelper.click(action.selector);
            break;
          case 'hover':
            await webInteractionHelper.hover(action.selector);
            break;
          default:
            agentState.updateStatus(
              AgentStatus.error,
              message: 'Unknown action: ${action.actionIdentifier}',
            );
            throw Exception(
                'Unknown action identifier: ${action.actionIdentifier}');
        }
        final actionSuccess =
            await _verifyActionSuccess(action.verifyCondition);
        await webInteractionHelper.removeHighlight(action.selector);

        if (!actionSuccess) {
          await _handleUserAction(
            'Perform "${action.description}" on the page.',
            action.verifyCondition,
            selector: action.selector,
          );
          return;
        }
      } catch (e) {
        agentState.updateStatus(
          AgentStatus.error,
          message: 'Error during action ${action.actionIdentifier}: $e',
        );
        await webInteractionHelper.removeHighlight(action.selector);
        rethrow;
      }
    }

    while (await webViewController!.isLoading()) {
      await Future.delayed(const Duration(seconds: 1));
    }

    await processContext();
  }

  Future<bool> _verifyActionSuccess(final String verifyCondition) async {
    if (verifyCondition.isEmpty) {
      return true;
    }

    final result = await webViewController!.evaluateJavascript(
      source: '''
      (function() {
        return $verifyCondition;
      })();
      ''',
    );

    return result == true || result == 'true';
  }

  Future<void> _handleUserAction(
    final String instruction,
    final String conditionForResume, {
    final String? selector,
  }) async {
    final webInteractionHelper = WebInteractionHelper(webViewController!);
    if (selector != null) {
      await webInteractionHelper.scrollIntoView(selector);
      await webInteractionHelper.highlightElement(selector);
    }

    agentState.handleUserActionRequired(instruction);
    final conditionMet = await _monitorCondition(conditionForResume);
    if (selector != null) {
      await webInteractionHelper.removeHighlight(selector);
    }

    if (conditionMet) {
      await processContext();
    }
    agentState.updateStatus(
      AgentStatus.error,
      message: 'Action not completed by user.',
    );
  }

  Future<bool> _monitorCondition(final String condition) async {
    var retries = 0;
    const maxRetries = 30;

    while (retries < maxRetries) {
      await Future.delayed(const Duration(seconds: 1));
      retries++;

      final result = await webViewController!.evaluateJavascript(
        source: '''
        (function() {
          return $condition;
        })();
        ''',
      );

      if (result == true || result == 'true') {
        return true;
      }
    }

    return false;
  }

  Future<void> provideUserInput(final String input) async {
    try {
      final parsedData = await aiService.parseUserData(input);
      await storage.updateUserDataItems(parsedData);
      agentState.updateStatus(
        AgentStatus.automating,
        message: 'User input processed.',
        isAuto: true,
      );
      await processContext();
    } catch (e) {
      agentState.updateStatus(
        AgentStatus.error,
        message: 'Error parsing input: $e',
      );
    }
  }

  void pauseAutomation() {
    agentState.pauseAutomation();
  }

  void resumeAutomation() {
    agentState.resumeAutomation();
    processContext();
  }
}
