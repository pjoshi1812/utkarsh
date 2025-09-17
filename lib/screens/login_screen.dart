import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isValidEmail(String email) {
    // Basic email validation regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> signInWithEmailPassword() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (userCredential.user != null) {
        // Check if user is admin/teacher
        if (emailController.text.trim() == 'utkarshacademy20@gmail.com') {
          // Admin/Teacher login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome Admin!'), backgroundColor: Colors.green),
          );
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          }
        } else {
          // Check if user has approved enrollment
          final enrollmentQuery = await FirebaseFirestore.instance
              .collection('enrollments')
              .where('parentUid', isEqualTo: userCredential.user!.uid)
              .where('status', isEqualTo: 'approved')
              .limit(1)
              .get();

          if (enrollmentQuery.docs.isNotEmpty) {
            // Student has approved enrollment
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Welcome Student!'), backgroundColor: Colors.green),
            );
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/student-dashboard');
            }
          } else {
            // Regular user login - redirect to explore page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login successful!')),
            );
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/explore-more');
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() {
        _isLoading = true;
      });

      UserCredential userCredential;
      if (kIsWeb) {
        // Web sign-in
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
      } else {
        // Mobile sign-in (Android/iOS/macOS/Windows)
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        
        try {
          // Sign out first to ensure fresh sign-in
          await googleSignIn.signOut();
          
          // First try silent sign-in
        GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
          
          // If silent sign-in fails, show the sign-in dialog
          if (googleUser == null) {
            googleUser = await googleSignIn.signIn();
          }
          
          if (googleUser == null) {
            setState(() {
              _isLoading = false;
            });
            return; // User cancelled
          }

          print('Google Sign-In Account: ${googleUser.email}');

          // Get authentication details
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          
          print('Google Auth - Access Token: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}');
          print('Google Auth - ID Token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}');
          
          // Create Firebase credential
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

          // Sign in to Firebase with the credential
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
          
          print('Firebase Auth successful');
        } catch (e) {
          print('Google Sign-In Error: $e');
          rethrow;
        }
      }

      // Store user info in Firestore if new
      final user = userCredential.user;
      if (user != null) {
           // Debug: Print user info
           print('Google Sign-in successful for: ${user.email}');
           
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'name': user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'parent', // Default role, adjust as needed
               'emailVerified': user.emailVerified,
             });
             print('New user created in Firestore');
           } else {
             // Update email verification status
             await userDoc.update({
               'emailVerified': user.emailVerified,
             });
             print('Existing user found in Firestore');
           }
           
           // Check if user is admin/teacher
           if (user.email == 'utkarshacademy20@gmail.com') {
             // Admin/Teacher login
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Welcome Admin!'), backgroundColor: Colors.green),
             );
             if (context.mounted) {
               Navigator.pushReplacementNamed(context, '/admin-dashboard');
             }
           } else {
             // Check if user has approved enrollment
             final enrollmentQuery = await FirebaseFirestore.instance
                 .collection('enrollments')
                 .where('parentUid', isEqualTo: user.uid)
                 .where('status', isEqualTo: 'approved')
                 .limit(1)
                 .get();

             if (enrollmentQuery.docs.isNotEmpty) {
               // Student has approved enrollment
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Welcome Student!'), backgroundColor: Colors.green),
               );
               if (context.mounted) {
                 Navigator.pushReplacementNamed(context, '/student-dashboard');
               }
             } else {
               // Regular user login - redirect to explore page
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Signed in with Google!')),
               );
               if (context.mounted) {
                 Navigator.pushReplacementNamed(context, '/explore-more');
               }
             }
           }
         } else {
           throw Exception('Failed to get user from Firebase Auth');
         }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      String errorMessage = 'Google sign-in failed';
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage = 'An account already exists with the same email address but different sign-in credentials.';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Invalid credentials provided.';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'Google sign-in is not enabled.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled.';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'No user found for this email.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      print('General Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    if (!_isValidEmail(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email == emailController.text.trim()) {
        print('Resending verification email to: ${user.email}');
        await user.sendEmailVerification();
        print('Verification email resent successfully');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent! Check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in first to resend verification email'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send verification email';
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found with this email address.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many requests. Please try again later.';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Debug function removed - email verification is working

  Future<void> _resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    if (!_isValidEmail(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Sending password reset email to: ${emailController.text.trim()}');
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      
      print('Password reset email sent successfully');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send reset email';
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found with this email address.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many requests. Please try again later.';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Removed duplicate return Scaffold and block
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.30,
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
                              "Welcome to login Page",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 32),
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
                             const SizedBox(height: 16),
                             // Forgot Password and Resend Verification Links
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 TextButton(
                                   onPressed: _resendVerificationEmail,
                                   child: const Text(
                                     "Resend Verification",
                                     style: TextStyle(
                                       color: Colors.blue,
                                       fontWeight: FontWeight.w600,
                                     ),
                                   ),
                                 ),
                                 TextButton(
                                   onPressed: _resetPassword,
                                   child: const Text(
                                     "Forgot Password?",
                                     style: TextStyle(
                                       color: Colors.green,
                                       fontWeight: FontWeight.w600,
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                             // Debug button removed - email verification is working
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
                                onPressed: _isLoading ? null : signInWithEmailPassword,
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
                                  "Login",
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
                                  "Sign in with Google",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.green,
                                    width: 1.5,
                                  ),
                                  elevation: 2,
                                  shadowColor: Colors.greenAccent.withOpacity(
                                    0.1,
                                  ),
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
                                const Text("Don't have an account?"),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/register');
                                  },
                                  child: const Text(
                                    "Register",
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
