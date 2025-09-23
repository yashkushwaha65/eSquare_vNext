// lib/screens/pre_gate_in_screen.dart
import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../core/models/surveyMdl.dart';
import 'tabs/container_tab.dart';
import 'tabs/photos_tab.dart';
import 'tabs/survey_tab.dart';
import 'tabs/transporter_tab.dart';

class PreGateInScreen extends StatefulWidget {
  final Function(Survey)? onSave;
  final VoidCallback? onBack;
  final Survey? editingSurvey;

  const PreGateInScreen({
    super.key,
    this.onSave,
    this.onBack,
    this.editingSurvey,
  });

  @override
  State<PreGateInScreen> createState() => _PreGateInScreenState();
}

class _PreGateInScreenState extends State<PreGateInScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Use a post-frame callback to safely access the provider and fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PreGateInProvider>(context, listen: false);

      // Explicitly trigger the data fetch when the screen is ready
      provider.fetchDropdowns();

      // Move listener setup here as well
      provider.grossWtController.addListener(provider.calculatePayload);
      provider.tareWtController.addListener(provider.calculatePayload);
      provider.containerNoController.addListener(() {
        provider.validateContainer(provider.containerNoController.text);
      });

      if (widget.editingSurvey != null) {
        provider.loadFromSurvey(widget.editingSurvey!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreGateInProvider>(context);

    return PopScope<bool>(
      onPopInvokedWithResult: (didPop, result) {
        final provider = Provider.of<PreGateInProvider>(context, listen: false);
        provider.resetFields();
      },

      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pre-Gate In Survey'),
          actions: [
            TextButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      provider.hasValidatedShippingLine = true;
                      if (provider.validateForm()) {
                        final success = await provider.saveSurvey(context);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Survey saved successfully ✅"),
                            ),
                          );

                          Navigator.pop(
                            context,
                            true,
                          ); // Navigate back to dashboard
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to save survey."),
                            ),
                          );
                        }
                      } else {
                        final errorMessages = provider.errors.values.join('\n');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              errorMessages.isEmpty
                                  ? 'Please fix form errors.'
                                  : errorMessages,
                            ),
                          ),
                        );
                      }
                    },

              child: provider.isLoading
                  ? Lottie.asset('assets/anims/loading.json')
                  : const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),

        body: provider.isDropdownsLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading survey data...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : _buildFormTabs(),
      ),
    );
  }

  // Helper method to build the main form content
  Widget _buildFormTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'CONTAINER'),
            Tab(text: 'TRANSPORTER'),
            Tab(text: 'SURVEY'),
            Tab(text: 'PHOTOS'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ContainerTab(),
              TransporterTab(),
              SurveyTab(),
              PhotosTab(),
            ],
          ),
        ),
      ],
    );
  }
}
