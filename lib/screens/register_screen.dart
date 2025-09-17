import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isValidEmail(String email) {
    // Basic email validation regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> signUpWithEmailPassword() async {
    if (studentNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Validate email format
    if (!_isValidEmail(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address (e.g., user@domain.com)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password strength
    String password = passwordController.text.trim();
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

             // Store user info in Firestore
       final user = userCredential.user;
       if (user != null) {
         await FirebaseFirestore.instance
             .collection('users')
             .doc(user.uid)
             .set({
           'uid': user.uid,
           'name': studentNameController.text.trim(),
           'email': emailController.text.trim(),
           'createdAt': FieldValue.serverTimestamp(),
           'role': 'parent',
           'emailVerified': false,
         });

                   // Send email verification
          try {
            await user.sendEmailVerification();
            print('Email verification sent successfully to: ${user.email}');
            print('Please check your email (including spam folder) for verification link');
            print('Sender: noreply@utkarsh-8cf54.firebaseapp.com');
            print('Subject: Verify your email for Utkarsh Academy');
          } catch (e) {
            print('Error sending email verification: $e');
            // Continue with registration even if email verification fails
          }

                   ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please check your email to verify your account.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );

          // Navigate to explore page after registration
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/explore-more');
          }
       }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> signUpWithGoogle() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // Web sign-in
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
      } else {
        // Mobile sign-in
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return; // User cancelled
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      // Store user info in Firestore if new
      final user = userCredential.user;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'name': studentNameController.text.trim().isNotEmpty 
                ? studentNameController.text.trim() 
                : user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'parent', // Default role, adjust as needed
          });
        }
      }
             ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Registration successful!'),
           backgroundColor: Colors.green,
         ),
       );
       
       // Navigate to explore page after registration
       if (context.mounted) {
         Navigator.pushReplacementNamed(context, '/explore-more');
       }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-up failed: $e')));
    }
  }

  final studentNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    studentNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // Subtle green background
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.30, // Low opacity for background image
              child: Image.asset('assets/bg_math.png', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double maxWidth =
                    constraints.maxWidth < 500 ? constraints.maxWidth : 400;
                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo at the top center
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/utkarsh_logo.jpg',
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Utkarsh Academy",
                              style: TextStyle(
                                color: Color(0xFF1B5E20),
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Register Account",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Student Name input
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CustomTextField(
                                label: "Student Name",
                                controller: studentNameController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Student Name",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CustomTextField(
                                label: "Email Id",
                                controller: emailController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Email Id",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CustomTextField(
                                label: "Password",
                                controller: passwordController,
                                obscureText: obscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed:
                                      () => setState(() => obscure = !obscure),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: _isLoading ? null : signUpWithEmailPassword,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Register",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text("or"),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.g_mobiledata,
                                  size: 28,
                                  color: Colors.green,
                                ),
                                label: const Text(
                                  "Sign up with Google",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: signUpWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.green,
                                    width: 1.5,
                                  ),
                                  elevation: 2,
                                  shadowColor: Colors.green.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Already have an account?"),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(color: Colors.green),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
