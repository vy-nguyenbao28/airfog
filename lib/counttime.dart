import 'dart:ui';
import 'dart:convert' as cnv;
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mist_app/home.dart';
import 'network_request/user_model.dart';
import 'theme/colors.dart';
import 'theme/constant.dart';
import 'package:date_time/date_time.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimerApp extends StatefulWidget {
  const TimerApp({Key? key}) : super(key: key);
  @override
  _TimerApp createState() => _TimerApp();
}

class _TimerApp extends State<TimerApp> with TickerProviderStateMixin{

  //Khai báo biến
  String? status;
  double progress = 1.0;
  int counter = 0;
  int temp = 0;
  int loadcell = 0;
  int timeUp = timePhun;
  bool isActive = true;
  bool _isConnected = false;
  bool checkErrorTemp = false;
  bool checkErrorChemical = false;
  bool checkShowdialog = false;
  bool checkConfirmButton = false;
  Timer? timer;
  Timer? timerLoadData;
  late AnimationController controller;
  static const duration = const Duration(seconds: 1);
  CountDownController _controller = CountDownController();

  final dateTime = DateTime.now();
  int? year, month, day;
  String? time;

  //Khai báo Firebase
  CollectionReference machine = FirebaseFirestore.instance.collection('$id');

  updateHistoryToFireStore(String yearstart, String monthstart, String daystart, String timestart, int runtime, String errorcode) async {
    setState(() {
      viewedHistory = false;
    });
    QuerySnapshot querySnapshot = await machine.doc('history').
      collection(yearstart).
      doc(monthstart).
      collection(daystart).get();
    int seconds = runtime % 60;
    int minutes = (runtime % (3600)) ~/ 60;
    int hours = runtime ~/ (3600);
    String date_created = '$yearstart/${monthstart.toString().padLeft(2, '0')}/${daystart.toString().padLeft(2, '0')}';
    String run_time = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    List<DocumentSnapshot> _myDocCount = querySnapshot.docs;
    machine.doc('history').
      collection(yearstart).
      doc(monthstart).
      collection(daystart).doc('${_myDocCount.length}').set({
        'date_created': '$date_created $timestart',
        'room_name': 'Chạy nhanh',
        'run_time': '$run_time',
        'status': errorcode
    });
    history.add(History(year: int.parse(yearstart), month: int.parse(monthstart), day: int.parse(daystart), sum: _myDocCount.length + 1));
  }

  void handleTick() {
    if (isActive) {
      setState(() {
        timeUp = timeUp - 1;
        if (timeUp == 0) {
          status = 'Hoàn thành';
          sendData('stop',{'api_key': '$id', 'stopcode':'0'});
          updateHistoryToFireStore(year.toString(), month.toString(), day.toString(), time.toString(), timePhun,'1');
          sendData('response', {'api_key': '$id', 'rescode':'2'});
          //FlutterRingtonePlayer.playNotification();
          Navigator.of(context).pop();
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) => SimpleDialog(
                    children: [
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Hoàn thành!',
                                style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w500)),
                            CircleAvatar(
                              child: Icon(Icons.check, size: 55),
                              radius: 35,
                            ),
                            SizedBox(height: 20),
                            SizedBox.fromSize(
                                size: Size(125, 40),
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            AppColors.tertiary),
                                  ),
                                  child: const Text('Xác nhận',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500)),
                                  onPressed: () => {
                                    Navigator.pop(context)
                                  },
                                )),
                          ])
                    ],
                  ));
        }
      });
    }
  }

  //Hàm HTTP
  void sendData(String mode, final dataSend)async  {
    Dio().getUri(Uri.http('192.168.16.2','/$mode',dataSend));
  }

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

  void checkError() {
    machine.doc('program').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
      if(temp > int.parse(documentSnapshot['temp'].toString())){
        setState(() {
          checkErrorTemp = true;
          isActive = false;
          _controller.pause();
        });
      }
      if(temp <= int.parse(documentSnapshot['temp'].toString()) || int.parse(model![0].loadcell.toString()) > 20){
        if (checkConfirmButton){
          setState(() {
            checkConfirmButton = false;
          });
        }
      }
    });
    if (int.parse(model![0].loadcell.toString()) <= 20){
      setState(() {
        checkErrorChemical = true;
        isActive = false;
        _controller.pause();
      });
    }
  }


  //Hàm initState và dispose
  @override
  void initState() {
    year = dateTime.year;
    month = dateTime.month;
    day = dateTime.day;
    time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    super.initState();
    timerLoadData = Timer.periodic(Duration(seconds: 3), (Timer t) {
      checkError();
    });
  }

  @override
  void dispose() {
    super.dispose();
    timerLoadData!.cancel();
    timer!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (!checkConfirmButton){
      if (!checkShowdialog && checkErrorTemp){
        Timer.run(() {
          errorDisplay(context, 'Quá tải nhiệt !!!');
        });
        timeUp = timePhun - timeUp;
        updateHistoryToFireStore(year.toString(), month.toString(), day.toString(), time.toString(), timeUp,'3');
        timePhun = 0;
        sendData('response', {'api_key': '$id', 'rescode':'2'});
        isActive = false;
        checkShowdialog = true;
      }
    }
    if(!checkConfirmButton){
      if (!checkShowdialog && checkErrorChemical){
        Timer.run(() {
          errorDisplay(context, 'Hết hóa chất !!!');
        });
        timeUp = timePhun - timeUp;
        updateHistoryToFireStore(year.toString(), month.toString(), day.toString(), time.toString(), timeUp,'4');
        timePhun = 0;
        sendData('response', {'api_key': '$id', 'rescode':'2'});
        isActive = false;
        checkShowdialog = true;
      }
    }
    checkConnectivty();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Image(
          image: AssetImage('assets/headerdrawer.png'),
          fit: BoxFit.cover,
        ),
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.tertiary,
        centerTitle: false,
        title: Text(
          "Vận hành",
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 26,
              color: Colors.white),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20,0,20,0),
        children: [Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              SizedBox(height: 10),
              (model != null && _isConnected)
                  ? Text("Đã kết nối", style: TextStyle(color: AppColors.tertiary))
                  : Text("Chưa kết nối", style: TextStyle(color: Colors.red)),
              inforTime(),
              SizedBox(height: 10),
              countTime(),
              SizedBox(height: 30),
              buttonTime(),
              SizedBox(height: 10),
            ]
        ),],
      ),
    );
  }

  Widget inforTime(){
    return SizedBox(
      height: 107,
      child: Column(
        children: [
          (Roomname == 'Chạy nhanh')
              ? Text("Chạy nhanh",
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500))
              : Text('Phòng: $Roomname',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500)),
          (model != null && _isConnected)
              ? slideChemicalLevel(((int.parse(model![0].loadcell.toString())/6000)*100) / 100, MediaQuery.of(context).size.width)
              : slideChemicalLevel(0, MediaQuery.of(context).size.width),
          SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nhiệt độ:',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500)),
                (model != null && _isConnected)
                    ? Text('${model![0].temp.toString()}\u1d52C',
                    style: TextStyle(
                        fontSize: 24, color: Colors.red,fontWeight: FontWeight.w400))
                    : Text('??\u1d52C',
                    style: TextStyle(
                        fontSize: 24, color: Colors.red,fontWeight: FontWeight.w400))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget countTime(){
    if (timer == null) {
      timer = Timer.periodic(duration, (Timer t) {
        handleTick();
      });
    }
    int seconds = timeUp % 60;
    int minutes = (timeUp % 3600) ~/ 60;
    int hours = timeUp ~/ (60 * 60);
    return (model != null && _isConnected)
        ? SizedBox(
            width: MediaQuery.of(context).size.width - 85,
            height: MediaQuery.of(context).size.width - 85,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularCountDownTimer(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width,
                  duration: timePhun,
                  fillColor: AppColors.tertiary,
                  ringColor: Colors.grey.shade300,
                  controller: _controller,
                  backgroundColor: Colors.white54,
                  strokeWidth: 10.0,
                  strokeCap: StrokeCap.round,
                  isTimerTextShown: false,
                  isReverse: true,
                  isReverseAnimation: true,
                  onComplete: (){
                  },
                  textStyle: TextStyle(fontSize: 50.0,color: Colors.black),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    LabelText(
                        'HRS', hours.toString().padLeft(2, '0')),
                    LabelText(
                        'MIN',minutes.toString().padLeft(2, '0')),
                    LabelText(
                        'SEC',seconds.toString().padLeft(2, '0')),
                  ],
                )
              ],
            )
          )
        : SizedBox(
            width: MediaQuery.of(context).size.width - 85,
            height: MediaQuery.of(context).size.width - 85,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularCountDownTimer(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width,
                  duration: timePhun,
                  fillColor: AppColors.tertiary,
                  ringColor: AppColors.tertiary,
                  controller: _controller,
                  backgroundColor: Colors.white54,
                  strokeWidth: 10.0,
                  strokeCap: StrokeCap.round,
                  isTimerTextShown: false,
                  isReverse: true,
                  isReverseAnimation: true,
                  onComplete: (){
                  },
                  textStyle: TextStyle(fontSize: 50.0,color: Colors.black),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    LabelText(
                        'HRS', '00'),
                    LabelText(
                        'MIN', '00'),
                    LabelText(
                        'SEC', '00'),
                  ],
                )
              ],
            )
          );
  }

  Widget buttonTime(){
    return Center(
      child: IconButton(
        splashRadius: 50,
        iconSize: 100,
        icon:Icon(Icons.stop_circle_sharp,
          color: AppColors.tertiary,
        ),
        onPressed: (){
          if (timePhun != 0 && model != null && _isConnected){
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context)=> CupertinoAlertDialog(
                  title: Text(
                      'Dừng ngay',
                      style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w500)),
                  content: Padding(
                    padding: EdgeInsets.fromLTRB(0,7,0,7),
                    child: Text(
                        'Bạn có chắc chắn muốn dừng chương trình không?',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400)),
                  ),
                  actions: [
                    CupertinoDialogAction(child: TextButton(
                      child: Text(
                          'Có',
                          style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w500,color: Colors.red)),
                      onPressed: (){
                        setState(() {
                          timeUp = timePhun - timeUp;
                          updateHistoryToFireStore(year.toString(), month.toString(), day.toString(), time.toString(), timeUp,'2');
                          timePhun = 0;
                          isActive = false;
                          sendData('stop',{'api_key': '$id', 'stopcode':'1'});
                          sendData('response', {'api_key': '$id', 'rescode':'2'});
                        });
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                    )),
                    CupertinoDialogAction(child: TextButton(
                      child: Text(
                          'Không',
                          style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w500, color: Colors.blue)),
                      onPressed: (){
                        Navigator.pop(context);
                      },
                    )),
                  ],
                ));
          }
        },
      ),
    );
  }

  Widget slideChemicalLevel(double? percentage, double width){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        (model != null && _isConnected && percentage != 0)
            ? Text('${(percentage!*100).toInt()}%', style: TextStyle(fontSize: 15))
            : Text('??%', style: TextStyle(fontSize: 15)),
        Row(
          children: [
            SizedBox(
              width: width * 0.29,
              child: Text('Mức hóa chất:',
                  style: TextStyle(
                      fontSize: 17,
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
                      width: percentage == null ? 0 : (width - (width * 0.29 + 42.6)) * percentage,
                      height: 13.4,
                    ),
                  )
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  void errorDisplay(BuildContext context, String error){
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => SimpleDialog(
          contentPadding: EdgeInsets.only(left: 0, right: 0, bottom: 15),
          titlePadding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                (error == 'Quá tải nhiệt !!!')
                    ? Image.asset('assets/temp.png',width: 100)
                    : Image.asset('assets/error-water-level.png',width: 100),
                SizedBox(height: 20),
                Text(error,
                    style: TextStyle(fontSize: 20, color: Colors.red)),
                Container(
                  margin: EdgeInsets.fromLTRB(30,10,30,5),
                  height: 1.5,
                  color: Color(0xffDDDDDD),
                )
              ]),
          children: <Widget>[
            Center(
              child:ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Material(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        checkErrorTemp = false;
                        checkErrorChemical = false;
                        checkShowdialog = false;
                        checkConfirmButton = true;
                      });
                      Navigator.pop(context);
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
          ],
        ));
  }

  Widget LabelText(String label, String value){
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: AppColors.tertiary,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$value',
            style: TextStyle(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          Text(
            '$label',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
