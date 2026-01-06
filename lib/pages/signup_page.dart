import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:karma_split/pages/main_page.dart';
import 'package:karma_split/pages/auth_choice_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:karma_split/utils/image_compressor.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  bool _otpSent = false;
  bool _isLoading = false;
  bool _otpVerified = false;
  XFile? _profileImage;
  Timer? _usernameCheckTimer;
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;
  String? _usernameError;

  // Validation patterns
  static const String _usernamePattern = r'^[a-zA-Z0-9_]{3,20}$';
  static const String _namePattern = r'^[a-zA-Z\s]{2,50}$';

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _usernameCheckTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim();
    _usernameCheckTimer?.cancel();

    // Clear previous states
    setState(() {
      _isUsernameAvailable = false;
      _isCheckingUsername = false;
      _usernameError = null;
    });

    // Only check for availability if basic validation passes
    if (username.isEmpty) {
      return; // Don't show error for empty field
    }

    if (username.length < 3) {
      setState(() {
        _usernameError = 'Username must be at least 3 characters';
      });
      return;
    }

    if (!RegExp(_usernamePattern).hasMatch(username)) {
      setState(() {
        _usernameError =
            'Username can only contain letters, numbers, and underscores';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
    });

    _usernameCheckTimer = Timer(const Duration(seconds: 1), () {
      _checkUsernameAvailability(username);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isUsernameAvailable = querySnapshot.docs.isEmpty;
          _isCheckingUsername = false;
          if (!_isUsernameAvailable) {
            _usernameError = 'Username already taken';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameError = 'Error checking username availability';
        });
      }
    }
  }

  Future<void> _getOTP() async {
    final phone = "+91${_mobileController.text.trim()}";
    if (!_validateMobileNumber()) return;

    // Check if mobile number is already registered - DO THIS FIRST before OTP
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(
          'This mobile number is already registered. Please use a different number or login.',
        );
        return;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error checking mobile number registration');
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
        _showErrorSnackBar('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
        _showSuccessSnackBar('OTP sent to your mobile number');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  bool _validateMobileNumber() {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      _showErrorSnackBar('Please enter your mobile number');
      return false;
    }
    if (mobile.length != 10) {
      _showErrorSnackBar('Mobile number must be 10 digits');
      return false;
    }
    if (!mobile.startsWith(RegExp(r'[6-9]'))) {
      _showErrorSnackBar('Mobile number must start with 6, 7, 8, or 9');
      return false;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      _showErrorSnackBar('Please enter a valid mobile number');
      return false;
    }
    return true;
  }

  Future<void> _verifyOTP() async {
    final smsCode = _otpController.text.trim();
    if (_verificationId == null || smsCode.isEmpty) {
      _showErrorSnackBar('Please enter the OTP');
      return;
    }
    if (smsCode.length != 6) {
      _showErrorSnackBar('OTP must be 6 digits');
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
      _showErrorSnackBar('Invalid OTP. Please try again.');
    }
  }

  void _pickImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Profile Picture'),
        content: const Text('Select how you want to add your profile picture'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final picked = await ImagePicker().pickImage(
                source: ImageSource.camera,
                imageQuality: 80,
              );
              if (picked != null) setState(() => _profileImage = picked);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt),
                const SizedBox(width: 8),
                const Text('Camera'),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );
              if (picked != null) setState(() => _profileImage = picked);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library),
                const SizedBox(width: 8),
                const Text('Gallery'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // IMAGE UPLOAD TO CLOUDINARY
  Future<String> _uploadImageToCloudinary(File imageFile, String userId) async {
    try {
      // Compress the image before uploading
      final compressedFile = await compressImage(imageFile, quality: 80);

      // Cloudinary configuration
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
      final folder = dotenv.env['CLOUDINARY_FOLDER'] ?? '';

      // Create multipart request
      final request = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final requestFields = {
        'upload_preset': uploadPreset,
        'folder': folder,
        'public_id': '${userId}_profilepicture',
      };

      final imageBytes = await compressedFile.readAsBytes();

      final requestMultipart = http.MultipartRequest('POST', request);
      requestMultipart.fields.addAll(requestFields);
      requestMultipart.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'profilepicture.jpg',
        ),
      );

      final response = await requestMultipart.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        final secureUrl = jsonResponse['secure_url'];

        return secureUrl;
      } else {
        final responseData = await response.stream.bytesToString();
        throw Exception(
          'Upload failed with status: ${response.statusCode}. Response: $responseData',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _completeSignup() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    try {
      // Double-check username uniqueness
      final username = _usernameController.text.trim();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Username already taken. Please choose another.');
        return;
      }

      // Check if profile picture is selected (mandatory)
      if (_profileImage == null) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Profile picture is mandatory. Please select one.');
        return;
      }

      // Generate a unique user ID using UUID
      final String userId = const Uuid().v4();
      final photoUrl = await _uploadImageToCloudinary(
        File(_profileImage!.path),
        userId,
      );

      // Save user data
      final name = _nameController.text.trim();
      final phone = '+91${_mobileController.text.trim()}';

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'name': name,
        'userId': userId,
        'username': username,
        'phone': phone,
        'photoUrl': photoUrl, // Profile image uploaded to Cloudinary
        'totalKarmaPoints': 0.0,
        'groupsJoined': 0,
        'expensesAdded': 0,
        'totalSpent': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      setState(() => _isLoading = false);
      _showSuccessSnackBar('Account created successfully!');

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error creating account: ${e.toString()}');
    }
  }

  bool _validateForm() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    if (!_otpVerified) {
      _showErrorSnackBar('Please verify your mobile number first');
      return false;
    }

    // Check profile picture is mandatory
    if (_profileImage == null) {
      _showErrorSnackBar('Profile picture is mandatory');
      return false;
    }

    if (name.isEmpty) {
      _showErrorSnackBar('Please enter your name');
      return false;
    }

    if (!RegExp(_namePattern).hasMatch(name)) {
      _showErrorSnackBar(
        'Name should only contain letters and be 2-50 characters',
      );
      return false;
    }

    if (username.isEmpty) {
      _showErrorSnackBar('Please enter a username');
      return false;
    }

    if (!RegExp(_usernamePattern).hasMatch(username)) {
      _showErrorSnackBar(
        'Username must be 3-20 characters, letters, numbers, and underscores only',
      );
      return false;
    }

    if (!_isUsernameAvailable) {
      _showErrorSnackBar('Please choose an available username');
      return false;
    }

    return true;
  }

  void _onVerificationSuccess() {
    setState(() => _otpVerified = true);
    _showSuccessSnackBar('Mobile number verified successfully!');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showBackConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Cancel Signup?'),
              content: const Text(
                'Are you sure you want to cancel the signup process? Your progress will be lost.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Don't exit
                  },
                  child: const Text('Continue Signup'),
                ),
                TextButton(
                  onPressed: () async {
                    final navigatorContext = this.context;
                    Navigator.of(context).pop(true); // Close the dialog
                    // Sign out the user and navigate to AuthChoicePage
                    await _auth.signOut();
                    if (mounted && navigatorContext.mounted) {
                      Navigator.of(navigatorContext).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const AuthChoicePage(),
                        ),
                      );
                    }
                  },
                  child: const Text('Cancel Signup'),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(_otpSent || _otpVerified),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Show confirmation dialog when trying to go back
        if (_otpSent || _otpVerified) {
          final dialogContext = context;
          final result = await _showBackConfirmationDialog();
          if (result && dialogContext.mounted) {
            // Navigate back to AuthChoicePage
            Navigator.of(dialogContext).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthChoicePage()),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Create Account'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Welcome text
                    Text(
                      'Join Karma Split',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your account to start splitting expenses',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Mobile number field
                    _buildMobileField(),
                    const SizedBox(height: 20),

                    // OTP verification section
                    if (_otpVerified) ...[
                      _buildProfilePictureSection(),
                      const SizedBox(height: 20),
                      _buildNameField(),
                      const SizedBox(height: 20),
                      _buildUsernameField(),
                      const SizedBox(height: 30),
                      _buildCompleteSignupButton(),
                    ] else if (_otpSent) ...[
                      const SizedBox(height: 20),
                      _buildOTPField(),
                      const SizedBox(height: 20),
                      _buildVerifyOTPButton(),
                    ] else ...[
                      const SizedBox(height: 20),
                      _buildGetOTPButton(),
                    ],

                    const SizedBox(height: 20),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Sign In',
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
        ),
      ),
    );
  }

  Widget _buildMobileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      ],
    );
  }

  Widget _buildOTPField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      ],
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Text(
          'Profile Picture *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: _profileImage != null
                  ? FileImage(File(_profileImage!.path))
                  : null,
              child: _profileImage == null
                  ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Profile picture is mandatory',
          style: TextStyle(color: Colors.red[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Choose a unique username',
            prefixIcon: Icon(Icons.alternate_email, color: Colors.grey[600]),
            suffixIcon: _buildUsernameSuffixIcon(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            errorText: _usernameError,
          ),
        ),
        if (_isUsernameAvailable && _usernameController.text.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 16),
              const SizedBox(width: 4),
              Text(
                'Username is available',
                style: TextStyle(color: Colors.green[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget? _buildUsernameSuffixIcon() {
    if (_isCheckingUsername) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_usernameController.text.isNotEmpty) {
      if (_isUsernameAvailable) {
        return Icon(Icons.check_circle, color: Colors.green[600]);
      } else if (_usernameError != null) {
        return Icon(Icons.error, color: Colors.red[600]);
      }
    }

    return null;
  }

  Widget _buildGetOTPButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _getOTP,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              "Send OTP",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildVerifyOTPButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _verifyOTP,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              "Verify OTP",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildCompleteSignupButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _completeSignup,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              "Create Account",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }
}
