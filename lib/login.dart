import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:phone_authentication/home.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  final formkey = GlobalKey<FormState>();

  TextEditingController otp = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  int timeCount = 60;
  String verID = "";
  int screenState = 0;
  String countryDial = "+91";
  String pinCode = '';
  bool isResend = false;
  bool isVerify = false;
  bool isComplete = false;

  Timer? timer;

  void StartTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeCount != 0) {
        setState(() {
          timeCount--;
        });
      } else {
        setState(() {
          isResend = true;
          timer.cancel();
        });
      }
    });
  }

  Future<void> verifyPhone(String number) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      timeout: Duration(minutes: 1),
      verificationCompleted: (PhoneAuthCredential credential) async {
        setState(() {
          otp.text = credential.smsCode.toString();
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          showSnackBarText("The Provided Phone Number is Not Valid.");
          setState(() {
            screenState = 0;
            timeCount = 60;
            isResend = false;
            timer!.cancel();
          });
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        showSnackBarText("OTP Sent!");
        verID = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        showSnackBarText("Timeout!");
      },
    );
  }

  void showSnackBarText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  Future<void> verifyOTP() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verID,
        smsCode: pinCode,
      );
      auth.signInWithCredential(credential).then((result) {
        if (result.user != null) {
          setState(() {
            timer!.cancel();
          });
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Home()),
              (route) => false);
        }
      }).catchError((e) {
        print(e);
        showSnackBarText("Incorrect OTP!, Try Again");
      });
    } catch (e) {
      print("rrrrrrr$e");
    }
  }

  @override
  dispose() {
    timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(143, 148, 251, .2),
                    blurRadius: 20.0,
                    // offset: Offset(0, 10),
                  )
                ],
              ),
              child: Form(
                key: formkey,
                child: Column(
                  children: [
                    screenState == 1
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "OTP Send This Number ",
                                style: TextStyle(fontSize: 14),
                              ),
                              Text("$countryDial${phoneController.text}",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.green)),
                            ],
                          )
                        : Container(),
                    SizedBox(height: screenState == 1 ? 4 : 0),
                    screenState == 1
                        ? InkWell(
                            onTap: () {
                              setState(() {
                                screenState = 0;
                                timeCount = 60;
                                timer!.cancel();
                              });
                            },
                            child: Text("Change Number",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.green)),
                          )
                        : Container(),
                    screenState == 0
                        ? Container(
                            padding: EdgeInsets.all(8.0),
                            margin: EdgeInsets.only(top: 6, bottom: 6),
                            child: IntlPhoneField(
                              invalidNumberMessage: '',
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              showCountryFlag: true,
                              flagsButtonPadding:
                                  EdgeInsets.only(left: 20, right: 10),
                              showDropdownIcon: false,
                              // disableLengthCheck: true,
                              initialValue: countryDial,
                              // enabled: false,
                              onCountryChanged: (country) {
                                setState(() {
                                  countryDial = "+" + country.dialCode;
                                });
                              },
                              validator: (p0) {
                                setState(() {
                                  if (p0!.isValidNumber()) {
                                    isComplete = true;
                                  }
                                });
                                return "";
                              },
                              // autovalidateMode: AutovalidateMode.always,
                              decoration: InputDecoration(
                                  counterText: "",
                                  hintText: "Enter Number",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5),
                                  ),
                                  contentPadding:
                                      EdgeInsets.fromLTRB(20, 0, 0, 0)),
                            ),
                          )
                        : Container(
                            padding:
                                EdgeInsets.only(left: 6, right: 6, top: 14),
                            child: PinCodeTextField(
                              appContext: context,
                              pastedTextStyle: TextStyle(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                              length: 6,
                              obscureText: false,
                              enablePinAutofill: true,
                              animationType: AnimationType.fade,
                              pinTheme: PinTheme(
                                shape: PinCodeFieldShape.box,
                                borderRadius: BorderRadius.circular(4),
                                fieldHeight: 40,
                                fieldWidth: 40,
                                inactiveFillColor: Colors.white,
                                inactiveColor: Color(0xFF8F94FB),

                                selectedColor: Color(0xFF8F94FB),
                                selectedFillColor: Colors.white,
                                activeFillColor: Colors.white,
                                // activeColor:
                                //     ColorUtils.greyBorderColor,
                              ),
                              // cursorColor: app_color,
                              animationDuration: Duration(milliseconds: 150),
                              enableActiveFill: true,
                              controller: otp,
                              keyboardType: TextInputType.number,
                              boxShadows: [
                                BoxShadow(
                                  offset: Offset(0, 1),
                                  color: Colors.black12,
                                  blurRadius: 10,
                                )
                              ],
                              onCompleted: (v) {
                                verificationDailog();
                                verifyOTP();
                                setState(() {
                                  isVerify = true;
                                });
                              },
                              onChanged: (value) {
                                print(value);
                                setState(() {
                                  pinCode = value;
                                  print(pinCode);
                                });
                              },
                            )),
                    screenState == 1
                        ? Padding(
                            padding:
                                EdgeInsets.only(left: 4, right: 4, bottom: 2),
                            child: Row(
                              children: [
                                isResend == true
                                    ? InkWell(
                                        onTap: () {
                                          verifyPhone(countryDial +
                                              phoneController.text);
                                          StartTimer();
                                          setState(() {
                                            isResend = false;
                                            timeCount = 60;
                                          });
                                        },
                                        child: Text(
                                          "Resend",
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 16),
                                        ),
                                      )
                                    : Container(),
                                Spacer(),
                                isResend == false
                                    ? Text(
                                        timeCount < 10
                                            ? "00:0$timeCount"
                                            : "00:$timeCount",
                                        style: TextStyle(
                                            color: Colors.green, fontSize: 16),
                                      )
                                    : Container(),
                              ],
                            ),
                          )
                        : Container()
                  ],
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            screenState == 0 && isVerify == false || isVerify == true
                ? GestureDetector(
                    onTap: () {
                      if (screenState == 0) {
                        if (phoneController.text.length == 0) {
                          showSnackBarText("Enter Mobile Number");
                        } else if (!isComplete) {
                          showSnackBarText("Enter Mobile Number Correctly");
                        } else {
                          verifyPhone(countryDial + phoneController.text);
                          StartTimer();
                          setState(() {
                            screenState = 1;
                            timeCount = 60;
                          });
                        }
                      } else {
                        if (pinCode.length >= 6) {
                          verifyOTP();
                        } else {
                          showSnackBarText("Enter OTP Correctly!");
                        }
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: 50,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(colors: [
                            Color.fromARGB(255, 140, 241, 152),
                            Color.fromARGB(153, 139, 240, 126),
                          ])),
                      child: Text(
                        screenState == 0 ? "Send OTP" : "Verify OTP",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : Container(),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
          ],
        ),
      ),
    );
  }

  verificationDailog() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(children: [
              SizedBox(
                width: 4,
              ),
              CircularProgressIndicator(),
              SizedBox(
                width: 8,
              ),
              Text("OTP Verification..."),
            ]),
          );
        });
  }
}
