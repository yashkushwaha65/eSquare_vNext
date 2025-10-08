import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/authPdr.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final borderStyle = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/homedark.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    elevation: 8,
                    color: Colors.black.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            enabledBorder: borderStyle,
                            focusedBorder: borderStyle.copyWith(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: borderStyle.copyWith(
                              borderSide: BorderSide(
                                color: Colors.redAccent.withOpacity(0.5),
                              ),
                            ),
                            focusedErrorBorder: borderStyle.copyWith(
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 60,
                                width: 60,
                                child: SvgPicture.asset(
                                  'assets/icons/squareVerticalW.svg',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Sign In",
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: "Username",
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? "Enter username"
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.white70,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      );
                                    },
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? "Enter password"
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          await authProvider.login(
                                            _usernameController.text.trim(),
                                            _passwordController.text.trim(),
                                            context,
                                          );

                                          if (authProvider.errorMessage !=
                                              null) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    authProvider.errorMessage!,
                                                  ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                              );
                                            }
                                          } else {
                                            if (context.mounted) {
                                              Navigator.pushReplacementNamed(
                                                context,
                                                '/dashboard',
                                              );
                                            }
                                          }
                                        }
                                      },
                                child: authProvider.isLoading
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: SvgPicture.asset('assets/anims/loading.json'),
                                      )
                                    : const Text("Login"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _FooterCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterCard extends StatelessWidget {
  const _FooterCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: isMobile
              ? _buildMobileLayout(context)
              : _buildDesktopLayout(context),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildProductOfSection(context)),
          const VerticalDivider(color: Colors.white30, thickness: 1),
          Expanded(flex: 2, child: _buildOtherProductsSection(context)),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProductOfSection(context),
        const Divider(color: Colors.white30, height: 24, thickness: 1),
        _buildOtherProductsSection(context),
      ],
    );
  }

  Widget _buildProductOfSection(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "A product of",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        SvgPicture.asset('assets/icons/ddFull.svg', height: 24),
      ],
    );
  }

  Widget _buildOtherProductsSection(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Other logistics products",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            SvgPicture.asset('assets/icons/Tracker.svg', height: 20),
            const Text(
              '|',
              style: TextStyle(color: Colors.white30, fontSize: 20),
            ),
            SvgPicture.asset('assets/icons/Wheeler.svg', height: 20),
            // const Text(
            //   '|',
            //   style: TextStyle(color: Colors.white30, fontSize: 20),
            // ),
            // SvgPicture.asset('assets/icons/squareVerticalW.svg', height: 20),
            const Text(
              '|',
              style: TextStyle(color: Colors.white30, fontSize: 20),
            ),
            SvgPicture.asset('assets/icons/fmlm.svg', height: 15),
          ],
        ),
      ],
    );
  }
}
