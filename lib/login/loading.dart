import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mist_app/home.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:mist_app/login/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mist_app/theme/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity/connectivity.dart';

class Loading extends StatefulWidget {
  @override
  _Loading createState() => _Loading();
}

class _Loading extends State<Loading> {

  bool _isConnected = false;

  CollectionReference account = FirebaseFirestore.instance.collection('user');
  var email;

  checkConnectivty() async{
    var result = await Connectivity().checkConnectivity();
    switch(result){
      case ConnectivityResult.wifi:
        setState(() {
          _isConnected = true;
        });
        break;
      case ConnectivityResult.mobile:
        setState(() {
          _isConnected = true;
        });
        break;
      case ConnectivityResult.none:
        setState(() {
          _isConnected = false;
        });
    }
  }

  void notification(String s){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$s',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      backgroundColor: Color(0xff898989),
      duration: Duration(seconds: 3),
      shape: StadiumBorder(),
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ));
  }

  Future<void> getUser() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email');
    if (_isConnected == false) {
      notification('Không có kết nối Internet !!!');
    } else loadApiKey();
  }

  loadApiKey() async {
    if (email == null){
      new Future.delayed(new Duration(milliseconds: 1500), () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Login()
            ));
      });
    }
    if (email != null){
      account.doc('$email').get().then((DocumentSnapshot documentSnapshot) {
        int dem = 0;
        do {
          setState(() {
            id = documentSnapshot['apikey'].toString();
          });
          dem++;
        }
        while (id == '' && dem < 10000);
        if (id != ''){
          new Future.delayed(new Duration(milliseconds: 1500), () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Home())
            );
          });
        }
      });
    }
  }

  @override
  void initState() {
    checkConnectivty();
    getUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/logo.gif', width: 200, color: AppColors.tertiary,),
      ),
      bottomNavigationBar: Container(
        height: 70,
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
