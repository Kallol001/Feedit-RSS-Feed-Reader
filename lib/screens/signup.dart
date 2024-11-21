//signup.dart

import 'package:flutter/material.dart';

import '/widgets/button.dart';
import '../services/authentication.dart';
import '../widgets/snackbar.dart';
import '../widgets/text_field.dart';
import 'home_screen.dart';
import 'login.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const SignupScreen({super.key, this.onToggleTheme});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signupUser() async {
    setState(() {
      isLoading = true;
    });

    String res = await AuthMethod().signupUser(
      email: emailController.text,
      password: passwordController.text,
      name: nameController.text,
    );

    if (res == "success") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            onToggleTheme: widget.onToggleTheme ?? () {},
          ),
        ),
      );
    } else {
      showSnackBar(context, res);
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          onToggleTheme: widget.onToggleTheme ?? () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
            child: Container(
              constraints: BoxConstraints(
                maxWidth: contentWidth,
                minHeight: screenHeight * 0.8,
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
              padding: const EdgeInsets.symmetric(vertical: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Feedit',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: screenHeight * 0.20,
                      maxWidth: contentWidth * 0.8,
                    ),
                    child: Image.asset(
                      'lib/assets/signup.jpeg', // Update with your local image path
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextFieldInput(
                          icon: Icons.person,
                          textEditingController: nameController,
                          hintText: 'Name',
                          textInputType: TextInputType.text,
                        ),
                        const SizedBox(height: 10),
                        TextFieldInput(
                          icon: Icons.email,
                          textEditingController: emailController,
                          hintText: 'Email',
                          textInputType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        TextFieldInput(
                          icon: Icons.lock,
                          textEditingController: passwordController,
                          hintText: 'Password',
                          textInputType: TextInputType.text,
                          isPass: true,
                        ),
                        const SizedBox(height: 14),
                        isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: MyButtons(
                                  onTap: signupUser,
                                  text: "Sign Up",
                                ),
                              ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?"),
                            GestureDetector(
                              onTap: _navigateToLogin,
                              child: const Text(
                                " Login",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
