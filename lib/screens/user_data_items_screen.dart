import 'package:flutter/material.dart';
import 'package:breeze/styles/app_styles.dart';
import 'package:breeze/services/storage.dart';
import 'package:breeze/services/ai_service.dart';

class UserDataItemsScreen extends StatefulWidget {
  const UserDataItemsScreen({final Key? key}) : super(key: key);

  @override
  _UserDataItemsScreenState createState() => _UserDataItemsScreenState();
}

class _UserDataItemsScreenState extends State<UserDataItemsScreen> {
  bool privacyMode = false;

  @override
  void initState() {
    super.initState();
    privacyMode = BreezeStorage().getBool(BreezeStorage.privacyModeKey);
  }

  Future<void> _togglePrivacyMode(final bool value) async {
    setState(() {
      privacyMode = value;
    });
    await BreezeStorage().setBool(BreezeStorage.privacyModeKey, value);
  }

  void _addDataFromText() {
    showDialog(
      context: context,
      builder: (final context) {
        var freeFormText = '';
        var isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (final context, final setState) {
            return AlertDialog(
              title: const Text('Add Free-form Data'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        maxLines: 10,
                        decoration: const InputDecoration(
                          hintText: 'Enter or paste your data here',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (final val) => freeFormText = val,
                      ),
                      const SizedBox(height: 10),
                      if (isLoading) const CircularProgressIndicator(),
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (freeFormText.isNotEmpty) {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      // Send to AI API
                      final aiService = AIService();
                      try {
                        final parsedData =
                            await aiService.parseUserData(freeFormText);
                        await BreezeStorage().updateUserDataItems(parsedData);
                        setState(() {
                          isLoading = false;
                        });
                        Navigator.pop(context);
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                          errorMessage = 'Failed to parse data: $e';
                        });
                      }
                    }
                  },
                  child: const Text('Submit'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editUserDataItem(final String key, final String value) {
    // Allow users to edit values
    showDialog(
      context: context,
      builder: (final context) {
        var newValue = value;
        return AlertDialog(
          title: Text('Edit Value for "$key"'),
          content: TextField(
            decoration: const InputDecoration(labelText: 'Value'),
            onChanged: (final val) => newValue = val,
            controller: TextEditingController(text: value),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await BreezeStorage().setString(key, newValue);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUserDataItem(final String key) async {
    await BreezeStorage().deleteUserDataItem(key);
    setState(() {}); // Refresh the list
  }

  @override
  Widget build(final BuildContext context) {
    final userDataItems = BreezeStorage().userDataItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Data'),
        backgroundColor: AppStyles.primaryColor,
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Privacy Mode'),
            value: privacyMode,
            onChanged: _togglePrivacyMode,
            subtitle: const Text(
                'When enabled, your data is not shared with AI models.'),
          ),
          Expanded(
            child: userDataItems.isEmpty
                ? Center(
                    child: Text(
                      'No data available.',
                      style: AppStyles.bodyTextStyle,
                    ),
                  )
                : ListView.builder(
                    itemCount: userDataItems.length,
                    itemBuilder: (final context, final index) {
                      final key = userDataItems.keys.elementAt(index);
                      final value = userDataItems[key];
                      return ListTile(
                        title: Text(
                          key,
                          style: AppStyles.headingTextStyle,
                        ),
                        subtitle: Text(
                          value!,
                          style: AppStyles.bodyTextStyle,
                        ),
                        onTap: () => _editUserDataItem(key, value),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteUserDataItem(key),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDataFromText,
        backgroundColor: AppStyles.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
