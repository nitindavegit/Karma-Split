import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:karma_split/pages/main_page.dart';
import 'dart:io';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}


class _SignupPageState extends State<SignupPage> {
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

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
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
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOTP() async {
    final smsCode = _otpController.text.trim();
    if (_verificationId == null || smsCode.isEmpty) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  void _pickImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final picked = await ImagePicker().pickImage(
                source: ImageSource.camera,
              );
              if (picked != null) setState(() => _profileImage = picked);
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null) setState(() => _profileImage = picked);
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSignup() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    if (username.isEmpty || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Username must be non-empty and contain only alphanumeric characters',
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Check username uniqueness
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Username already taken')));
        return;
      }
      // Proceed to photo upload
      String? photoUrl;
      if (_profileImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'profile_images/${_auth.currentUser!.uid}.jpg',
        );
        await storageRef.putFile(File(_profileImage!.path));
        photoUrl = await storageRef.getDownloadURL();
      }
      // Save data
      final phone = '+91${_mobileController.text.trim()}';
      await FirebaseFirestore.instance.collection('users').doc(phone).set({
        'name': name,
        'username': username,
        'phone': phone,
        'photoUrl': photoUrl,
        'totalKarmaPoints': 0,
        'groupsJoined': 0,
        'expensesAdded': 0,
        'totalSpent': 0,
      });
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup completed successfully!')),
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _onVerificationSuccess() {
    setState(() => _otpVerified = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Mobile number field
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Mobile Number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_otpVerified) ...[
                  const SizedBox(height: 20),
                  // pfp
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(File(_profileImage!.path))
                            : AssetImage('assets/images/JD.jpg'),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
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
                  const SizedBox(height: 30),
                  // Name Field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Username field
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (_otpVerified) ...[
                  ElevatedButton(
                    onPressed: _isLoading ? null : _completeSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Complete Signup",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ] else if (_otpSent) ...[
                  // OTP field
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Enter OTP",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Verify OTP button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Verify OTP",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ] else ...[
                  // Get OTP button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _getOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Get OTP", style: TextStyle(fontSize: 18)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
