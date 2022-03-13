import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mist_app/login/login.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPassword createState() => _ForgotPassword();
}

class _ForgotPassword extends State<ForgotPassword> {
  final textEmail = TextEditingController();

  bool colorEmail = false;
  bool checkButton = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  CollectionReference user = FirebaseFirestore.instance.collection('user');

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
        child:  ListView(
            padding: EdgeInsets.all(20),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                child: Image.asset('assets/logo.png', height: 120,color: Colors.white,),
              ),
              Center(
                child: Text('Tìm lại mật khẩu',
                    style: TextStyle(fontSize: 40, color: Colors.white),
                    textAlign: TextAlign.center),
              ),
              SizedBox(height: 20),
              Padding(
                  padding: EdgeInsets.fromLTRB(35,0,35,10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Email(),
                        SizedBox(height: 30),
                        RegistrationButton(),
                      ],
                    ),
                  )
              )
            ]
        ),
      )
    );
  }

  Widget Email(){
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      onTap: (){
        setState(() {
          colorEmail = true;
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
        fillColor: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorEmail)
            ? Colors.white
            : null,
        hintStyle: TextStyle(fontSize: 17,
            color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorEmail)
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
                  color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorEmail)
                      ? AppColors.tertiary
                      : Colors.white),
              SizedBox(width: 10),
              Container(
                height: 28,
                width: 1,
                color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorEmail)
                    ? AppColors.tertiary
                    : Colors.white,
              )
            ],
          ),
        ),
      ),
      style: TextStyle(fontSize: 17, height: 1.2, color: (WidgetsBinding.instance!.window.viewInsets.bottom > 0.0 && colorEmail)
          ? AppColors.tertiary
          : Colors.white),
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      controller: textEmail,
      cursorColor: AppColors.tertiary,
    );
  }

  Widget RegistrationButton(){
    return ElevatedButton(
      onPressed: () {
        setState(() {
          checkButton = true;
        });
        if (_formKey.currentState!.validate()) {
          SendAcount();
        }
      },
      child: Container(
          height: 50,
          width: MediaQuery.of(context).size.width*0.5,
          child: Center(
            child: Text('Tìm lại mật khẩu',
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
                    Text("Đang gửi yêu cầu...",style: TextStyle(fontSize: 15)),
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
        await FirebaseAuth.instance.sendPasswordResetEmail(email: textEmail.text);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
                child: new Padding(
                  padding: EdgeInsets.fromLTRB(0,15,0,3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/checked.png', width: 50),
                      SizedBox(height: 15),
                      new Text("Vui lòng kiểm tra email"),
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
            title:
            Text('Ôi bạn ơi !!!'),
            content: Text('Không tìm thấy người dùng'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                },
                child: Text('Xác nhận'),
              )
            ],
          ),
        );
        print(e.message);
      }
    });
  }
}