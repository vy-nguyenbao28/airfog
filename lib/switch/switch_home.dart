import 'dart:async';
import 'dart:ui';
import 'dart:convert' as cnv;
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
import 'package:mist_app/theme/namedisplay_and_id.dart';
import '../counttime.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwitchHome extends StatefulWidget {
  @override
  _SwitchHome createState() => _SwitchHome();
}

class _SwitchHome extends State<SwitchHome>
    with SingleTickerProviderStateMixin {
  //////////////////Khai báo biến
  //Biến Widget
  late int counter = 0;
  String volume = '';
  String creator = '';
  String speed = '';
  String roomname = '';
  String flow = '';
  int selectedCard = 0;
  int checkTemp = 0;
  int checkFlow = 0;
  bool _isConnected = false;
  bool checkStatus = false;
  Timer? timerRefresh;
  Timer? timerLoadData;

  //TabBar
  late TabController _tabController;

  //Firestore
  CollectionReference machine = FirebaseFirestore.instance.collection('$id');

  //TextController
  final textVolume = TextEditingController();
  final textUser = TextEditingController();
  final textRoom = TextEditingController();

  //Các hàm ngoài

  Future getDocs() async {
    setState(() async {
      QuerySnapshot _myDoc = await FirebaseFirestore.instance.collection('user').get();
      List<DocumentSnapshot> _myDocCount = _myDoc.docs;
      counter = _myDocCount.length;
      print('coutner $counter');
    });
  }

  void getDataFireStore(String ID, int index) {
    machine.doc('user').collection('user').doc(ID).get().then((DocumentSnapshot documentSnapshot) {
      creator = documentSnapshot['creator'];
      volume = documentSnapshot['volume'];
      speed = documentSnapshot['speed'];
      roomname = documentSnapshot['roomname'];
      machine.doc('user').collection('user').doc('${index}').set({
        'creator': creator,
        'volume': volume,
        'speed': speed,
        'roomname': roomname,
      });
    });
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

  //Các hàm cho timeApp
  StreamController<int>? _events;
  int secondsPassed = 0;
  Timer? timer;
  void _startTimer() {
    secondsPassed = 20;
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      (secondsPassed > 0) ? secondsPassed-- : timer.cancel();
      _events!.add(secondsPassed);
    });
  }

  void makeDio(String api, final dataSend)async  {
    Dio().getUri(Uri.http('192.168.16.2','/$api',dataSend));
  }

  Future<void> getTime() async {
    machine.doc('user').collection('settings').doc('selectedCard').get().then((DocumentSnapshot documentSnapshot) {
      selectedCard = int.parse(documentSnapshot['selectedCard'].toString());
      machine.doc('user').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
        checkTemp = int.parse(documentSnapshot['temp'].toString());
        checkFlow = int.parse(documentSnapshot['flow'].toString());
        flow = documentSnapshot['flow'].toString();
        machine.doc('user').collection('user').doc('countuser').get().then((DocumentSnapshot documentSnapshot) {
          machine.doc('user').collection('user').doc('${int.parse(documentSnapshot['countuser'].toString())- selectedCard - 1}').get().then((DocumentSnapshot documentSnapshot) {
            int speed = int.parse(documentSnapshot['speed'].toString());
            int volume = int.parse(documentSnapshot['volume'].toString());
            Roomname = documentSnapshot['roomname'].toString();
            timePhun = speed * volume * 60 ~/ checkFlow;
          });
        });
      });
    });
  }

  //Linh tinh
  void getSelectedCard() {
    machine.doc('user').collection('settings').doc('selectedCard').get().then((DocumentSnapshot documentSnapshot) {
      selectedCard = int.parse(documentSnapshot['selectedCard'].toString());
    });
  }
  String? get _errorTextUser {
    final text = textUser.value.text;
    if (text.isEmpty) {
      return '*Bắt buộc';
    }
    return null;
  }
  String? get _errorTextRoom {
    final text = textRoom.value.text;
    if (text.isEmpty) {
      return '*Bắt buộc';
    }
    return null;
  }
  String? get _errorTextVolume {
    final text = textVolume.value.text;
    if (text.isEmpty) {
      return '*Bắt buộc';
    }
    if (text.length == 1) {
      return '* Thể tích quá nhỏ';
    }
    if (double.tryParse(text) == null) {
      return '* Nhập kiểu số';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    getSelectedCard();
    _events = StreamController<int>.broadcast();
  }

  @override
  void dispose() {
    super.dispose();
    timerRefresh!.cancel();
    timerLoadData!.cancel();
    timer!.cancel();
    _tabController.dispose();
  }
  //List Widget

  @override
  Widget build(BuildContext context) {
    machine.doc('user').collection('user').doc('countuser').get().then((DocumentSnapshot documentSnapshot) {
      counter = int.parse(documentSnapshot['countuser'].toString());
    });
    checkConnectivty();
    return ListView(
      padding: EdgeInsets.fromLTRB(0,0,0,20),
      children: [
        valueCard(),
        SizedBox(height: 4),
        Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Chương trình',
                    style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 25)),
                addUserButton(),
              ],
            )),
        SizedBox(
            height: MediaQuery.of(context).size.height - 400,
            child: (counter == 0)
                ? Center(child: Text('Chưa có chương trình', style: TextStyle(fontSize: 30),),)
                : ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: counter,
              itemBuilder: (context, index) => roomCard(index),
            )
        )
      ],
    );
  }

  Widget addUserButton() => ElevatedButton(
        child: Icon(Icons.add, size: 30, color: Colors.white),
        onPressed: () {
          if (_isConnected == false){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Không có kết nối Internet !!!',
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
          else if (_isConnected == true){
            getDocs();
            double speed = 0;
            textVolume.clear();
            textUser.clear();
            textRoom.clear();
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) => SimpleDialog(
                  contentPadding: EdgeInsets.only(left: 10, right: 10),
                  titlePadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  title: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(''),
                        Spacer(flex: 3),
                        Text('Thiết lập'),
                        Spacer(flex: 1),
                        ElevatedButton(
                          child: Icon(Icons.clear,
                              size: 22, color: AppColors.tertiary),
                          onPressed: () {
                            textVolume.clear();
                            textUser.clear();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              elevation: 2,
                              primary: Colors.white),
                        )
                      ]),
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: textUser,
                          builder: (context, TextEditingValue value, __) {
                            return TextFormField(
                              decoration: InputDecoration(
                                icon: Icon(
                                  Icons.perm_identity_outlined,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                labelText: 'Người tạo',
                                focusColor: Colors.black,
                                errorText: _errorTextUser,
                              ),
                              autofocus: true,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.send,
                              controller: textUser,
                              cursorColor: Colors.blueGrey,
                            );
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: textRoom,
                          builder: (context, TextEditingValue value, __) {
                            return TextFormField(
                              decoration: InputDecoration(
                                icon: Icon(
                                  Icons.house_outlined,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                labelText: 'Tên phòng',
                                focusColor: Colors.black,
                                errorText: _errorTextRoom,
                              ),
                              textInputAction: TextInputAction.send,
                              textCapitalization: TextCapitalization.words,
                              controller: textRoom,
                              cursorColor: Colors.blueGrey,
                            );
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: textVolume,
                          builder: (context, TextEditingValue value, __) {
                            return TextFormField(
                              decoration: InputDecoration(
                                icon: Icon(
                                  Icons.home_work_outlined,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                labelText: 'Thể tích (m\u00B3)',
                                focusColor: Colors.black,
                                errorText: _errorTextVolume,
                              ),
                              textInputAction: TextInputAction.send,
                              maxLength: 3,
                              controller: textVolume,
                              keyboardType: TextInputType.number,
                              cursorColor: Colors.blueGrey,
                            );
                          },
                        ),
                        Text("Nồng độ: ${speed.toInt().toString().padLeft(2, '0')} ml/m\u00B3",
                            style: TextStyle(fontSize: 18)),
                        SliderTheme(
                            data: SliderThemeData(trackHeight: 7),
                            child: Slider(
                              value: speed,
                              min: 0,
                              max: 16,
                              divisions: 16,
                              label: speed.round().toString(),
                              onChanged: (double Value) {
                                setState(() {
                                  speed = Value;
                                  (context as Element).markNeedsBuild();
                                });
                              },
                              activeColor: Colors.blue,
                              inactiveColor: Color(0xffC0C0C0),
                            )),
                        Center(
                            child: RawMaterialButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                                elevation: 2.0,
                                fillColor: AppColors.tertiary,
                                onPressed: () => {
                                  if (textUser.text == '' ||
                                      textVolume.value.text.length <=1 ||
                                      textRoom.text == ''||
                                      speed == 0 ){
                                    null
                                  }
                                  else{
                                    machine.doc('user').collection('user').doc('${counter}').set({
                                      'creator': textUser.text,
                                      'speed': speed.toInt().toString(),
                                      'volume': textVolume.text,
                                      'roomname': textRoom.text,
                                    }),
                                    machine.doc('user').collection('user').doc('countuser').set({
                                      'countuser': '${counter+1}',
                                    }),
                                    textVolume.clear(),
                                    textUser.clear(),
                                    textRoom.clear(),
                                    Navigator.pop(context),
                                    setState(() {
                                      (context as Element).markNeedsBuild();
                                    }),
                                  }
                                },
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(15,5,15,5),
                                    child: Text('Xác nhận',
                                        style: TextStyle(
                                            fontSize: 20, color: Colors.white)))
                            )
                        ),
                        SizedBox(height: 10)
                      ],
                    )
                  ],
                ));
          }
        },
        style: ElevatedButton.styleFrom(
            shape: CircleBorder(), elevation: 2, primary: AppColors.tertiary),
      );

  Widget editUserButton(String creator, double speed, String volume,
          String roomname, String id) =>
      TextButton(
        child: Icon(Icons.edit_outlined, size: 30, color: Color(0xffDF0029)),
        onPressed: () {
          if (_isConnected == false){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Không có kết nối Internet !!!',
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
          else if (_isConnected == true){
            getDocs();
            textUser.text = creator;
            textVolume.text = volume;
            textRoom.text = roomname;
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) => SimpleDialog(
                  contentPadding: EdgeInsets.only(left: 10, right: 10),
                  titlePadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  title: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(''),
                        Spacer(flex: 3),
                        Text('Thiết lập'),
                        Spacer(flex: 1),
                        ElevatedButton(
                          child: Icon(Icons.clear,
                              size: 22, color: AppColors.tertiary),
                          onPressed: () {
                            textVolume.clear();
                            textUser.clear();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              elevation: 2,
                              primary: Colors.white),
                        )
                      ]),
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: textUser,
                          builder: (context, TextEditingValue value, __) {
                            return TextFormField(
                              decoration: InputDecoration(
                                icon: Icon(
                                  Icons.perm_identity_outlined,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                labelText: 'Người tạo',
                                focusColor: Colors.black,
                                errorText: _errorTextUser,
                              ),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.send,
                              controller: textUser,
                              cursorColor: Colors.blueGrey,
                            );
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: textRoom,
                          builder: (context, TextEditingValue value, __) {
                            return TextFormField(
                              decoration: InputDecoration(
                                icon: Icon(
                                  Icons.house_outlined,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                labelText: 'Tên phòng',
                                focusColor: Colors.black,
                                errorText: _errorTextRoom,
                              ),
                              textInputAction: TextInputAction.send,
                              textCapitalization: TextCapitalization.words,
                              controller: textRoom,
                              cursorColor: Colors.blueGrey,
                            );
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: textVolume,
                          builder: (context, TextEditingValue value, __) {
                            return TextFormField(
                              decoration: InputDecoration(
                                icon: Icon(
                                  Icons.home_work_outlined,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                labelText: 'Thể tích (m\u00B3)',
                                focusColor: Colors.black,
                                errorText: _errorTextVolume,
                              ),
                              textInputAction: TextInputAction.send,
                              maxLength: 3,
                              controller: textVolume,
                              keyboardType: TextInputType.number,
                              cursorColor: Colors.blueGrey,
                            );
                          },
                        ),
                        Text("Nồng độ: ${speed.toInt().toString().padLeft(2, '0')} ml/m\u00B3",
                            style: TextStyle(fontSize: 18)),
                        SliderTheme(
                            data: SliderThemeData(trackHeight: 7),
                            child: Slider(
                              value: speed,
                              min: 0,
                              max: 16,
                              divisions: 16,
                              label: speed.round().toString(),
                              onChanged: (double Value) {
                                setState(() {
                                  speed = Value;
                                  (context as Element).markNeedsBuild();
                                });
                              },
                              activeColor: Colors.blue,
                              inactiveColor: Color(0xffC0C0C0),
                            )),
                        Center(
                            child: RawMaterialButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                                elevation: 2.0,
                                fillColor: AppColors.tertiary,
                                onPressed: () => {
                                  if (textUser.text == '' ||
                                      textVolume.text.length <=1 ||
                                      textRoom.text == ''||
                                      speed == 0 ){
                                    null
                                  }
                                  else{
                                    machine.doc('user').collection('user').doc(id).set({
                                      'creator': textUser.text,
                                      'speed': speed.toInt().toString(),
                                      'volume': textVolume.text,
                                      'roomname': textRoom.text,
                                    }),
                                    Navigator.pop(context),
                                  }
                                },
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(15,5,15,5),
                                    child: Text('Xác nhận',
                                        style: TextStyle(
                                            fontSize: 20, color: Colors.white)))
                            )
                        ),
                        SizedBox(height: 10)
                      ],
                    )
                  ],
                ));
          }
        },
      );

  Widget valueCard() {
    final double sliderWidth = MediaQuery.of(context).size.width;
    getTime();
    return Container(
        margin: EdgeInsets.only(right: 20, left: 20, top: 0),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
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
                          (model == null || !_isConnected)
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
                    Container(height: 60, width: 1.5, color: Colors.grey),
                    SizedBox(
                      width: (sliderWidth / 2) * 0.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          SizedBox(height: 7),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20),
                              (model == null || !_isConnected)
                                  ? Text('??',
                                  style: TextStyle(
                                      fontSize: 50, color: Colors.grey,fontWeight: FontWeight.w400))
                                  : Container(),
                              (model != null && _isConnected)
                                  ? Text('${model![0].temp.toString()}',
                                  style: TextStyle(
                                      fontSize: 50, color: Colors.red,fontWeight: FontWeight.w400))
                                  : Container(),
                              Text('o',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.red,fontWeight: FontWeight.w500)),
                              Text('C',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.red,fontWeight: FontWeight.w400)),
                            ],
                          ),
                          RawMaterialButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              elevation: 2.0,
                              fillColor: AppColors.tertiary,
                              onPressed: () {
                                if (!_isConnected){
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: const Text('Không có kết nối Internet !!!',
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
                                machine.doc('user').collection('user').doc('countuser').get().then((DocumentSnapshot documentSnapshot) {
                                  if (documentSnapshot['countuser'].toString() == '0'){
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: const Text('Không có chương trình thực thi',
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
                                  if (_isConnected && (model == null)){
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: const Text('Không có kết nối với máy !!!',
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
                                  else if (documentSnapshot['countuser'].toString() != '0' &&_isConnected == true && model != null){
                                    if (((timePhun * checkFlow) / 60 - loadcell > 0) || temp >= checkTemp){
                                      setState(() {
                                        checkStatus = true;
                                      });
                                    }else if ((timePhun * checkFlow) / 60 - loadcell < 0 && (temp<checkTemp)){
                                      checkStatus = false;
                                      _startTimer();
                                    };
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (BuildContext context) => SimpleDialog(
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
                                                          print('time = $timePhun');
                                                          machine.doc('user').collection('user').doc('${counter - selectedCard - 1}').get().then((DocumentSnapshot documentSnapshot) {
                                                            int speed = int.parse(documentSnapshot['speed'].toString());
                                                            machine.doc('user').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                                                              makeDio('start',{'api_key': '$id',
                                                                'speed':'$speed',
                                                                'flow':'${documentSnapshot['flow'].toString()}',
                                                                'time':'$timePhun',
                                                              });
                                                            });
                                                          });
                                                          Navigator.pop(context);
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(builder: (context) => TimerApp()),
                                                          );
                                                          timer!.cancel;
                                                        };
                                                      });
                                                      return timeApp();
                                                    })
                                                    : SizedBox(width: 0),
                                                statusCard(timePhun,checkFlow, checkTemp),
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
                                                          width: 200,
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
                                                            print('time = $timePhun');
                                                            machine.doc('user').collection('user').doc('${counter - selectedCard - 1}').get().then((DocumentSnapshot documentSnapshot) {
                                                              int speed = int.parse(documentSnapshot['speed'].toString());
                                                              machine.doc('user').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                                                                makeDio('start',{'api_key': '$id',
                                                                  'speed':'$speed',
                                                                  'flow':'${documentSnapshot['flow'].toString()}',
                                                                  'time':'$timePhun',
                                                                });
                                                              });
                                                            });
                                                            timer!.cancel;
                                                            Navigator.pop(context);
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(builder: (context) => TimerApp()),
                                                            );
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
                                        ));
                                  }
                                });
                              },
                              child: Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(
                                        Icons.not_started,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      Text(" Bắt đầu",
                                          style: TextStyle(
                                            fontSize: 19,
                                            color: Colors.white,
                                          )),
                                    ],
                                  ))),
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

  Widget roomCard(int index) {
    return GestureDetector(
      onTap: () => {
        machine.doc('user').collection('settings').doc('selectedCard').set({'selectedCard': index}),
          setState(
            () => {
              print(index),
              selectedCard = index,
            },
          ),
      },
      child: StreamBuilder<DocumentSnapshot>(
          stream: machine.doc('user').collection('settings').doc('selectedCard').snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                  child: Text('Đang tải...',
                      style: TextStyle(fontSize: 15)));
            }
            return (snapshot.hasData)
                ? Container(
                margin: EdgeInsets.only(right: 18, top: 5, bottom: 17, left: 18),
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color:
                    int.parse(snapshot.data!['selectedCard'].toString()) == index ? AppColors.primary : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lighterGray,
                        blurRadius: 10,
                      )
                    ]),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(width: 5),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 10,
                          ),
                          Image.asset('assets/Room.png', width: 47),
                          StreamBuilder<DocumentSnapshot>(
                              stream: machine.doc('user').collection('user').doc('countuser').snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (!snapshot.hasData) {
                                  return Icon(Icons.edit_outlined, size: 30, color: Color(0xffDF0029));
                                }
                                int idInput = int.parse(snapshot.data!['countuser'].toString()) - index - 1;
                                return StreamBuilder<DocumentSnapshot>(
                                    stream: machine.doc('user').collection('user')
                                        .doc('${idInput}').snapshots(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                                      if (!snapshot.hasData) {
                                        return Icon(Icons.edit_outlined, size: 30, color: Color(0xffDF0029));
                                      }
                                      return editUserButton(
                                          snapshot.data!['creator'].toString(),
                                          double.parse(snapshot.data!['speed'].toString()),
                                          snapshot.data!['volume'].toString(),
                                          snapshot.data!['roomname'].toString(),
                                          idInput.toString());
                                    });
                              }),
                        ],
                      ),
                      Container(height: 60, width: 1.5, color: Colors.grey),
                      SizedBox(width: 15),
                      Column(
                        children: [
                          SizedBox(
                            height: 95,
                            child: StreamBuilder<DocumentSnapshot>(
                                stream: machine.doc('user').collection('user').doc('countuser')
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (!snapshot.hasData) {
                                    return Center(
                                        child: Text('Đang tải...',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w300
                                            )));
                                  }
                                  return (!snapshot.data!.exists || !snapshot.hasData)
                                      ? Center(
                                      child: Text('Đang xóa...',
                                          style: TextStyle(
                                            fontSize: 20,
                                          )))
                                      : StreamBuilder<DocumentSnapshot>(
                                      stream: machine.doc('user').collection('user')
                                          .doc('${int.parse(snapshot.data!['countuser'].toString()) - index - 1}')
                                          .snapshots(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                                        if (!snapshot.hasData) {
                                          return Center(
                                              child: Text('Đang tải...',
                                                  style: TextStyle(fontSize: 15)));
                                        }
                                        return (!snapshot.data!.exists || !snapshot.hasData)
                                            ? Center(
                                            child: Text('Đang xóa...',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                )))
                                            :Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text('${snapshot.data!["roomname"]}',
                                                style: TextStyle(
                                                    fontSize: 19,
                                                    fontWeight: FontWeight.w500)),
                                            Text('Người tạo: ${snapshot.data!["creator"]}',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xff696969)
                                                )),
                                            Text('Thể tích phòng: ${snapshot.data!["volume"]} m\u00B3',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xff696969)
                                                )),
                                            Text('Nồng độ: ${snapshot.data!["speed"]} ml/m\u00B3',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xff696969)
                                                )),
                                          ],
                                        );
                                      });
                                }),
                          )
                        ],
                      ),
                      Spacer(
                        flex: 2,
                      ),
                      RawMaterialButton(
                        elevation: 3,
                        onPressed: () {
                          if (_isConnected == false){
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('Không có kết nối Internet !!!',
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
                          else if (_isConnected == true){
                            showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (BuildContext context) => CupertinoAlertDialog(
                                  title: Text('Xóa chương trình',
                                      style: TextStyle(
                                          fontSize: 23, fontWeight: FontWeight.w500)),
                                  content:  Padding(
                                    padding: EdgeInsets.fromLTRB(0,7,0,7),
                                    child:  Text(
                                        'Bạn có chắc chắn muốn xóa chương trình không?',
                                        style: TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w400)),
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                        child: TextButton(
                                          child: Text('Có',
                                              style: TextStyle(
                                                  fontSize: 23,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.red)),
                                          onPressed: () {
                                            machine.doc('user').collection('user').doc('countuser').get().then((DocumentSnapshot documentSnapshot) {
                                              int counter = int.parse(documentSnapshot['countuser'].toString());
                                              if (index < (counter - 1) && index > 0) {
                                                machine.doc('user').collection('user').doc('countuser').set({
                                                  'countuser': '0'
                                                });
                                                Future.delayed(new Duration(milliseconds: 50), () {
                                                  for (int i = counter - 1; i >=counter - index ; i--) {
                                                    getDataFireStore((i).toString(), i - 1);
                                                  }
                                                  machine.doc('user').collection('user').doc('${counter - 1}').delete();
                                                  machine.doc('user').collection('user').doc('countuser').set({
                                                    'countuser': '${counter-1}'
                                                  });
                                                });
                                              }
                                              else if (index == 0) {
                                                machine.doc('user').collection('user').doc('${counter - 1}').delete();
                                                machine.doc('user').collection('user').doc('countuser').set({
                                                  'countuser': '${counter-1}'
                                                });
                                              }
                                              else if (index == (counter - 1)) {
                                                machine.doc('user').collection('user').doc('0').delete();
                                                machine.doc('user').collection('user').doc('countuser').set({
                                                  'countuser': '${counter-1}'
                                                });
                                                for (int i = 1; i <= counter - 1; i++) {
                                                  getDataFireStore((i).toString(), i - 1);
                                                }
                                              }
                                            });
                                            Navigator.pop(context);
                                          },
                                        )),
                                    CupertinoDialogAction(
                                        child: TextButton(
                                          child: Text('Không',
                                              style: TextStyle(
                                                  fontSize: 23,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blue)),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        )),
                                  ],
                                ));
                          }
                        },
                        fillColor: int.parse(snapshot.data!['selectedCard'].toString()) == index ? Colors.white : AppColors.tertiary,
                        shape: CircleBorder(),
                        child: Icon(Icons.clear,
                            size: 20,
                            color: int.parse(snapshot.data!['selectedCard'].toString()) == index
                                ? Colors.black
                                : Colors.white),
                      ),
                    ]))
                : Center(
                child: Text('Đang xóa...',
                    style: TextStyle(
                      fontSize: 20,
                    )));
          })

    );
  }

  Widget timeApp() {
    getTime();
    int seconds = timePhun % 60;
    int minutes = (timePhun % (3600)) ~/ 60;
    int hours = timePhun ~/ (3600);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Text('${(secondsPassed % 60).toString().padLeft(2, '0')} giây',
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 25
                  ),),
              ),
              SizedBox(height: 15),
              (!checkStatus)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Thời gian phun dự kiến: ', style: TextStyle(fontSize: 17),
                        ),
                        (secondsPassed>19) ? SizedBox(width: 25) : SizedBox(width: 0),
                        (secondsPassed>19)
                          ?  SizedBox(
                            height: 23,
                            width: 23,
                            child: new CircularProgressIndicator(
                            value: null,
                            strokeWidth: 3,
                            ),
                          )
                          : Text('${hours.toString().padLeft(2, '0')}:'
                                 '${minutes.toString().padLeft(2, '0')}:'
                                 '${seconds.toString().padLeft(2, '0')}'
                                 ,style: TextStyle(fontSize: 17),
                            ),
                        ],
                    )
                  : SizedBox(width: 0),
              SizedBox(height: 15),
            ],
          ),
        ],
      ),
    );
  }

  Widget statusCard(int timPhun, int checkFlow, int checkTemp){
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ((timePhun * checkFlow) / 60 - loadcell <= 0)
                ? Text('Mức hóa chất: Đủ',
              style: TextStyle(fontSize: 18, color: AppColors.tertiary),)
                : Text('Mức hóa chất: Thiếu ${((timePhun * 33) / 60 - loadcell).toInt()} ml ',
              style: TextStyle(fontSize: 18, color: Colors.red),),
            (temp<checkTemp)
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