import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/widgets/snackbar.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController emailController = TextEditingController();
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () {
            myDialogBox(context);
          },
          child: const Text(
            "Forgot Password?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  void myDialogBox(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Get screen width to make dialog responsive
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate dynamic width and padding
              double dialogWidth = screenWidth > 600
                  ? 300 // Desktop/tablet width
                  : screenWidth * 0.85; // Mobile width (85% of screen)

              return Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: screenHeight * 0.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.all(
                  screenWidth > 600
                      ? 20
                      : 15, // Adjust padding for different screen sizes
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Spacer(),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                "Forgot Your Password",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth > 600 ? 18 : 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth > 600 ? 20 : 10),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 600 ? 0 : 10,
                        ),
                        child: TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelText: "Enter the Email",
                            hintText: "eg abc@gmail.com",
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: screenWidth > 600 ? 15 : 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenWidth > 600 ? 20 : 15),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 600 ? 0 : 10,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                              vertical: screenWidth > 600 ? 15 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await auth
                                .sendPasswordResetEmail(
                                    email: emailController.text)
                                .then((value) {
                              // if success then show this message
                              showSnackBar(context,
                                  "We have sent you the reset password link to your email id, Please check it");
                            }).onError((error, stackTrace) {
                              // if unsuccessful then show error message
                              showSnackBar(context, error.toString());
                            });
                            // terminate the dialog after send the forgot password link
                            Navigator.pop(context);
                            // clear the text field
                            emailController.clear();
                          },
                          child: Text(
                            "Send",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth > 600 ? 16 : 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
