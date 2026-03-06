import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/services/security_service.dart';
import 'package:fintrack/features/home/presentation/pages/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final settingsProvider = context.read<SettingsProvider>();

    if (!settingsProvider.biometricEnabled) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authenticated = await BiometricService.authenticate();
      if (authenticated && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Biometric authentication failed');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyPIN() async {
    final pinLength = _pinController.text.length;
    if (pinLength != 4 && pinLength != 6) {
      setState(() => _errorMessage = 'PIN must be 4 or 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await PINService.verifyPIN(_pinController.text);

      if (isValid && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        setState(() => _errorMessage = 'Invalid PIN');
        _pinController.clear();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error verifying PIN');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.lock,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Secure Access',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure Your Financial Data',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),

              // PIN Input Section (only if PIN is enabled)
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, _) {
                  if (!settingsProvider.pinEnabled) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      // PIN Input
                      TextField(
                        controller: _pinController,
                        enabled: !_isLoading,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          letterSpacing: 8,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 24,
                            color: Colors.grey[400],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onSubmitted: (_) => !_isLoading ? _verifyPIN() : null,
                      ),
                      const SizedBox(height: 16),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Unlock Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyPIN,
                          child: _isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Unlock',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              // Biometric Button (if enabled)
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, _) {
                  return FutureBuilder<bool>(
                    future: BiometricService.canUseBiometrics(),
                    builder: (context, snapshot) {
                      final canUseBiometrics = snapshot.data ?? false;
                      final isBiometricEnabled =
                          settingsProvider.biometricEnabled;

                      if (!canUseBiometrics || !isBiometricEnabled) {
                        return const SizedBox.shrink();
                      }

                      return TextButton.icon(
                        onPressed: _isLoading ? null : _tryBiometric,
                        icon: Icon(Icons.fingerprint),
                        label: Text('Use Biometric'),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
