import 'dart:convert' as cnv;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mist_app/login/login.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mist_app/theme/constant.dart';
import 'package:connectivity/connectivity.dart';

class Registration extends StatefulWidget {
  @override
  _Registration createState() => _Registration();
}

class _Registration extends State<Registration> {
  final textUserName = TextEditingController();
  final textEmail = TextEditingController();
  final textPass = TextEditingController();
  final textPassConfirm = TextEditingController();
  final textPassAdmin = TextEditingController();

  bool _passwordVisible = false;
  bool _passwordVisibleConfirm = false;
  bool _passwordVisibleAdmin = false;
  bool colorUserName = false;
  bool colorAccount = false;
  bool colorPass = false;
  bool colorPassConfirm = false;
  bool colorPassAdmin = false;
  bool checkBox = false;
  bool checkButton = false;
  bool checkPassAdmin = false;
  bool _isConnected = false;

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

  @override
  void initState() {
    super.initState();
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
        child:  Stack(
          children: [
            ListView(
                padding: EdgeInsets.all(20),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    child: Image.asset('assets/logo.png', height: 120,color: Colors.white,),
                  ),
                  Center(
                    child: Text('Đăng ký tài khoản',
                        style: TextStyle(fontSize: 40, color: Colors.white),
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(height: 20),
                  Padding(
                      padding: EdgeInsets.fromLTRB(35,0,35,50),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            UserName(),
                            SizedBox(height: 15),
                            Email(),
                            SizedBox(height: 15),
                            Password(),
                            SizedBox(height: 15),
                            PasswordConfirm(),
                            SizedBox(height: 15),
                            PasswordAdmin(),
                            SizedBox(height: 15),
                          ],
                        ),
                      )

                  )
                ]
            ),
            (WidgetsBinding.instance!.window.viewInsets.bottom <= 0.0)
                ? Padding(
                padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.2,0,MediaQuery.of(context).size.width * 0.2,20),
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
      )
    );
  }

  Widget UserName(){
    return TextFormField(
      onTap: (){
        setState(() {
          colorPassConfirm = false;
          colorUserName = true;
          colorAccount = false;
          colorPass = false;
          colorPassAdmin = false;
        });
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val){
        if (checkButton){
          if (val!.isEmpty) {
            return '* Nhập tên người dùng';
          }
        }
      },
      decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorUserName)
              ? Colors.white
              : null,
          hintStyle: TextStyle(fontSize: 17,
              color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorUserName)
                  ? AppColors.tertiary
                  : Colors.white),
          hintText: 'Tên người dùng',
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
                Image.asset('assets/username.png',width: 30,
                    color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorUserName)
                        ? AppColors.tertiary
                        : Colors.white),
                SizedBox(width: 10),
                Container(
                  height: 28,
                  width: 1,
                  color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorUserName)
                      ? AppColors.tertiary
                      : Colors.white,
                )
              ],
            ),
          ),
      ),
      style: TextStyle(fontSize: 17, height: 1.2, color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorUserName)
          ? AppColors.tertiary
          : Colors.white),
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      controller: textUserName,
      cursorColor: AppColors.tertiary,
    );
  }

  Widget Email(){
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      onTap: (){
        setState(() {
          colorPassConfirm = false;
          colorAccount = true;
          colorPass = false;
          colorUserName = false;
          colorPassAdmin = false;
        });
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val){
        if (checkButton){
          if (val == null || val.isEmpty) {
            return '* Nhập email';
          }
          const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
          final regExp = RegExp(pattern);

          if (!regExp.hasMatch(val)) {
            return '* Nhập đúng dạng email';
          }
          return null;
        }
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
      controller: textEmail,
      cursorColor: AppColors.tertiary,
    );
  }

  Widget Password(){
    return TextFormField(
      onTap: (){
        setState(() {
          colorPassConfirm = false;
          colorAccount = false;
          colorUserName = false;
          colorPass = true;
          colorPassAdmin = false;
        });
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val){
        if (checkButton){
          if(val!.isEmpty){
            return "* Nhập mật khẩu";
          }
          if(val.length < 6){
            return "* Mật khẩu ít nhất cần 6 ký tự";
          }
        }
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

  Widget PasswordConfirm(){
    return TextFormField(
      onTap: (){
        setState(() {
          colorPassConfirm = true;
          colorAccount = false;
          colorUserName = false;
          colorPass = false;
          colorPassAdmin = false;
        });
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val){
        if (checkButton){
          if(val!.isEmpty){
            return "* Nhập mật khẩu";
          }
          if(val.toString() != textPass.text){
            return "* Nhập lại mật khẩu sai";
          }
        }
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassConfirm)
            ? Colors.white
            : null,
        hintStyle: TextStyle(fontSize: 17,
            color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassConfirm)
                ? AppColors.tertiary
                : Colors.white),
        hintText: 'Nhập lại mật khẩu',
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
              Image.asset('assets/confirmpass.png',width: 30,
                  color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassConfirm)
                      ? AppColors.tertiary
                      : Colors.white),
              SizedBox(width: 10),
              Container(
                height: 28,
                width: 1,
                color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassConfirm)
                    ? AppColors.tertiary
                    : Colors.white,
              )
            ],
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisibleConfirm
                ? Icons.visibility
                : Icons.visibility_off,
            color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassConfirm)
                ? Colors.grey
                : Colors.white,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _passwordVisibleConfirm = !_passwordVisibleConfirm;
            });
          },
        ),
      ),
      style: TextStyle(fontSize: 17, height: 1.2,
          color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassConfirm)
              ? AppColors.tertiary
              : Colors.white),
      obscureText: !_passwordVisibleConfirm,
      textAlign: TextAlign.left,
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      controller: textPassConfirm,
      cursorColor: AppColors.tertiary,
    );
  }

  Widget PasswordAdmin(){
    return TextFormField(
      onTap: (){
        setState(() {
          colorPassConfirm = false;
          colorAccount = false;
          colorUserName = false;
          colorPass = false;
          colorPassAdmin = true;
        });
      },
      validator: (val){
        if (checkButton){
          if(val!.isEmpty){
            return "* Nhập mã đăng ký";
          }
          if (checkPassAdmin) {
            return "* Mã đăng ký không hợp lệ";
          }
        }
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassAdmin)
            ? Colors.white
            : null,
        hintStyle: TextStyle(fontSize: 17,
            color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassAdmin)
                ? AppColors.tertiary
                : Colors.white),
        hintText: 'Mã đăng ký',
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
              Image.asset('assets/adminpass.png',width: 30,
                  color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassAdmin)
                      ? AppColors.tertiary
                      : Colors.white),
              SizedBox(width: 10),
              Container(
                height: 28,
                width: 1,
                color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassAdmin)
                    ? AppColors.tertiary
                    : Colors.white,
              )
            ],
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisibleAdmin
                ? Icons.visibility
                : Icons.visibility_off,
            color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassAdmin)
                ? Colors.grey
                : Colors.white,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _passwordVisibleAdmin = !_passwordVisibleAdmin;
            });
          },
        ),
      ),
      style: TextStyle(fontSize: 17, height: 1.2,
          color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorPassAdmin)
              ? AppColors.tertiary
              : Colors.white),
      obscureText: !_passwordVisibleAdmin,
      textAlign: TextAlign.left,
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      controller: textPassAdmin,
      cursorColor: AppColors.tertiary,
    );
  }

  Widget RegistrationButton(){
    return ElevatedButton(
      onPressed: () async {
        if (_isConnected == false) {
          notification('Không có kết nối Internet !!!');
        } else {
          setState(() {
            checkButton = true;
          });
          if (textPassAdmin.text != ''){
            CollectionReference collectionReference =
            FirebaseFirestore.instance.collection("${textPassAdmin.text}");
            QuerySnapshot querySnapshot = await collectionReference.get();
            if (!querySnapshot.docs.isNotEmpty){
              setState(() {
                checkPassAdmin = true;
              });
            } else
              setState(() {
                checkPassAdmin = false;
              });
          }
          if (_formKey.currentState!.validate()) {
            setState(() {
              id = textPassAdmin.text;
            });
            SendAcount();
          }
        }
      },
      child: Container(
          height: 50,
          width: MediaQuery.of(context).size.width*0.5,
          child: Center(
            child: Text('Đăng ký tài khoản',
                style: TextStyle(fontSize: 17, color:  Colors.white)),
          )
      ),
      style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25)), elevation: 2, primary: AppColors.tertiary),
    );
  }

  void SendAcount()  {
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
                    Text("Đang đăng ký...",style: TextStyle(fontSize: 15)),
                  ],
                ),
              )
          ),
        );
      },
    );
    Future.delayed(Duration(seconds: 2), () async {
      Navigator.of(context).pop();
      try {
        CollectionReference account = FirebaseFirestore.instance.collection('user');
        final user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: textEmail.text, password: textPass.text);
        user.user!.sendEmailVerification();
        account.doc('${textEmail.text}').set({
          'apikey': textPassAdmin.text,
          'password': textPass.text,
          'name': textUserName.text,
        });
        FirebaseAuth.instance.currentUser!.updateDisplayName(textUserName.text);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: new Padding(
                  padding: EdgeInsets.fromLTRB(0,15,0,3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/checked.png', width: 50),
                      SizedBox(height: 15),
                      new Text("Kiểm tra email để xác minh tài khoản"),
                      SizedBox(height: 5),
                      TextButton(
                        child: Text('Xác nhận', style: TextStyle(fontSize: 18),),
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Login()),
                          );
                        },
                      )
                    ],
                  ),
                )
            );
          },
        );
      } on FirebaseAuthException catch (e) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            title:
            Text('Ôi bạn ơi !!!'),
            content: Text('Email này đã được sử dụng cho tài khoản khác'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop;
                },
                child: Text('Xác nhận'),
              )
            ],
          ),
        );
      }
    });
  }
}