import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadUserCredentials();
  }

  Future<void> _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final bool rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _usernameController.text = prefs.getString('username') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      });
    }
  }

  Future<void> _handleCredentialsSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', _rememberMe);

    if (_rememberMe) {
      await prefs.setString('username', _usernameController.text.trim());
      await prefs.setString('password', _passwordController.text.trim());
    } else {
      await prefs.remove('username');
      await prefs.remove('password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // --- NEW: A reusable border style for the text fields ---
    final borderStyle = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(
        color: Colors.white.withOpacity(0.2),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
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
                    // --- NEW: The Theme widget applies a consistent style to all text fields within the Form ---
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          enabledBorder: borderStyle,
                          focusedBorder: borderStyle.copyWith(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: borderStyle.copyWith(
                            borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                          ),
                          focusedErrorBorder: borderStyle.copyWith(
                            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
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
                              height: 80,
                              width: 80,
                              child: SvgPicture.asset(
                                'assets/icons/squareVerticalW.svg',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Sign In",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // --- UPDATED: TextFormField is now simpler, inheriting the new style ---
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: "Username",
                                prefixIcon: Icon(Icons.person, color: Colors.white70),
                              ),
                              validator: (value) => value == null || value.isEmpty ? "Enter username" : null,
                            ),
                            const SizedBox(height: 16),

                            // --- UPDATED: TextFormField is now simpler, inheriting the new style ---
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty ? "Enter password" : null,
                            ),
                            const SizedBox(height: 12),

                            CheckboxListTile(
                              value: _rememberMe,
                              onChanged: (bool? value) => setState(() => _rememberMe = value ?? false),
                              title: const Text('Remember Me', style: TextStyle(color: Colors.white)),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: Theme.of(context).colorScheme.primary,
                              checkColor: Colors.white,
                            ),
                            const SizedBox(height: 12),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () async {
                                if (_formKey.currentState!.validate()) {
                                  // Save the "Remember Me" choice
                                  await _handleCredentialsSave();

                                  await authProvider.login(
                                    _usernameController.text.trim(),
                                    _passwordController.text.trim(),
                                    context,
                                  );

                                  if (authProvider.errorMessage != null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(authProvider.errorMessage!),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      Navigator.pushReplacementNamed(context, '/dashboard');
                                    }
                                  }
                                }
                              },
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
    );
  }
}

class _FooterCard extends StatelessWidget {
  const _FooterCard();

  // ... (Layout logic for the footer remains the same)
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

  // "A product of" section
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
        // --- UPDATED: Reduced logo size ---
        SvgPicture.asset('assets/icons/ddFull.svg', height: 30),
      ],
    );
  }

  // "Other logistics products" section
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
            // --- UPDATED: Reduced all product logo sizes ---
            SvgPicture.asset('assets/icons/Tracker.svg', height: 24),
            const Text(
              '|',
              style: TextStyle(color: Colors.white30, fontSize: 20),
            ),
            SvgPicture.asset('assets/icons/Wheeler.svg', height: 24),
            const Text(
              '|',
              style: TextStyle(color: Colors.white30, fontSize: 20),
            ),
            SvgPicture.asset('assets/icons/squareVerticalW.svg', height: 24),
            const Text(
              '|',
              style: TextStyle(color: Colors.white30, fontSize: 20),
            ),
            SvgPicture.asset('assets/icons/fmlm.svg', height: 24),
          ],
        ),
      ],
    );
  }
}
