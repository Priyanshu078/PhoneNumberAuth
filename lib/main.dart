import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:phoneauth/Authentication.dart';
import 'package:phoneauth/homepage.dart';
import 'package:sms_autofill/sms_autofill.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PhoneAuth(),
    );
  }
}

class PhoneAuth extends StatefulWidget {
  PhoneAuth({Key key}) : super(key: key);

  @override
  _PhoneAuthState createState() => _PhoneAuthState();
}

class _PhoneAuthState extends State<PhoneAuth> {
  String title = "Phone Authentication";
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _verificationId = '';
  final SmsAutoFill _autoFill = SmsAutoFill();
  TextEditingController _controllerNumber = new TextEditingController();
  TextEditingController _controllerOTP = new TextEditingController();
  String buttonText = "Send OTP";
  String verificationID = "";
  int resendtoken = 0;
  int seconds = 30;
  Timer _timer;
  Color color = Colors.black;
  bool _btnEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: Text(title),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: _controllerNumber,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Phone Number',
                  labelText: 'Phone No.',
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: TextField(
                    controller: _controllerOTP,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'OTP',
                      labelText: 'OTP',
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("OTP not recieved,"),
                    TextButton(
                        onPressed: _btnEnabled
                            ? () {
                                verifyPhoneNumber();
                                startTimer();
                              }
                            : null,
                        child: Text(
                          "Resend  OTP",
                          style: TextStyle(color: color),
                        )),
                    Text("$seconds:00"),
                  ],
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: MaterialButton(
                  color: Colors.deepOrange,
                  child: Text(
                    buttonText,
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    if (buttonText == "Send OTP") {
                      if (_controllerNumber.text.isNotEmpty) {
                        verifyPhoneNumber();
                        startTimer();
                      }
                    } else {
                      signIn(verificationID, resendtoken);
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void verifyPhoneNumber() async {
    setState(() {
      buttonText = "Verify";
    });
    await firebaseAuth.verifyPhoneNumber(
        phoneNumber: "+91" + _controllerNumber.text.toString(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // ANDROID ONLY!
          // Sign the user in (or link) with the auto-generated credential
          await firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'invalid-phone-number') {
            customSnackBar('The provided phone number is not valid.');
          }
          // Handle other errors
        },
        codeSent: (String verificationId, int resendToken) async {
          // Update the UI - wait for the user to enter the SMS code
          setState(() {
            verificationID = verificationId;
            resendtoken = resendToken;
          });
        },
        timeout: Duration(seconds: 25),
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            verificationID = verificationId;
          });
        });
  }

  signIn(String verificationId, int resendToken) async {
    // Update the UI - wait for the user to enter the SMS code
    String smsCode = _controllerOTP.text.toString();

    // Create a PhoneAuthCredential with the code
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    // Sign the user in (or link) with the credential
    await firebaseAuth.signInWithCredential(credential);
    customSnackBar("User SignedIn with $credential");
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => HomePage(title: title)));
  }

  void signInWithPhoneNumber() async {}

  customSnackBar(String text) {
    return ScaffoldMessenger(child: SnackBar(content: Text(text)));
  }

  startTimer() {
    const onesec = Duration(seconds: 1);
    _timer = Timer.periodic(onesec, (Timer timer) {
      if (seconds == 0) {
        timer.cancel();
        setState(() {
          _btnEnabled = true;
          color = Colors.green;
          buttonText = "Send OTP";
          seconds = 30;
        });
      } else {
        setState(() {
          seconds -= 1;
        });
      }
    });
  }
}
