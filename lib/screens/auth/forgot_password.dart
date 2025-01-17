import 'package:autophile/core/toast.dart';
import 'package:autophile/screens/auth/forgot_otp_page.dart';
import 'package:autophile/screens/auth/login_page.dart';
import 'package:autophile/screens/auth/verify_email_page.dart';
import 'package:email_otp/email_otp.dart';
import 'package:flutter/material.dart';

import 'package:autophile/widgets/app_button.dart';
import 'package:autophile/widgets/app_textfield.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();

  void sendOTP()async{
    EmailOTP.config(
      appName: 'Autophile',
      otpType: OTPType.numeric,
      expiry : 60000,
      emailTheme: EmailTheme.v3,
      appEmail: 'info@autophile.com',
      otpLength: 6,
    );
    bool result = await EmailOTP.sendOTP(email: emailController.text);
    if(result){
      Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotOTPPage(email: emailController.text)));
    }else{
      ToastUtils.showError('Something went wrong while sending OTP');
    }
  }
  // Function to validate email format
  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$")
        .hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_open_rounded,
                        color: Theme.of(context).colorScheme.onSecondary,
                        size: 150,
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Forgot Password?',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Don’t worry! It happens. Please enter the email associated with your account.",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  SizedBox(height: 41,),
                  AppTextField(
                    controller: emailController,
                    hintText: 'Enter your email address',
                    labelText: 'Email address',
                    obscureText: false,

                  ),
                  const SizedBox(height: 41),
                  AppButton(text: 'Send link', onTap: sendOTP),
                  const SizedBox(height: 71),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Remember password?',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary
                        ),
                      ),
                      SizedBox(width: 20,),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>Login_Page()));
                        },
                        child:
                        Text('Sign in',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),

    );
  }
}
