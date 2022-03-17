import 'dart:async';
import 'dart:convert' as cnv;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mist_app/home.dart';
import 'package:mist_app/login/forgot_password.dart';
import 'package:mist_app/login/registration.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mist_app/theme/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:mist_app/network_request/user_model.dart';
import 'package:mist_app/check_connect.dart';
import 'package:connectivity/connectivity.dart';

class Login extends StatefulWidget {
  @override
  _Login createState() => _Login();
}

class _Login extends State<Login> {
  final textAccount = TextEditingController();
  final textPass = TextEditingController();

  bool _isConnected = false;
  bool _passwordVisible = false;
  bool colorAccount = false;
  bool colorPass = false;
  bool checkBox = false;
  bool checkButton = false;
  bool checkPassFaild = false;
  bool checkAccountFaild = false;
  bool checkSignInFaild = false;

  List<CheckConnect>? modelconnect;

  CollectionReference account = FirebaseFirestore.instance.collection('user');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  void notification(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$s',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      backgroundColor: Color(0xff898989),
      duration: Duration(milliseconds: 1500),
      shape: StadiumBorder(),
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ));
  }
  int demcheckdata = 0;

  void getDataHttp(String id) async {
    var response = await Dio().getUri(Uri.http('192.168.16.2', '/getweighttemp', {'api_key': '$id'}));
    if (response.statusCode == 200){
      List<dynamic> body = cnv.jsonDecode(response.data);
      model = body.map((dynamic item) => UserModel.fromJson(item)).cast<UserModel>().toList();
      setState(() {
        temp = int.parse(model![0].temp.toString());
        loadcell = int.parse(model![0].loadcell.toString());
      });

      if (model![0].loadcell.toString() == '1'){
        while (demcheckdata < 1){
          demcheckdata++;
          var check = await Dio().getUri(Uri.http('192.168.16.2', '/checkconnect', {'api_key': '$id'}));
          if (check.statusCode == 200){
            List<dynamic> body = cnv.jsonDecode(check.data);
            modelconnect = body.map((dynamic item) => CheckConnect.fromJson(item)).cast<CheckConnect>().toList();
            if (modelconnect![0].datastate.toString() == '1'){
              updateHistoryToFireStore(id);
              sendData('response',{'api_key': '$id',
                'rescode':'2',  //dữ liệu đã được ghi
              });
            } else
              sendData('response',{'api_key': '$id',
                'rescode':'1',   //dữ liệu chưa được ghi
              });
          }
        }
      }
    }
  }

  updateHistoryToFireStore(String id) async {
    CollectionReference machine = FirebaseFirestore.instance.collection('$id');
    QuerySnapshot querySnapshot = await machine.doc('history').
    collection('${modelconnect![0].monthstart}').
    doc('${modelconnect![0].monthstart}').
    collection('${modelconnect![0].daystart}').get();
    List<DocumentSnapshot> _myDocCount = querySnapshot.docs;
    int seconds = int.parse(modelconnect![0].runtime.toString()) % 60;
    int minutes = (int.parse(modelconnect![0].runtime.toString()) % (3600)) ~/ 60;
    int hours = int.parse(modelconnect![0].runtime.toString()) ~/ (3600);
    machine.doc('history').
    collection('${modelconnect![0].yearstart}').
    doc('${modelconnect![0].monthstart}').
    collection('${modelconnect![0].daystart}').doc('${_myDocCount.length}').set({
      'date_created': '${modelconnect![0].yearstart}/${modelconnect![0].monthstart.toString().padLeft(2, '0')}/${modelconnect![0].daystart.toString().padLeft(2, '0')} ${modelconnect![0].timestart}',
      'room_name': '${modelconnect![0].roomname}',
      'run_time': '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      'status': '${modelconnect![0].errorcode}'
    });
  }

  void sendData(String mode, final dataSend)async  {
    Dio().getUri(Uri.http('192.168.16.2','/$mode',dataSend));
  }

  @override
  Widget build(BuildContext context) {
    checkConnectivty();
    return Scaffold(
        body: Container(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
              image: DecorationImage(
                image:  AssetImage('assets/headerdrawer.png'),
                fit: BoxFit.cover)),
          child: Stack(
            children: [
              ListView(
                  padding: EdgeInsets.all(20),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 30),
                      child: Image.asset('assets/logo.png', height: 200,color: Colors.white,),
                    ),
                    Padding(
                        padding: EdgeInsets.fromLTRB(35,0,35,10),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Email(),
                              SizedBox(height: 10),
                              Password(),
                              SizedBox(height: 10),
                              RememberMe(),
                              SizedBox(height: 30),
                              SignInButton(),
                              SizedBox(height: 50),
                            ],
                          ),
                        )
                    )
                  ]
              ),
              (WidgetsBinding.instance!.window.viewInsets.bottom <= 0.0)
                  ? Padding(
                  padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.3,0,MediaQuery.of(context).size.width * 0.3,20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(),
                      RegistrationButton(),
                    ],
                  )
              )
                  : Container()
            ],
          ),
        ),
    );
  }

  Widget Email(){
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      onTap: (){
        setState(() {
          colorAccount = true;
          colorPass = false;
        });
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val){
        if (checkButton){
          const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
          final regExp = RegExp(pattern);
          if (val == null || val.isEmpty) {
            return '* Nhập email';
          }
          if (!regExp.hasMatch(val)) {
            return '* Nhập đúng dạng email';
          }
          if (checkAccountFaild){
            return '* Không tìm thấy người dùng';
          }
        }
        return null;
      },
      decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorAccount)
              ? Colors.white
              : null,
          hintStyle: TextStyle(fontSize: 17,
              color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorAccount)
                  ? AppColors.tertiary
                  : Colors.white),
          hintText: 'Email',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white, width: 1),
          ),
          enabledBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.white, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(width: 1,color: Colors.white),
          ),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(width: 1,color: Colors.red)
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 10),
                Image.asset('assets/account.png',width: 30,
                    color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorAccount)
                        ? AppColors.tertiary
                        : Colors.white),
                SizedBox(width: 10),
                Container(
                  height: 28,
                  width: 1,
                  color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorAccount)
                      ? AppColors.tertiary
                      : Colors.white,
                )
              ],
            ),
          ),
      ),
      style: TextStyle(fontSize: 17, height: 1.2, color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorAccount)
          ? AppColors.tertiary
          : Colors.white),
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      controller: textAccount,
      cursorColor: AppColors.tertiary,
    );
  }

  Widget Password(){
    return TextFormField(
      onTap: (){
        setState(() {
          colorPass = true;
          colorAccount = false;
        });
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val){
        if (checkButton){
          if(val!.isEmpty){
            return '* Nhập mật khẩu';
          }
          else if(val.length < 6){
            return '* Mật khẩu ít nhất cần 6 ký tự';
          }
          else if(!val.contains(RegExp(r'[0-9]'))){
            return '* Mật khẩu cần ít nhất 1 số';
          }
          else if (checkPassFaild){
              return '* Mật khẩu không hợp lệ';
            }
        }
        return null;
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPass)
            ? Colors.white
            : null,
        hintStyle: TextStyle(fontSize: 17,
            color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPass)
                ? AppColors.tertiary
                : Colors.white),
        hintText: 'Mật khẩu',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Colors.white, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(width: 1,color: Colors.white),
        ),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(width: 1,color: Colors.red)
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 10),
              Image.asset('assets/pass.png',width: 30,
                  color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPass)
                      ? AppColors.tertiary
                      : Colors.white),
              SizedBox(width: 10),
              Container(
                height: 28,
                width: 1,
                color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPass)
                    ? AppColors.tertiary
                    : Colors.white,
              )
            ],
          ),
        ),
        suffixIcon: IconButton(
          splashRadius: 17,
          icon: Icon(
            _passwordVisible
                ? Icons.visibility
                : Icons.visibility_off,
            color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPass)
                ? Colors.grey
                : Colors.white,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
        ),
      ),
      style: TextStyle(fontSize: 17, height: 1.2,
          color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPass)
              ? AppColors.tertiary
              : Colors.white),
      obscureText: !_passwordVisible,
      textAlign: TextAlign.left,
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      controller: textPass,
      cursorColor: AppColors.tertiary,
    );
  }

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.white;
  }

  Widget RememberMe(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(5,0,5,0),
              height: 20,
              width: 20,
              child: Checkbox(
                checkColor: AppColors.tertiary,
                fillColor: MaterialStateProperty.resolveWith(getColor),
                value: checkBox,
                onChanged: (bool? value) {
                  setState(() {
                    checkBox = value!;
                  });
                },
              ),
            ),
            Text('Duy trì đăng nhập', style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        TextButton(
            onPressed: (){
              if (_isConnected == false) {
                notification('Không có kết nối Internet !!!');
              } else
              Navigator.of(context).push(
                MaterialPageRoute(builder: (contex) => ForgotPassword(),
                ),
              );
            },
            child: Text('Quên mật khẩu?',
                style: TextStyle(color: Colors.white, fontSize: 13,
                  decoration: TextDecoration.underline,)),
        )
      ],
    );
  }

  Widget SignInButton(){
    return ElevatedButton(
      onPressed: () async {
        if (_isConnected == false) {
          notification('Không có kết nối Internet !!!');
        } else {
          setState(() {
            checkButton = true;
            checkPassFaild = false;
            checkAccountFaild = false;
            checkSignInFaild = false;
          });
          if (_formKey.currentState!.validate()) {
            account.doc('${textAccount.text}').get().then((DocumentSnapshot documentSnapshot) async {
              getDataHttp(documentSnapshot['apikey'].toString());
              SignIn();
            });
          };
        }
      },
      child: Container(
          height: 50,
          width: MediaQuery.of(context).size.width*0.5,
          child: Center(
            child: Text('Đăng nhập',
                style: TextStyle(fontSize: 17, color:  Colors.white)),
          )
      ),
      style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25)), elevation: 2, primary: AppColors.tertiary),
    );
  }

  Future<void> SignIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Container(
          width: 100,
          height: 100,
          child: Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 120),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(0,20,0,20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Đang đăng nhập...",style: TextStyle(fontSize: 15)),
                  ],
                ),
              )
          ),
        );
      },
    );
    try {
      final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: textAccount.text, password: textPass.text);
      if (user.user!.emailVerified) {
        if (!checkPassFaild && !checkAccountFaild && !checkSignInFaild){
          int dem = 0;
          account.doc('${textAccount.text}').get().then((DocumentSnapshot documentSnapshot) async {
            do {
              setState(() {
                id = documentSnapshot['apikey'].toString();
              });
              dem++;
            }
            while (id == '' && dem < 10000);
            if (id != ''){
              account.doc('${textAccount.text}').set({
                'password': '${textPass.text}',
                'apikey': id,
                'name': user.user!.displayName
              });
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (contex) => Home(),
                ),
              );
              if (checkBox){
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setString('email', textAccount.text);
              }
            }
          });
        }
      }
      else {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            title: Text("Ôi bạn ơi"),
            content: Text('Tài khoản chưa được xác minh'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Xác nhận'),
              )
            ],
          ),
        );
      };
    } on FirebaseAuthException catch (e) {
      if (e.message == 'The password is invalid or the user does not have a password.'){
        setState(() {
          checkPassFaild = true;
        });
      }
      if (e.message == 'There is no user record corresponding to this identifier. The user may have been deleted.') {
        setState(() {
          checkAccountFaild = true;
        });
      }
      if (e.message == 'We have blocked all requests from this device due to unusual activity. Try again later.') {
        setState(() {
          checkSignInFaild = true;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            title: Text("Ôi bạn ơi"),
            content: Text('Lỗi đăng nhập mất rồi. Vui lòng thử lại sau vài phút :('),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text('Xác nhận'),
              )
            ],
          ),
        );
      }
      Navigator.of(context).pop();
    }
  }

  Widget RegistrationButton(){
    return OutlinedButton(
      onPressed: () {
        if (_isConnected == false) {
          notification('Không có kết nối Internet !!!');
        } else
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Registration()),
        );
      },
      child: Container(
          height: 34,
          width: MediaQuery.of(context).size.width*0.5,
          child: Center(
            child: Text('Đăng ký',
                style: TextStyle(fontSize: 15, color:  Colors.white)),
          )
      ),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
        primary: Colors.orange, // foreground text
        side: BorderSide(color: Colors.white), // foreground border
      ),
    );
  }
}