import 'dart:convert' as cnv;
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mist_app/theme/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwitchCheck extends StatefulWidget {
  @override
  _SwitchCheck createState() => _SwitchCheck();
}

class _SwitchCheck extends State<SwitchCheck> {
  //Biến Widget
  bool switchAC = false;
  bool switchDC = false;
  bool switchPump = false;
  bool switchBell = false;
  bool checkAC = false;
  bool checkDC = false;
  bool checkPump = false;
  bool checkBell = false;

  //Test
  String? check;
  String generateRandomString(int len) {
    var r = Random();
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
  }

  void sendData(String mode, final data)  {
    Dio().getUri(Uri.http('192.168.16.2','/$mode',data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: CheckCard('assets/motorAC.png','Động cơ thổi',switchAC)
                    ),
                    SizedBox(width: 20),
                    Expanded(
                        child: CheckCard('assets/dc.png','Động cơ quay',switchDC)
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: CheckCard('assets/pump.png','Động cơ bơm',switchPump)
                    ),
                    SizedBox(width: 20),
                    Expanded(
                        child: CheckCard('assets/bell.png','Chuông báo',switchBell)
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            )
    ));
  }

  Widget CheckCard(String image, String name, bool switchbutton) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.lighterGray,
              blurRadius: 10,
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
                fontWeight: FontWeight.w400, fontSize: 20, color: Colors.black),
          ),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Image.asset(image, width: 50,),
              FlutterSwitch(
                height: 23,
                width: 55,
                toggleSize: 20,
                activeColor: AppColors.tertiary,
                inactiveColor: Color(0xff555555),
                value: switchbutton,
                onToggle: (bool value) {
                  setState(() {
                    if (name == 'Động cơ thổi') {
                      if (!checkAC){
                        switchAC = value;
                        if (switchAC){
                          checkAC = true;
                          sendData('test',{'api_key': '$id',
                            'testcode':'1',
                          });
                          new Future.delayed(new Duration(seconds: 5), () {
                            setState(() {
                              switchAC = false;
                              checkAC = false;
                            });
                          });
                        }
                      }
                    }
                    if (name == 'Động cơ quay') {
                      if (!checkDC){
                        switchDC = value;
                        if (switchDC){
                          checkDC =true;
                          sendData('test',{'api_key': '$id',
                            'testcode':'2',
                          });
                          new Future.delayed(new Duration(seconds: 5), () {
                            setState(() {
                              switchDC = false;
                              checkDC = false;
                            });
                          });
                        }
                      }
                    }
                    if (name == 'Động cơ bơm') {
                      if (!checkPump){
                        switchPump = value;
                        if (switchPump){
                          checkPump =true;
                          sendData('test',{'api_key': '$id',
                            'testcode':'3',
                          });
                          new Future.delayed(new Duration(seconds: 5), () {
                            setState(() {
                              switchPump = false;
                              checkPump = false;
                            });
                          });
                        }
                      }
                    }
                    if (name == 'Chuông báo') {
                      if (!checkBell){
                        switchBell = value;
                        if (switchBell){
                          checkBell =true;
                          sendData('test',{'api_key': '$id',
                            'testcode':'4',
                          });
                          new Future.delayed(new Duration(seconds: 5), () {
                            setState(() {
                              switchBell = false;
                              checkBell = false;
                            });
                          });
                        }
                      }
                    }
                  });
                },
              )
            ],
          ),
        ],
      )
    );
  }
}
