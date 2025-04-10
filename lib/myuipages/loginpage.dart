import 'package:flutter/material.dart';
import 'package:medrhythms/mypages/readroutes.dart';
import 'package:medrhythms/myuipages/sessions_page.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/helpers/usersession.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController imeiController = TextEditingController();
  final FirestoreServiceRead firestoreService = FirestoreServiceRead();

  bool isLoading = false;
  String errorMessage = '';

  void login() async {
    String imei = imeiController.text.trim();

    if (imei.isEmpty) {
      setState(() {
        errorMessage = "IMEI cannot be empty";
      });
      return;
    }
    //IMEI number must be 15 digits
    if (imei.length != 15){
      setState(() {
        errorMessage = "IMEI must be 15 digits";
      });
      return;
    }
    //IMEI can only be digits
    if (!RegExp(r'^[0-9]{15}$').hasMatch(imei)){
    setState(() {
      errorMessage = "IMEI must contain only digits!";
    });
    return;
    }
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      var userData = await firestoreService.checkUserSessionRegistry(imei);

      if (userData != null && userData.containsKey("userId")) {
        UserSession().userId = userData["userId"];
        UserSession().userData = userData;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/sessions',
          (route) => false,
          arguments: {
            'uuid': userData["userId"],
            'userData': userData,
          },
        );
      } else {
        setState(() {
          errorMessage = "User not found or error occurred";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MedRhythmsAppBar(),
        body: Container(
            height: double.infinity,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: imeiController,
                  decoration: InputDecoration(
                    labelText: "Enter IMEI",
                    border: OutlineInputBorder(),
                    errorText: errorMessage.isNotEmpty ? errorMessage : null,
                  ),
                ),
                SizedBox(height: 20),
                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: login,
                        child: Text("Login"),
                      ),
              ],
            )));
  }
}
