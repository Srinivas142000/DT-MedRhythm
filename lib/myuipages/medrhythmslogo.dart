import 'package:flutter/material.dart';
//Widget for AppBar that is reusable
class MedRhythmsAppBar extends StatelessWidget implements PreferredSizeWidget{
  @override
  Widget build(BuildContext context){
    return AppBar(
      backgroundColor: Colors.green,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/images/logo.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}