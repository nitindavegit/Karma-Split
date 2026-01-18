import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:karma_split/pages/main_page.dart';
import 'package:karma_split/pages/auth_choice_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<bool> _showBackConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Cancel Login?'),
              content: const Text(
                'Are you sure you want to cancel the login process?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Continue Login'),
                ),
                TextButton(
                  onPressed: () async {
                    final navigatorContext = this.context;
                    Navigator.of(context).pop(true);
                    if (!mounted) return;
                    await _auth.signOut();
                    if (mounted && navigatorContext.mounted) {
                      Navigator.of(navigatorContext).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const AuthChoicePage(),
                        ),
                      );
                    }
                  },
                  child: const Text('Cancel Login'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _checkAccount(String phone) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      
      if (!mounted) return;

      if (querySnapshot.docs.isNotEmpty) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainPage()),
          (route) => false,
        );
      } else {
        await _auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account not found. Please sign up.')),
          );
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  // Removed _useDemoCredentials as we don't auto-fill anymore

  Future<bool> _checkGlobalOtpLimit(String phoneNumber) async {
    // BYPASS LIMIT FOR DEMO NUMBER
    String demoPhone = dotenv.env['DEMO_PHONE_NUMBER'] ?? "7233665588";
    // Sanitize for comparison
    demoPhone = demoPhone.replaceAll(RegExp(r'\D'), '');
    if (demoPhone.length > 10) {
      demoPhone = demoPhone.substring(demoPhone.length - 10);
    }

    if (phoneNumber.contains(demoPhone)) {
      return true;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('system_metrics')
          .doc('auth_metrics');

      return await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        if (!snapshot.exists) {
          // Initialize if not exists
          transaction.set(docRef, {
            'otp_requests_count': 1,
            'last_reset_date': Timestamp.fromDate(today),
          });
          return true; // Use 1st request
        }

        final data = snapshot.data()!;
        final lastResetTimestamp = data['last_reset_date'] as Timestamp;
        final lastResetDate = lastResetTimestamp.toDate();
        final resetDate = DateTime(lastResetDate.year, lastResetDate.month, lastResetDate.day);

        int currentCount = data['otp_requests_count'] as int;

        if (today.isAfter(resetDate)) {
          // New day, reset counter
          currentCount = 0;
          transaction.update(docRef, {
            'otp_requests_count': 1,
            'last_reset_date': Timestamp.fromDate(today),
          });
          return true;
        }

        if (currentCount >= 10) { // Limit set to 10
          return false; // Limit reached
        }

        // Increment
        transaction.update(docRef, {
          'otp_requests_count': currentCount + 1,
        });
        return true;
      });
    } catch (e) {
      print("Error checking OTP limit: $e");
      return true; // Fail safe: allow login if check fails
    }
  }

  Future<void> _showLimitReachedDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Daily Login Limit Reached'),
          content: const Text(
            'The daily limit for OTP verifications has been reached for the app.\n\nFor demo access, please check the README on our GitHub repository.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getOTP() async {
    final phone = "+91${_mobileController.text.trim()}";
    if (phone.length != 13 ||
        !_mobileController.text.startsWith(RegExp(r'[6-9]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit mobile number')),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    // CHECK GLOBAL LIMIT
    final allowed = await _checkGlobalOtpLimit(phone);
    if (!allowed) {
      setState(() => _isLoading = false);
      if (mounted) _showLimitReachedDialog();
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _onVerificationSuccess();
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Verification failed')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your mobile number')),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (mounted) _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOTP() async {
    final smsCode = _otpController.text.trim();
    if (_verificationId == null || smsCode.isEmpty) return;

    if (smsCode.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP must be 6 digits')));
      return;
    }
    
    setState(() => _isLoading = true);

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    try {
      await _auth.signInWithCredential(credential);
      setState(() => _isLoading = false);
      _onVerificationSuccess();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
    }
  }

  Future<void> _onVerificationSuccess() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final phone = user.phoneNumber ?? "";
      if (phone.isEmpty) { // Fallback if phoneNumber is null
         // Should not happen with Phone Auth
      }
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        if (mounted) {
          // Clear the entire navigation stack and go to MainPage
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainPage()),
            (route) => false,
          );
        }
      } else {
        await _auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account not found. Please sign up.')),
          );
        }
      }
    } catch (e) {
      await _auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking account: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_otpSent,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_otpSent) {
          final dialogContext = context;
          final shouldExit = await _showBackConfirmationDialog();
          if (shouldExit && dialogContext.mounted) {
            Navigator.of(dialogContext).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthChoicePage()),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Sign In'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Welcome text
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue to Karma Split',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Mobile number section
                Text(
                  'Mobile Number',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  enabled: !_otpSent,
                  decoration: InputDecoration(
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon: Icon(Icons.phone, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 20),

                if (_otpSent) ...[
                  // OTP section
                  Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, letterSpacing: 2),
                    decoration: InputDecoration(
                      hintText: 'Enter 6-digit OTP',
                      prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Verify OTP button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "Verify OTP",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ] else ...[
                  // Get OTP button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _getOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "Send OTP",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],

                const SizedBox(height: 30),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
