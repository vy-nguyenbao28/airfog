import 'dart:async';
import 'dart:convert' as cnv;
import 'package:flutter/material.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mist_app/theme/constant.dart';
import 'package:mist_app/theme/namedisplay_and_id.dart';

class ChangePassword extends StatefulWidget {
  @override
  _ChangePassword createState() => _ChangePassword();
}

class _ChangePassword extends State<ChangePassword> {
  final textPassOld = TextEditingController();
  final textPassNew = TextEditingController();
  final textPassConfirm = TextEditingController();

  bool Saved = false;
  bool checkButton = false;
  bool checkOldPass = false;
  bool _passwordVisible = false;
  bool _passwordVisibleNew = false;
  bool _passwordVisibleConfirm = false;

  String? password;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  CollectionReference user = FirebaseFirestore.instance.collection('user');

  getOldPassword(){
    user.doc('${FirebaseAuth.instance.currentUser!.email}').get().then((DocumentSnapshot documentSnapshot) {
      password = documentSnapshot['password'].toString();
    });
  }

  @override
  void initState() {
    getOldPassword();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: false,
        flexibleSpace: Image(
          image: AssetImage('assets/headerdrawer.png'),
          fit: BoxFit.cover,
        ),
        elevation: 2.5,
        title: Text(
          "Đổi mật khẩu",
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 26, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      body: Container(
          padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.08,
              MediaQuery.of(context).size.width * 0.08,
              MediaQuery.of(context).size.width * 0.08, 0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                OldPassword(),
                SizedBox(height: 20),
                NewPassword(),
                SizedBox(height: 20),
                ConfirmNewPassword()
              ],
            ),
          )
      ),
      bottomNavigationBar: ChangePasswordButton(),
    );
  }

  Widget OldPassword(){
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val){
        if (checkButton){
          if(checkOldPass){
            return "* Nhập mật khẩu cũ sai";
          }
          if(val!.isEmpty){
            return "* Nhập mật khẩu cũ";
          }
          if(val.length < 6){
            return "* Mật khẩu ít nhất cần 6 ký tự";
          }
        }
        return null;
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(fontSize: 17,
            ),
        hintText: 'Mật khẩu cũ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(width: 1),
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
              Image.asset('assets/pass.png',width: 30),
              SizedBox(width: 10),
              Container(
                height: 28,
                width: 1,
                color: Colors.black,
              )
            ],
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.grey,
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
         ),
      obscureText: !_passwordVisible,
      textAlign: TextAlign.left,
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      controller: textPassOld,
      cursorColor: Colors.black,
    );
  }

  Widget NewPassword(){
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val){
        if (checkButton){
          if(val!.isEmpty){
            return "* Nhập mật khẩu mới";
          }
          if(val.length < 6){
            return '* Mật khẩu ít nhất cần 6 ký tự';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(fontSize: 17),
        hintText: 'Mật khẩu mới',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(width: 1),
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
              Image.asset('assets/newpass.png',width: 30),
              SizedBox(width: 10),
              Container(
                height: 28,
                width: 1,
                color: Colors.black
              )
            ],
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisibleNew
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _passwordVisibleNew = !_passwordVisibleNew;
            });
          },
        ),
      ),
      style: TextStyle(fontSize: 17, height: 1.2),
      obscureText: !_passwordVisibleNew,
      textAlign: TextAlign.left,
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      controller: textPassNew,
      cursorColor: Colors.black,
    );
  }

  Widget ConfirmNewPassword(){
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val){
        if (checkButton){
          if(val!.isEmpty){
            return "* Xác nhận mật khẩu mới";
          }
          if(val != textPassNew.text){
            return '* Nhập lại mất khẩu mới sai';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(fontSize: 17),
        hintText: 'Nhập lại mật khẩu mới',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(width: 1),
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
              Image.asset('assets/confirmpass.png',width: 30),
              SizedBox(width: 10),
              Container(
                height: 28,
                width: 1,
                color: Colors.black
              )
            ],
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisibleConfirm
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _passwordVisibleConfirm = !_passwordVisibleConfirm;
            });
          },
        ),
      ),
      style: TextStyle(fontSize: 17, height: 1.2),
      obscureText: !_passwordVisibleConfirm,
      textAlign: TextAlign.left,
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      controller: textPassConfirm,
      cursorColor: Colors.black,
    );
  }

  Widget ChangePasswordButton(){
    return Container(
        padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width*0.13, 0,
            MediaQuery.of(context).size.width*0.13, 10),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              checkButton = true;
            });
            if(textPassOld.text != password){
              setState(() {
                checkOldPass = true;
              });
            } else setState(() {
              checkOldPass = false;
            });
            if (_formKey.currentState!.validate()) {
              FirebaseAuth.instance.currentUser!.updatePassword(textPassNew.text);
              user.doc('${FirebaseAuth.instance.currentUser!.email}').set({
                'password': '${textPassNew.text}',
                'apikey': '$id',
                'name': '${FirebaseAuth.instance.currentUser!.displayName}'
              });
            }
          },
          child: Container(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/saveinfo.png', width: 19, color: AppColors.tertiary),
                  SizedBox(width: 10),
                  Text('Lưu thông tin',
                      style: TextStyle(fontSize: 17, color:  AppColors.tertiary)),
                ],
              )
          ),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            primary: AppColors.tertiary, // foreground text
            side: BorderSide(color: AppColors.tertiary), // foreground border
          ),
        )
    );
  }
}