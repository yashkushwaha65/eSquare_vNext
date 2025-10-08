// lib/screens/pre_survey/pre_gate_in_screen.dart
import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:esquare/widgets/caution_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
  late PreGateInProvider _provider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _provider = Provider.of<PreGateInProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _provider.fetchDropdowns();

      if (widget.editingSurvey != null) {
        _provider.loadFromSurvey(widget.editingSurvey!);
      }

      _provider.grossWtController.addListener(_provider.calculatePayload);
      _provider.tareWtController.addListener(_provider.calculatePayload);
    });
  }

  @override
  void dispose() {
    _provider.grossWtController.removeListener(_provider.calculatePayload);
    _provider.tareWtController.removeListener(_provider.calculatePayload);
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Exit Survey?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Are you sure you want to exit? Any unsaved progress will be permanently lost.',
            style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Exit',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldPop ?? false) {
      // MODIFICATION: Call resetFields without notifying listeners to prevent race condition.
      Provider.of<PreGateInProvider>(
        context,
        listen: false,
      ).resetFields(notify: false);
      return true;
    }
    return false;
  }

  String _getErrorMessage(Map<String, String> errors) {
    if (errors.isEmpty) {
      return 'Please review and correct all form fields before submitting.';
    }
    return 'The following fields require your attention:\n\n${errors.values.map((e) => '• $e').join('\n')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreGateInProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _onWillPop().then((shouldPop) {
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        });
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF1565C0),
          // Professional blue
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            tooltip: 'Exit Survey',
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pre-Gate In Survey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Container Inspection Form',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        provider.hasValidatedShippingLine = true;
                        if (provider.validateForm()) {
                          final errorMessage = await provider.saveSurvey(
                            context,
                          );

                          if (!context.mounted) return;

                          if (errorMessage == null) {
                            // This means success
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Survey submitted successfully",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            Navigator.pop(context, true);
                          } else if (errorMessage ==
                              'A survey for this container number has already been done.') {
                            // Handle the specific "duplicate container" error
                            await CautionDialog.show(
                              context: context,
                              title: 'Duplicate Survey',
                              message: errorMessage,
                              icon: Icons.error_outline,
                              iconColor: Colors.red,
                            );
                          } else {
                            // Handle all other generic errors
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      errorMessage, // Show the actual error message
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        } else {
                          final errors = provider.errors;
                          final errorMessage = _getErrorMessage(errors);

                          // Find which tab has the first error
                          int errorTabIndex = 0;
                          if (errors.containsKey('containerNo') ||
                              errors.containsKey('shippingLine') ||
                              errors.containsKey('isoCode') ||
                              errors.containsKey('grossWeight') ||
                              errors.containsKey('tareWeight') ||
                              errors.containsKey('mfgMonth') ||
                              errors.containsKey('mfgYear')) {
                            errorTabIndex = 0;
                          } else if (errors.containsKey('transporterName')) {
                            errorTabIndex = 1;
                          } else if (errors.containsKey('examination') ||
                              errors.containsKey('surveyType') ||
                              errors.containsKey('containerInStatus') ||
                              errors.containsKey('condition') ||
                              errors.containsKey('grade')) {
                            errorTabIndex = 2;
                          }
                          _tabController.animateTo(errorTabIndex);

                          CautionDialog.show(
                            context: context,
                            title: 'Incomplete Survey',
                            message: errorMessage,
                          );
                        }
                      },
                icon: provider.isLoading
                    ? SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        height: MediaQuery.sizeOf(context).height,
                        child: SvgPicture.asset('assets/anims/loading.json'),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  provider.isLoading ? 'Submitting...' : 'Submit',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1565C0),
                  disabledBackgroundColor: Colors.white.withOpacity(0.5),
                  disabledForegroundColor: Colors.grey,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: provider.isDropdownsLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Lottie.asset(
                        'assets/anims/loading.json',
                        repeat: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading Survey Data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we prepare your form',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : _buildFormTabs(),
      ),
    );
  }

  Widget _buildFormTabs() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF1565C0),
            indicatorWeight: 3,
            labelColor: const Color(0xFF1565C0),
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            isScrollable: false,
            tabs: const [
              Tab(
                height: 50,
                icon: Icon(Icons.inventory_2_outlined, size: 20),
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'CONTAINER',
              ),
              Tab(
                height: 50,
                icon: Icon(Icons.local_shipping_outlined, size: 20),
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'TRANSPORT',
              ),
              Tab(
                height: 50,
                icon: Icon(Icons.assignment_outlined, size: 20),
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'SURVEY',
              ),
              Tab(
                height: 50,
                icon: Icon(Icons.photo_camera_outlined, size: 20),
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'PHOTOS',
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
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
        ),
      ],
    );
  }
}
