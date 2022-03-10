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
import 'package:mist_app/theme/namedisplay_and_id.dart';

class Login extends StatefulWidget {
  @override
  _Login createState() => _Login();
}

class _Login extends State<Login> {
  final textAccount = TextEditingController();
  final textPass = TextEditingController();

  bool _passwordVisible = false;
  bool colorAccount = false;
  bool colorPass = false;
  bool checkBox = false;
  bool checkButton = false;
  bool checkPassFaild = false;
  bool checkAccountFaild = false;

  readNameAndId(){
    UserId user = UserId.fromJson(cnv.jsonDecode(FirebaseAuth.instance.currentUser!.photoURL.toString()));
    setState(() {
      id = user.id.toString();
      photourl = user.photourl.toString();
    });
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  CollectionReference login = FirebaseFirestore.instance.collection('login');

  @override
  Widget build(BuildContext context) {
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
          else if (!regExp.hasMatch(val)) {
            return '* Nhập đúng dạng email';
          }
          else if (checkAccountFaild){
            return '* Không tìm thấy người dùng';
          }
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
          children: [
            Checkbox(
              checkColor: AppColors.tertiary,
              fillColor: MaterialStateProperty.resolveWith(getColor),
              value: checkBox,
              onChanged: (bool? value) {
                setState(() {
                  checkBox = value!;
                });
                print(checkBox);
              },
            ),
            Text('Duy trì đăng nhập', style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        TextButton(
            onPressed: (){
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
        setState(() {
          checkButton = true;
          checkAccountFaild = false;
          checkPassFaild = false;
        });
        if (_formKey.currentState!.validate()) {
          SignIn();
        };
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
        return Dialog(
            child: new Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  new CircularProgressIndicator(),
                  SizedBox(height: 20),
                  new Text("Đang đăng nhập..."),
                ],
              ),
            )
        );
      },
    );
    try {
      final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: textAccount.text, password: textPass.text);
      if (user.user!.emailVerified) {
        readNameAndId();
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
      else {
        Navigator.of(context).pop;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
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
      else if (e.message == 'There is no user record corresponding to this identifier. The user may have been deleted.') {
        setState(() {
          checkAccountFaild = true;
        });
      }
      else if (e.message == 'We have blocked all requests from this device due to unusual activity. Try again later.') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Ôi bạn ơi"),
            content: Text('Lỗi đăng nhập'),
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
    }
  }

  Widget RegistrationButton(){
    return OutlinedButton(
      onPressed: () {
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