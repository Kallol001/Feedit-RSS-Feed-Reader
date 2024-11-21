import 'package:flutter/material.dart';

import '../services/authentication.dart';
import '../services/google_auth.dart';
import '../widgets/button.dart';
import '../widgets/snackbar.dart';
import '../widgets/text_field.dart';
import 'forgot_password.dart';
import 'home_screen.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const LoginScreen({super.key, this.onToggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isGoogleLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void loginUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      String res = await AuthMethod().loginUser(
        email: emailController.text,
        password: passwordController.text,
      );

      if (res == "success" && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              onToggleTheme: widget.onToggleTheme ?? () {},
            ),
          ),
        );
      } else if (mounted) {
        showSnackBar(context, res);
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> handleGoogleSignIn() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      String result = await FirebaseServices().signInWithGoogle();

      if (result == "success" && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              onToggleTheme: widget.onToggleTheme ?? () {},
            ),
          ),
        );
      } else if (mounted) {
        showSnackBar(context, result);
      }
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  void _navigateToSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SignupScreen(
          onToggleTheme: widget.onToggleTheme ?? () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive width calculation
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Determine content width based on screen size
    double contentWidth = screenWidth > 1200
        ? 400
        : screenWidth > 600
            ? screenWidth * 0.7
            : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: contentWidth,
                  constraints: BoxConstraints(
                    minHeight: screenHeight * 0.8,
                    maxWidth: contentWidth,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Name
                      Text(
                        'Feedit',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Login Image (Local)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: screenHeight * 0.20,
                          maxWidth: contentWidth * 0.8,
                        ),
                        child: Image.asset(
                          'lib/assets/login.jpg', // Update with your local image path
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Login Form
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            TextFieldInput(
                              icon: Icons.email,
                              textEditingController: emailController,
                              hintText: 'Email',
                              textInputType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextFieldInput(
                              icon: Icons.lock,
                              textEditingController: passwordController,
                              hintText: 'Password',
                              textInputType: TextInputType.text,
                              isPass: true,
                            ),
                            const ForgotPassword(),
                            const SizedBox(height: 14),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              child: isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : MyButtons(
                                      onTap: loginUser,
                                      text: "Log In",
                                    ),
                            ),
                            const SizedBox(height: 12),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                      height: 1, color: Colors.grey.shade300),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    "or",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                      height: 1, color: Colors.grey.shade300),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Google Sign In Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                onPressed:
                                    isGoogleLoading ? null : handleGoogleSignIn,
                                child: isGoogleLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Image.asset(
                                              'lib/assets/google_logo.png', // Update with your local Google logo path
                                              height: 24,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text("Continue with Google"),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Sign Up Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _navigateToSignup,
                                  child: Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
