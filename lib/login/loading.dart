import 'package:flutter/material.dart';
import 'package:mist_app/home.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:mist_app/login/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mist_app/theme/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Loading extends StatefulWidget {
  @override
  _Loading createState() => _Loading();
}

class _Loading extends State<Loading> {
  CollectionReference login = FirebaseFirestore.instance.collection('login');
  CollectionReference account = FirebaseFirestore.instance.collection('user');
  var email;

  Future<void> getUser() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email');
    loadApiKey();
  }

  loadApiKey(){
    account.doc('$email').get().then((DocumentSnapshot documentSnapshot) {
      id = documentSnapshot['api_key'].toString();
    });
  }

  SwitchWidget(){
    new Future.delayed(new Duration(milliseconds: 1500), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => email == null ? Login() : Home()),
      );
    });
  }

  @override
  void initState() {
    getUser();
    SwitchWidget();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/logo.gif', width: 200, color: AppColors.tertiary,),
      ),
      bottomNavigationBar: Container(
        height: 65,
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            Text('From', style: TextStyle(fontSize: 15, color: Colors.grey)),
            Text('3Cs Lab', style: TextStyle(fontSize: 20, color: AppColors.tertiary)),
          ],
        ),
      )
    );
  }
}