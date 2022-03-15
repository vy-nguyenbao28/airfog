import 'dart:async';
import 'dart:convert' as cnv;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:mist_app/theme/constant.dart';
import 'package:mist_app/network_request/user_model.dart';
import '../counttime.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwitchRunNow extends StatefulWidget {
  @override
  _SwitchRunNow createState() => _SwitchRunNow();
}

class _SwitchRunNow extends State<SwitchRunNow>
    with TickerProviderStateMixin {
  //Biến Widget
  int checkTemp = 0;
  int checkFlow = 0;

  bool _isConnected = false;
  bool checkStatus = false;
  Timer? timerRefresh;
  Timer? timerLoadData;

  //TimeFast
  late AnimationController controller;
  String get countText {
    Duration count = controller.duration! * controller.value;
    return controller.isDismissed
        ? '${controller.duration!.inHours.toString().padLeft(2, '0')}:${(controller.duration!.inMinutes % 60).toString().padLeft(2, '0')}:${(controller.duration!.inSeconds % 60).toString().padLeft(2, '0')}'
        : '${count.inHours.toString().padLeft(2, '0')}:${(count.inMinutes % 60).toString().padLeft(2, '0')}:${(count.inSeconds % 60).toString().padLeft(2, '0')}';
  }
  double progress = 1.0;
  //Firestore
  CollectionReference machine = FirebaseFirestore.instance.collection('$id');

  //Các hàm ngoài

  //Hàm check Internet
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
      duration: Duration(milliseconds: 1500),
      shape: StadiumBorder(),
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ));
  }

  //Hàm timeApp
  StreamController<int>? _events;
  int secondsPassed = 0;
  Timer? timer;
  void _startTimer() {
    secondsPassed = 20;
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      //setState(() {re
      (secondsPassed > 0) ? secondsPassed-- : timer.cancel();
      //});
      _events!.add(secondsPassed);
    });
  }


  void sendData(String mode, final dataSend)async  {
    Dio().getUri(Uri.http('192.168.16.2','/$mode',dataSend));
  }

  //InitState & Dispose
  @override
  void initState() {
    _events = StreamController<int>.broadcast();
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 300),
    );
    controller.addListener(() {
      if (controller.isAnimating) {
        setState(() {
          progress = controller.value;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    timerRefresh!.cancel();
    timerLoadData!.cancel();
    timer!.cancel();
    controller.dispose();
  }
  //List Widget
  @override
  Widget build(BuildContext context) {
    checkConnectivty();
    return ListView(
      padding: EdgeInsets.fromLTRB(0,0,0,20),
      children: [
        valueCard(),
        SizedBox(height: 15),
        Padding(
          padding: EdgeInsets.fromLTRB(15,0,15,0),
          child: Center(
            child: Text('Nhập thời gian chạy tại đây',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 23,color: Colors.red),
              textAlign: TextAlign.center,),
          ),
        ),
        Center(
          child: CountdownPage(),
        ),
        IconButton(
          splashRadius: 50,
          iconSize: 150,
          icon:Icon(Icons.not_started,
              color: AppColors.tertiary,
          ),
          onPressed: (){
            timePhun =
                int.parse((controller.duration!.inHours % 60).toString())*3600 +
                    int.parse((controller.duration!.inMinutes % 60).toString())*60 +
                    int.parse((controller.duration!.inSeconds % 60).toString());
            machine.doc('program').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
              setState(() {
                checkTemp = int.parse(documentSnapshot['temp'].toString());
                checkFlow = int.parse(documentSnapshot['flow'].toString());
              });
              if (((timePhun * checkFlow) / 60 - loadcell > 0) || temp >= checkTemp){
                setState(() {
                  checkStatus = true;
                });
              }else if ((timePhun * checkFlow) / 60 - loadcell < 0 && (temp<checkTemp)){
                checkStatus = false;
                _startTimer();
              }
              if (!_isConnected){
                notification('Không có kết nối Internet !!!');
              }
              if (_isConnected && (model == null)){
                notification('Không có kết nối với máy !!!');
              }
              if (_isConnected == true){
                StartProgram();
              }
            });
          },
        ),

        // Text(" Bắt đầu",
        //     style: TextStyle(
        //       fontSize: 50,
        //       color: AppColors.tertiary,
        //     )),
      ],
    );
  }

  void StartProgram(){

    if(timePhun == 0){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Yêu cầu nhập thời gian chạy !!!',
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
    else showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context){
          return SimpleDialog(
            contentPadding: EdgeInsets.only(left: 10, right: 10, bottom: 15),
            titlePadding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  !checkStatus
                      ? Image.asset('assets/checked.png',width: 60)
                      : Image.asset('assets/error.png',width: 60),
                  SizedBox(height: 10),
                  !checkStatus
                      ? Text('Tiến hành phun sau',
                      style: TextStyle(color: AppColors.tertiary, fontSize: 20))
                      : Text('Phát hiện lỗi',
                      style: TextStyle(color: Colors.red, fontSize: 20)),
                  Container(
                    margin: EdgeInsets.fromLTRB(30,10,30,0),
                    height: 1.5,
                    color: Color(0xffDDDDDD),
                  )
                ]),
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  (!checkStatus)
                      ? StreamBuilder<int>(
                      stream: _events!.stream,
                      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                        SchedulerBinding.instance!.addPostFrameCallback((_) {
                          if (secondsPassed == 0 && !checkStatus) {
                            //FlutterRingtonePlayer.playNotfication();
                            print('timePhun = $timePhun');
                            machine.doc('user').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                              sendData('start',{'api_key': '$id',
                                'speed':'1',  //cần sửa do đây là chạy nhanh ko có
                                'flow':'${documentSnapshot['flow'].toString()}',
                                'time':'$timePhun',
                              });
                            });
                            Roomname = 'Chạy nhanh';
                            Navigator.pop(context);
                            checkBell();
                            Future.delayed(Duration(seconds: 5), () async {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TimerApp()),
                              );
                            });
                            timer!.cancel;
                          };
                        });
                        return timeApp();
                      })
                      : SizedBox(width: 0),
                  statusCard(checkTemp,checkFlow),
                  SizedBox(height: 10),
                  (checkStatus)
                      ? Center(
                    child:ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Material(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 140,
                            height: 50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Colors.red
                            ),
                            child: Center(
                                child: Text(
                                  'Xác nhận',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                )),
                          ),
                        ),
                      ),
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Material(
                          child: InkWell(
                            onTap: () {
                              print('timePhun = $timePhun');
                              machine.doc('user').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                                sendData('start',{'api_key': '$id',
                                  'speed':'1',  //cần sửa do đây là chạy nhanh ko có
                                  'flow':'${documentSnapshot['flow'].toString()}',
                                  'time':'$timePhun',
                                });
                              });
                              timer!.cancel;
                              Navigator.pop(context);
                              Roomname = 'Chạy nhanh';
                              checkBell();
                              Future.delayed(Duration(seconds: 5), () async {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => TimerApp()),
                                );
                              });
                            },
                            child: Container(
                              width: 100,
                              height: 50,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: AppColors.tertiary
                              ),
                              child: Center(
                                  child: Text(
                                    'Bắt đầu',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  )),
                            ),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Material(
                          child: InkWell(
                            onTap: () {
                              timer!.cancel;
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 100,
                              height: 50,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: AppColors.tertiary
                              ),
                              child: Center(
                                  child: Text(
                                    'Hủy bỏ',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  )),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              )
            ],
          );
        });
  }

  void checkBell(){
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
                    Text("Chuẩn bị phun...",style: TextStyle(fontSize: 15)),
                  ],
                ),
              )
          ),
        );
      },
    );
  }

  Widget valueCard() {
    final double sliderWidth = MediaQuery.of(context).size.width;
    return Container(
        margin: EdgeInsets.only(right: 20, left: 20, top: 8),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          boxShadow: [BoxShadow(blurRadius: 10, color: AppColors.lighterGray)],
          color: Colors.white,
        ),
        child: Column(
          children: [
            Padding(
                padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: (sliderWidth / 2) * 0.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Trạng thái kết nối',
                            style: TextStyle(color: Colors.grey, fontSize: 12,),
                          ),
                          SizedBox(
                            height: 11,
                          ),
                          ((model == null || !_isConnected))
                              ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Image.asset(
                                            'assets/disconnect.png',
                                            width: 100,
                                          ),
                                          SizedBox(
                                            height: 11,
                                          ),
                                          Text(
                                            'Chưa kết nối',
                                            style: TextStyle(color: Colors.black, fontSize: 15,fontWeight: FontWeight.w500),
                                          ),
                                        ])
                              : Container(),
                          (model != null && _isConnected)
                              ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Image.asset(
                                            'assets/connected.gif',
                                            width: 100,
                                          ),
                                          SizedBox(
                                            height: 11,
                                          ),
                                          Text(
                                            'Đã kết nối',
                                            style: TextStyle(color: Colors.black, fontSize: 15,fontWeight: FontWeight.w500),
                                          ),
                                        ]
                                    )
                              : Container(),
                        ],
                      ),
                    ),
                    Container(height: 80, width: 1.5, margin: EdgeInsets.only(top: 15), color: Colors.grey),
                    SizedBox(
                      width: (sliderWidth / 2) * 0.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('Nhiệt độ',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.red,fontWeight: FontWeight.w400)),
                          SizedBox(height: 7),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20),
                              (model == null || !_isConnected)
                                  ? Text('??',
                                  style: TextStyle(
                                      fontSize: 65, color: Colors.grey,fontWeight: FontWeight.w400))
                                  : Container(),
                              (model != null && _isConnected)
                                  ? Text('${model![0].temp.toString()}',
                                  style: TextStyle(
                                      fontSize: 65, color: Colors.red,fontWeight: FontWeight.w400))
                                  : Container(),
                              Text('o',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.red,fontWeight: FontWeight.w500)),
                              Text('C',
                                  style: TextStyle(
                                      fontSize: 28, color: Colors.red,fontWeight: FontWeight.w400)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
            SizedBox(height: 5),
            (model == null || !_isConnected)
                ? slideChemicalLevel(0, sliderWidth)
                : Container(),
            (model != null && _isConnected)
                ? slideChemicalLevel(((int.parse(model![0].loadcell.toString())/5000)*100) / 100, sliderWidth)
                : Container(),
          ],
        )
    );
  }

  Widget CountdownPage(){
    return Center(
      child: GestureDetector(
        onTap: () {
          if (controller.isDismissed) {
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                height: 300,
                child: CupertinoTimerPicker(
                  initialTimerDuration: controller.duration!,
                  onTimerDurationChanged: (time) {
                    setState(() {
                      controller.duration = time;
                    });
                  },
                ),
              ),
            );
          }
        },
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) => Text(
            countText,
            style: TextStyle(
              fontSize: 55,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget timeApp() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          (!checkStatus)
              ? Text('${(secondsPassed % 60).toString().padLeft(2, '0')} giây',
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 25
            ),)
              : SizedBox(width: 0),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Thời gian phun dự kiến: ', style: TextStyle(fontSize: 17)),
              AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) => Text(
                    countText,
                    style: TextStyle(
                      fontSize: 17,
                    ),
                  )
              ),
            ],
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget statusCard(int checkTemp, int checkFlow){
    timePhun =
        int.parse((controller.duration!.inHours % 60).toString())*3600 +
            int.parse((controller.duration!.inMinutes % 60).toString())*60 +
            int.parse((controller.duration!.inSeconds % 60).toString());
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ((timePhun * checkFlow) / 60 - loadcell <= 0)
              ? Text('Mức hóa chất: Cho phép',
            style: TextStyle(fontSize: 18, color: AppColors.tertiary),)
              : Text('Mức hóa chất: Thiếu ${((timePhun * 33) / 60 - loadcell).toInt()} ml ',
            style: TextStyle(fontSize: 18, color: Colors.red),),
          (temp < checkTemp)
              ? Text('Nhiệt độ động cơ: Cho phép',
            style: TextStyle(fontSize: 18, color: AppColors.tertiary),)
              : Text('Nhiệt độ động cơ: Quá tải',
            style: TextStyle(fontSize: 18, color: Colors.red),),
        ],
      )
    );
  }

  Widget slideChemicalLevel(double? percentage, double width) {
    return Padding(
        padding: EdgeInsets.fromLTRB(3,0,3,0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            (!_isConnected || model == null)
                ? Text('??%')
                : Text('${(percentage!*100).toInt()}%'),
            Row(
              children: [
                SizedBox(
                  width: width * 0.24,
                  child: Text('Mức hóa chất: ',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            width: 1.3, //                   <--- border width here
                          ),
                        ),
                        width: double.infinity,
                        height: 16,
                      ),
                      Padding(
                        padding: EdgeInsets.all(1.3),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Color(0xff00CC00),
                          ),
                          width: percentage == null ? 0 : (width - (width * 0.24 + 2*(20 + 1.3 +10))) * percentage,
                          height: 13.4,
                        ),
                      )
                    ],
                  ),
                )
              ],
            )
          ],
        )
    );
  }

}
