//import for all the necessary packages
import 'package:flutter/material.dart';
import 'package:medrhythms/mypages/readroutes.dart';
import 'package:medrhythms/myuipages/home_page.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';

//Widget for the login page
class LoginPage extends StatefulWidget{
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}
//State class for login page
class _LoginPageState extends State<LoginPage> {
  //Controller for the IMEI input field
  final TextEditingController imeiController = TextEditingController();
  //Instance of FirestoreServiceRead to interact with the Firestore DB
  final FirestoreServiceRead firestoreService = FirestoreServiceRead();
  //Used a boolean to indicate the loading state during a login attempt by a user
  bool isLoading = false;
  String errorMessage = '';

  //Method to handle user login with IMEI number
  void login() async{
    String imei = imeiController.text.trim();
    //To check if the Imei field is empty and then display an error message if it is
    if (imei.isEmpty){
      setState(() {
        errorMessage = "IMEI cannot be empty";
      });
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try{
      //To check user data from the DB based on the IMEI they entered
      var userData = await firestoreService.checkUserSessionRegistry(imei);
      //If valid it proceeds to the home page
      if(userData != null && userData.containsKey("userId")){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userData : userData),
          ),
        );
      }else{
        //displays an error text if the user is not found or if there is an error
        setState(() {
          errorMessage = "User not found or error occured";
        });
      }
    }catch (e){
      setState(() {
        errorMessage = "Error: ${e.toString()}";
      });
    }finally{
      //Reset the loading state after the login attempt is d
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: MedRhythmsAppBar(),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            TextField(
              controller: imeiController,
              decoration:  InputDecoration(
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
        )
      )
    );
  }
}