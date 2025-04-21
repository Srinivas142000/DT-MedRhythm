import 'package:flutter/material.dart';
import 'package:medrhythms/helpers/datasyncmanager.dart';
import 'package:medrhythms/mypages/readroutes.dart';
import 'package:medrhythms/myuipages/sessions_page.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/helpers/usersession.dart';

/**
 * Login page for MEDRhythms app.
 * Handles IMEI input, validation, and user session setup.
 * @extends {StatefulWidget}
 * A StatefulWidget that represents the login page of the app.
 * It allows the user to input their IMEI number and attempts to log them in.
 * If the IMEI is valid, it navigates to the Sessions page.
 */
class LoginPage extends StatefulWidget {
  /**
   * Constructs a [LoginPage].
   * @param {Key?} [key] Optional widget key.
   */
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

/**
 * State for [LoginPage].
 * Manages IMEI input, loading state, and navigation on successful login.
 * @extends {State<LoginPage>}
 */
class _LoginPageState extends State<LoginPage> {
  /** Controller for the IMEI text field. @type {TextEditingController} */
  final TextEditingController imeiController = TextEditingController();

  /** Firestore service for reading user session registry. @type {FirestoreServiceRead} */
  final FirestoreServiceRead firestoreService = FirestoreServiceRead();

  /** Manager for syncing local data to backend. @type {DataSyncManager} */
  final DataSyncManager dsm = DataSyncManager();

  /** Indicates whether a login request is in progress. @type {boolean} */
  bool isLoading = false;

  /** Error message to display under the IMEI field. @type {string} */
  String errorMessage = '';

  /**
   * Validates the IMEI and attempts to log in the user.
   * - Checks for non-empty, 15-digit numeric IMEI.
   * - Queries Firestore for existing user session.
   * - Uploads any pending local data.
   * - Navigates to the sessions page on success.
   *
   * @returns {Future<void>} Completes when login process finishes.
   * @private
   * Attempts to log the user in based on their IMEI number.
   * It validates the IMEI input and checks the user session registry.
   * If successful, it navigates to the Sessions page and uploads any pending data.
   * 
   * If there is any error (invalid IMEI or user not found), it displays an error message.
   */
  void login() async {
    String imei = imeiController.text.trim();

    // Validate IMEI presence
    if (imei.isEmpty) {
      setState(() {
        errorMessage = "IMEI cannot be empty";
      });
      return;
    }
    // Validate IMEI length
    if (imei.length != 15) {
      setState(() {
        errorMessage = "IMEI must be 15 digits";
      });
      return;
    }
    // Validate IMEI numeric format
    if (!RegExp(r'^[0-9]{15}$').hasMatch(imei)) {
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
      // Fetch or create user session in Firestore
      var userData = await firestoreService.checkUserSessionRegistry(imei);
      // Upload any pending local data first

      // Check if any past data is not uploaded
      await dsm.upload();

      if (userData != null && userData.containsKey("userId")) {
        // Save session info and navigate
        UserSession().userId = userData["userId"];
        UserSession().userData = userData;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/sessions',
          (route) => false,
          arguments: {'uuid': userData["userId"], 'userData': userData},
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
            /**
             * IMEI input field.
             * Displays [errorMessage] when non-empty.
             * IMEI input field where the user enters their IMEI number.
             * Displays an error message if the input is invalid.
             */
            TextField(
              controller: imeiController,
              decoration: InputDecoration(
                labelText: "Enter IMEI",
                border: OutlineInputBorder(),
                errorText: errorMessage.isNotEmpty ? errorMessage : null,
              ),
            ),
            SizedBox(height: 20),
            /**
             * Login button or loading indicator.
             * Calls [login] when pressed.
             * Displays either a loading indicator or the login button,
             * depending on the value of isLoading.
             */
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: login,
                    child: Text("Login"),
                  ),
          ],
        ),
      ),
    );
  }
}