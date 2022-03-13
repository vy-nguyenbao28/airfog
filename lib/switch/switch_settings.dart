import 'dart:convert' as cnv;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:mist_app/theme/namedisplay_and_id.dart';
import '../theme/user_manual.dart';
import 'package:dio/dio.dart';
import 'package:date_time/date_time.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mist_app/theme/constant.dart';


class SwitchSettings extends StatefulWidget {
  @override
  _SwitchSettings createState() => _SwitchSettings();
}

class _SwitchSettings extends State<SwitchSettings> {
  //Biến Widget
  final textFlow = TextEditingController();
  final textTemp = TextEditingController();
  final textUserWifi = TextEditingController();
  final textPassWifi = TextEditingController();
  final dateTime = DateTime.now();
  //Khai báo HTTP
  bool? _isConnected;
  bool checkSendFlow = false;
  bool checkSendTemp = false;
  bool _passwordVisible = false;
  //Khai báo Firestore
  CollectionReference machine = FirebaseFirestore.instance.collection('$id');
  String? get _errorTextUserWifi {
    final text = textUserWifi.value.text;
    if (text.isEmpty) {
      return '* Bắt buộc';
    }
    return null;
  }
  String? get _errorTextPassWifi {
    final text = textPassWifi.value.text;
    if (text.isEmpty) {
      return '* Bắt buộc';
    }
    if (text.length < 8) {
      return '* Nhập tối thiểu 8 ký tự';
    }
    return null;
  }
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

  void sendData(String mode, final dataSend)async  {
    Dio().getUri(Uri.http('192.168.16.2','/$mode',dataSend));
  }

  void notification(String s){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$s',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      backgroundColor: Color(0xff898989),
      duration: Duration(seconds: 1),
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
        body: ListView(
            children: [
              Column(
                children: [
                  ExpansionFlow(),
                  ExpansionTemp(),
                  ExpansionScale(),
                  ExpansionTime(),
                  ExpansionWifi(),
                  // ExpansionSpeed(),
                  // ExpansionTranslate(),
                  ExpansionManual(),
            ],
          )
        ]));
  }
  Widget CheckCard(String image, String name) {
    return Padding(
        padding: EdgeInsets.fromLTRB(10,0,20,0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Image.asset(image, width: 36,),
              SizedBox(width: 20),
              Text(
                name,
                style: TextStyle(
                    fontWeight: FontWeight.w400, fontSize: 18, color: Colors.black),
              ),
            ],
          ),
        ],
      )
    );
  }

  Widget ExpansionFlow(){
    return Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: ExpansionTile(
        iconColor: AppColors.tertiary,
        collapsedBackgroundColor: Colors.white,
        title: CheckCard('assets/water-pipe.png','Điều chỉnh lưu lượng'),
        children:<Widget> [
          StreamBuilder<DocumentSnapshot>(
              stream: machine.doc('program').collection('settings').doc('settings').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: Text('Đang tải...',
                          style: TextStyle(
                              fontSize: 15)));
                }
                if (textFlow.text == '' && WidgetsBinding.instance!.window.viewInsets.bottom <= 0.0 && checkSendFlow == false){
                  textFlow.text = snapshot.data!['flow'].toString();
                }
                else textFlow.text == snapshot.data!['flow'].toString();
                return Padding(
                    padding: EdgeInsets.fromLTRB(100,0,60,5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                                hintText: '30 ~ 37',
                                focusColor: Colors.black),
                            textInputAction: TextInputAction.send,
                            controller: textFlow,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            cursorColor: Colors.blueGrey,
                          ),
                        ),
                        Text('ml/phút'),
                        SizedBox(width: 10),
                        RawMaterialButton(
                            child: Center(
                                child: Text(
                                  'Lưu',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                )),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            elevation: 2.0,
                            fillColor: AppColors.tertiary,
                            onPressed: (){
                              if (_isConnected == false){
                                notification('Không có kết nối Internet !!!');
                              };
                              if (_isConnected == true){
                                setState(() {
                                  checkSendFlow = true;
                                });
                                if(textFlow.text == ''){
                                  notification('Sử dụng giá trị mặc định');
                                  machine.doc('program').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                                    machine.doc('program').collection('settings').doc('settings').set({
                                      'flow': '33',
                                      'temp': documentSnapshot['temp'].toString()
                                    });
                                  });
                                  textFlow.text = '33';
                                }
                                else if (textFlow.text != ''){
                                  if (double.tryParse(textFlow.text) != null) {
                                    notification('Đã lưu giá trị');
                                    machine.doc('program').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                                      machine.doc('program').collection('settings').doc('settings').set({
                                        'flow': textFlow.text,
                                        'temp': documentSnapshot['temp'].toString()
                                      });
                                    });
                                  } else notification('Vui lòng nhập dạng số');
                                }
                                FocusScope.of(context).requestFocus(FocusNode());
                              }
                            }
                        ),
                      ],
                    )
                );
              }),
        ],
      ),
    );
  }

  Widget ExpansionTemp(){
    return Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: ExpansionTile(
        iconColor: AppColors.tertiary,
        collapsedBackgroundColor: Colors.white,
        title:  CheckCard('assets/temp.png','Thiết lập mức nhiệt độ'),
        children: [
          StreamBuilder<DocumentSnapshot>(
              stream: machine.doc('program').collection('settings').doc('settings').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: Text('Đang tải...',
                          style: TextStyle(
                              fontSize: 15)));
                }
                if (textTemp.text == '' && WidgetsBinding.instance!.window.viewInsets.bottom <= 0.0 && checkSendTemp == false){
                  textTemp.text = snapshot.data!['temp'].toString();
                }
                else textTemp.text == snapshot.data!['temp'].toString();
                return Padding(
                    padding: EdgeInsets.fromLTRB(100,0,60,5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                                hintText: '0 ~ 100',
                                focusColor: Colors.black),
                            textInputAction: TextInputAction.send,
                            controller: textTemp,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            //textAlign: TextAlign.center,
                            cursorColor: Colors.blueGrey,
                          ),
                        ),
                        Text('\u1d52C'),
                        SizedBox(width: 10),
                        RawMaterialButton(
                            child: Center(
                                child: Text(
                                  'Lưu',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                )),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            elevation: 2.0,
                            fillColor: AppColors.tertiary,
                            onPressed: (){
                              if (_isConnected == false){
                                notification('Không có kết nối Internet !!!');
                              }
                              else if (_isConnected == true){
                                setState(() {
                                  checkSendTemp = true;
                                });
                                if(textTemp.text == ''){
                                  notification('Sử dụng giá trị mặc định');
                                  machine.doc('program').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                                    machine.doc('program').collection('settings').doc('settings').set({
                                      'flow': documentSnapshot['flow'].toString(),
                                      'temp': '80'
                                    });
                                  });
                                  textTemp.text = '80';
                                  FocusScope.of(context).requestFocus(FocusNode());
                                }
                                else if(textTemp.text != ''){
                                  if (double.tryParse(textTemp.text) != null) {
                                    notification('Đã lưu giá trị');
                                    machine.doc('user').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                                      machine.doc('user').collection('settings').doc('settings').set({
                                        'flow': documentSnapshot['flow'].toString(),
                                        'temp': textTemp.text
                                      });
                                    });
                                  } else notification('Vui lòng nhập dạng số');

                                  FocusScope.of(context).requestFocus(FocusNode());
                                }
                              }
                            }
                        ),
                      ],
                    )
                );
              }),
        ],
      ),
    );
  }

  Widget ExpansionScale(){
    return Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: ExpansionTile(
        iconColor: AppColors.tertiary,
        collapsedBackgroundColor: Colors.white,
        title: CheckCard('assets/weighing-machine.png','Căn chỉnh hóa chất'),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20,0,20,5),
                child: RawMaterialButton(
                    child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Nhỏ nhất',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        )
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 2.0,
                    fillColor: AppColors.tertiary,
                    onPressed: (){
                      if (_isConnected == false){
                        notification('Không có kết nối Internet !!!');
                      }
                      else if (_isConnected == true){
                        sendData('calib',{'api_key': '$id',
                          'calibcode':'0',
                        });
                        notification('Đã gửi yêu cầu');
                      }
                    }
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0,0,0,5),
                child: RawMaterialButton(
                    child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lớn nhất',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        )
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 2.0,
                    fillColor: AppColors.tertiary,
                    onPressed: (){
                      if (_isConnected == false){
                        notification('Không có kết nối Internet !!!');
                      }
                      else if (_isConnected == true){
                        sendData('calib',{'api_key': '$id',
                          'calibcode':'1',
                        });
                        notification('Đã gửi yêu cầu');
                      }
                    }
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget ExpansionTime(){
    return Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: ExpansionTile(
        iconColor: AppColors.tertiary,
        collapsedBackgroundColor: Colors.white,
        title: CheckCard('assets/time.png','Cấu hình thời gian'),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(120,0,80,5),
            child: RawMaterialButton(
                child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Nhấn vào đây',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    )
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                elevation: 2.0,
                fillColor: AppColors.tertiary,
                onPressed: (){
                  if (_isConnected == false){
                    notification('Không có kết nối Internet !!!');
                  }
                  else if (_isConnected == true){
                    sendData('settime',{'api_key': '$id',
                      'sec':'${dateTime.time.secs}',
                      'min':'${dateTime.time.mins}',
                      'hour':'${dateTime.time.hours}',
                      'date':'${dateTime.date.day}',
                      'month':'${dateTime.date.month}',
                      'year':'${dateTime.date.year}',
                    });
                    notification('Đã gửi yêu cầu');
                  }
                }
            ),
          ),
        ],
      ),
    );
  }

  Widget ExpansionWifi(){
    final double sliderWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: ExpansionTile(
        iconColor: AppColors.tertiary,
        collapsedBackgroundColor: Colors.white,
        title:  CheckCard('assets/wifi.png','Cấu hình Wifi'),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 30),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: sliderWidth-100,
                      child: ValueListenableBuilder(
                        valueListenable: textUserWifi,
                        builder: (context, TextEditingValue value, __) {
                          return TextFormField(
                            decoration: InputDecoration(
                              icon: Icon(
                                Icons.drive_file_rename_outline_sharp,
                                color: Colors.blue,
                                size: 30,
                              ),
                              labelText: 'Tên wifi',
                              focusColor: Colors.black,
                              errorText: _errorTextUserWifi,
                            ),
                            autofocus: true,
                            textInputAction: TextInputAction.send,
                            textCapitalization: TextCapitalization.none,
                            controller: textUserWifi,
                            cursorColor: Colors.blueGrey,
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: sliderWidth-100,
                      child: ValueListenableBuilder(
                        valueListenable: textPassWifi,
                        builder: (context, TextEditingValue value, __) {
                          return TextFormField(
                            decoration: InputDecoration(
                              icon: Icon(
                                Icons.password,
                                color: Colors.blue,
                                size: 30,
                              ),
                              labelText: 'Mật khẩu',
                              focusColor: Colors.black,
                              errorText: _errorTextPassWifi,
                              suffixIcon: IconButton(
                                splashRadius: 17,
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: _passwordVisible
                                      ? Colors.blueGrey
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _passwordVisible = !_passwordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_passwordVisible,
                            textInputAction: TextInputAction.send,
                            textCapitalization: TextCapitalization.none,
                            controller: textPassWifi,
                            cursorColor: Colors.blueGrey,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              RawMaterialButton(
                  child: Center(
                      child: Text(
                        'Gửi',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      )),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  elevation: 2.0,
                  fillColor: AppColors.tertiary,
                  onPressed: (){
                    if (_isConnected == false){
                      notification('Không có kết nối Internet !!!');
                    }
                    else if (_isConnected == true){
                      if (textUserWifi.text == '' || textPassWifi.text.length <8){
                        notification('Chưa nhập đủ thông tin !!!');
                      }
                      else if (textUserWifi.text != '' && textPassWifi.text.length >= 8){
                        sendData('configwifi',{'api_key': '$id',
                          'ssid':'${textUserWifi.text}',
                          'pass':'${textPassWifi.text}',
                        });
                        notification('Hãy kết nối với Wifi sau 5 giây');
                        FocusScope.of(context).requestFocus(FocusNode());
                      }
                    }

                  }
              ),
              SizedBox(width: 30)
            ],
          )
        ],
      ),
    );
  }

  Widget ExpansionSpeed(){
    return Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: ExpansionTile(
        iconColor: AppColors.tertiary,
        collapsedBackgroundColor: Colors.white,
        title: CheckCard('assets/speed.png','Tốc độ xe'),
        children: [
          Text('test')
        ],
      ),
    );
  }

  Widget ExpansionTranslate(){
    return Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: ExpansionTile(
        iconColor: AppColors.tertiary,
        collapsedBackgroundColor: Colors.white,
        title: CheckCard('assets/translate.png','Ngôn ngữ'),
        children: [
          Text('test')
        ],
      ),
    );
  }

  Widget ExpansionManual(){
    return Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: ExpansionTile(
        iconColor: AppColors.tertiary,
        collapsedBackgroundColor: Colors.white,
        title: CheckCard('assets/youtube.png','Hướng dẫn sử dụng'),
        children: [
          //Chạy nhanh
          Padding(
            padding: EdgeInsets.fromLTRB(80,0,50,5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Chạy nhanh',
                  style: TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 15, color: Colors.black),
                ),
                SizedBox(width: 10),
                RawMaterialButton(
                    child: Center(
                        child: Text(
                          'Xem',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        )),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 2.0,
                    fillColor: AppColors.tertiary,
                    onPressed: (){
                      if (_isConnected == false){
                        notification('Không có kết nối Internet !!!');
                      };
                      String url = "https://www.youtube.com/watch?v=5VWuWuZegWI&list=RD9B0kcmCtVPY&index=3&ab_channel=DiarialChill";
                      if (_isConnected == true){
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder:(context)=>UserManual(url)));
                      }
                    }
                ),
              ],
            ),
          ),
          Padding(
              padding: EdgeInsets.fromLTRB(80,0,150,5),
              child: Container(
                height: 1,
                color: Colors.grey,
              )
          ),
          //Chạy chuyên sâu
          Padding(
            padding: EdgeInsets.fromLTRB(80,0,50,5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Chạy chuyên sâu',
                  style: TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 15, color: Colors.black),
                ),
                SizedBox(width: 10),
                RawMaterialButton(
                    child: Center(
                        child: Text(
                          'Xem',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        )),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 2.0,
                    fillColor: AppColors.tertiary,
                    onPressed: (){
                      if (_isConnected == false){
                        notification('Không có kết nối Internet !!!');
                      };
                      String url = "https://www.youtube.com/watch?v=5VWuWuZegWI&list=RD9B0kcmCtVPY&index=3&ab_channel=DiarialChill";
                      if (_isConnected == true){
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder:(context)=>UserManual(url)));
                      }
                    }
                ),
              ],
            ),
          ),
          Padding(
              padding: EdgeInsets.fromLTRB(80,0,150,5),
              child: Container(
                height: 1,
                color: Colors.grey,
              )
          ),
          //Kiểm tra máy
          Padding(
            padding: EdgeInsets.fromLTRB(80,0,50,5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Kiểm tra máy',
                  style: TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 15, color: Colors.black),
                ),
                SizedBox(width: 10),
                RawMaterialButton(
                    child: Center(
                        child: Text(
                          'Xem',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        )),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 2.0,
                    fillColor: AppColors.tertiary,
                    onPressed: (){
                      if (_isConnected == false){
                        notification('Không có kết nối Internet !!!');
                      };
                      String url = "https://www.youtube.com/watch?v=5VWuWuZegWI&list=RD9B0kcmCtVPY&index=3&ab_channel=DiarialChill";
                      if (_isConnected == true){
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder:(context)=>UserManual(url)));
                      }
                    }
                ),
              ],
            ),
          ),
          Padding(
              padding: EdgeInsets.fromLTRB(80,0,150,5),
              child: Container(
                height: 1,
                color: Colors.grey,
              )
          ),
          SizedBox(height: 10)
        ],
      ),
    );
  }
}

