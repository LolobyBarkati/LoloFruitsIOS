import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class FingerprintAuthScreen extends StatefulWidget {
  static const routeName = '/fingerprint-auth';

  @override
  _FingerprintAuthScreenState createState() => _FingerprintAuthScreenState();
}

class _FingerprintAuthScreenState extends State<FingerprintAuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticateWithFingerprint();
  }

  Future<void> _authenticateWithFingerprint() async {
    try {
      setState(() => isAuthenticating = true);

      bool authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showRetryDialog();
      }
    } catch (e) {
      print("Authentication Error: $e");
      _showRetryDialog();
    } finally {
      setState(() => isAuthenticating = false);
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Failed'),
        content: const Text('Fingerprint authentication failed. Try again?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Use Password'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authenticateWithFingerprint();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: isAuthenticating
              ? const CircularProgressIndicator()
              : const Text('Authentication Required'),
        ),
      ),
    );
  }
}
