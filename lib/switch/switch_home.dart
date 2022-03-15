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
import '../counttime.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SwitchHome extends StatefulWidget {
  @override
  _SwitchHome createState() => _SwitchHome();
}

class _SwitchHome extends State<SwitchHome>
    with SingleTickerProviderStateMixin {
  //////////////////Khai báo biến
  //Biến Widget
  int counter = 0;
  String volume = '';
  String creator = '';
  String speed = '';
  String roomname = '';

  int selectedCard = 0;
  int checkTemp = 0;
  int checkFlow = 0;

  bool _isConnected = false;
  bool showProgram = false;

  Timer? timerRefresh;
  Timer? timerLoadData;

  //TabBar
  //Firestore
  CollectionReference machine = FirebaseFirestore.instance.collection('$id');

  //TextController
  final textVolume = TextEditingController();
  final textUser = TextEditingController();
  final textRoom = TextEditingController();

  //Các hàm ngoài

  void getDataFireStore(String ID, int index) {
    machine.doc('program').collection('program').doc(ID).get().then((DocumentSnapshot documentSnapshot) {
      creator = documentSnapshot['creator'];
      volume = documentSnapshot['volume'];
      speed = documentSnapshot['speed'];
      roomname = documentSnapshot['roomname'];
      machine.doc('program').collection('program').doc('${index}').set({
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

  //Linh tinh
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

  //Add chương trình vào List
  getCounter() async {
    QuerySnapshot querySnapshot = await machine.doc('program').collection('program').get();
    if (querySnapshot.docs.isNotEmpty){
      List<DocumentSnapshot> _myDocCount = querySnapshot.docs;
      counter = _myDocCount.length;
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

  @override
  void initState() {
    Timer.periodic(Duration(milliseconds: 1500), (Timer t) => setState(() {
      setState(() {
        showProgram = true;
      });
    }));
    getCounter();
    _events = StreamController<int>.broadcast();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    timerRefresh!.cancel();
    timerLoadData!.cancel();
    timer!.cancel();
  }
  //List Widget

  @override
  Widget build(BuildContext context) {
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
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    final snapshot = await FirebaseFirestore.instance.collection('names').get();
                    final documents = snapshot.docs;
                    print(documents); // error
                    print(documents); // []
                  },
                )

              ],
            )),
        SizedBox(
          height: MediaQuery.of(context).size.height - 400,
          child: ListView(
            children: [
              (showProgram)
                  ? (counter != 0)
                      ? Column(
                          children: [
                            SizedBox(
                                height: MediaQuery.of(context).size.height - 400,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  scrollDirection: Axis.vertical,
                                  itemCount: counter,
                                  itemBuilder: (context, index) =>
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(10,5,10,5),
                                        child: roomCard(context, index)
                                      ),
                                )
                            )
                          ]
                        )
                      : Center(child: Text('Không có chương trình', style: TextStyle(fontSize: 30), textAlign: TextAlign.center))
                  : SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
            ],
          ),
        )
      ],
    );
  }

  Widget addUserButton(){
    return ElevatedButton(
      child: Icon(Icons.add, size: 30, color: Colors.white),
      onPressed: () {
        if (_isConnected == false){
          notification('Không có kết nối Internet !!!');
        }
        else if (_isConnected == true){
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
                              onPressed: () {
                                if (textVolume.value.text.length <=1 ||
                                    textRoom.text == ''||
                                    speed == 0 ){
                                  null;
                                }
                                else{
                                  machine.doc('program').collection('program').doc('${counter}').set({
                                    'creator': FirebaseAuth.instance.currentUser!.displayName,
                                    'speed': speed.toInt().toString(),
                                    'volume': textVolume.text,
                                    'roomname': textRoom.text,
                                  });
                                  textVolume.clear();
                                  textUser.clear();
                                  textRoom.clear();
                                  Navigator.pop(context);
                                  setState(() {
                                    counter = counter + 1;
                                  });
                                  (context as Element).markNeedsBuild();
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
  }

  Widget editUserButton(String creator, double speed, String volume, String roomname, int id){
    return TextButton(
      child: Icon(Icons.edit_outlined, size: 30, color: Color(0xffDF0029)),
      onPressed: () {
        if (_isConnected == false){
          notification('Không có kết nối Internet !!!');
        }
        else if (_isConnected == true){
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
                              onPressed: () {
                                if (textVolume.text.length <=1 ||
                                    textRoom.text == ''||
                                    speed == 0 ){
                                  null;
                                }
                                else{
                                  machine.doc('program').collection('program').doc('$id').get().then((DocumentSnapshot documentSnapshot) {
                                    machine.doc('program').collection('program').doc('${id}').set({
                                      'creator': documentSnapshot['creator'].toString(),
                                      'speed': speed.toInt().toString(),
                                      'volume': textVolume.text,
                                      'roomname': textRoom.text,
                                    });
                                  });
                                  (context as Element).markNeedsBuild();
                                  Navigator.pop(context);
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
            (model != null && _isConnected)
                ? slideChemicalLevel(((int.parse(model![0].loadcell.toString())/5000)*100) / 100, sliderWidth)
                : slideChemicalLevel(0, sliderWidth)
          ],
        )
        );
  }

  Widget roomCard(BuildContext context, int index) {
    return Slidable(
      endActionPane: ActionPane(
        extentRatio: 0.25,
        motion:  StretchMotion(),
        children: <Widget>[
          SlidableAction(
            autoClose: true,
            onPressed: (context){deleteProgram(index);},
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Xóa',
          ),
        ]
      ),
      child: Container(
          margin: EdgeInsets.only(right: 10, top: 0, bottom: 0, left: 10),
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary,
              width: 1.5, //                   <--- border width here
            ),
            color: Colors.white,
          ),
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
                        stream: machine.doc('program').collection('program')
                            .doc('${counter - index - 1}')
                            .snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasData) {
                            return editUserButton(
                                snapshot.data!["creator"],
                                double.parse(snapshot.data!["speed"].toString()),
                                snapshot.data!["volume"],
                                snapshot.data!["roomname"],
                                (counter - index - 1)
                            );

                          }
                          return Icon(Icons.edit_outlined, size: 30, color: Color(0xffDF0029));
                        })
                  ],
                ),
                Container(height: 60, width: 1.5, color: AppColors.primary),
                SizedBox(width: 15),
                SizedBox(
                    height: 95,
                    child: StreamBuilder<DocumentSnapshot>(
                        stream: machine.doc('program').collection('program')
                            .doc('${counter - index - 1}')
                            .snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasData) {
                            return Column(
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
                          }
                          return SizedBox(
                            height: 100,
                            child: Center(
                                child: Text('Đang tải...',
                                    style: TextStyle(fontSize: 15))),
                          );
                        })
                ),
                Spacer(
                  flex: 2,
                ),
                RawMaterialButton(
                  elevation: 2,
                  onPressed: () {
                    machine.doc('program').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                      checkTemp = int.parse(documentSnapshot['temp'].toString());
                      checkFlow = int.parse(documentSnapshot['flow'].toString());
                      machine.doc('program').collection('program').doc('${counter- index - 1}').get().then((DocumentSnapshot documentSnapshot) {
                        int speed = int.parse(documentSnapshot['speed'].toString());
                        int volume = int.parse(documentSnapshot['volume'].toString());
                        Roomname = documentSnapshot['roomname'].toString();
                        timePhun = speed * volume * 60 ~/ checkFlow;
                        if (!_isConnected){
                          notification('Không có kết nối Internet !!!');
                        }
                        if (_isConnected && model == null){
                          notification('Không có kết nối với máy');
                        }
                        if (_isConnected ){
                          StartProgram(counter - index - 1);
                        }
                      });
                    });
                  },
                  fillColor: AppColors.tertiary,
                  shape: CircleBorder(),
                  child: Icon(Icons.play_arrow,
                      size: 20,
                      color: Colors.white),
                ),
              ]))
    );
  }

  void StartProgram(int index) {
    bool checkStatus = false;
    if (((timePhun * checkFlow) / 60 - loadcell > 0) || temp >= checkTemp){
      checkStatus = true;
    }
    if ((timePhun * checkFlow) / 60 - loadcell < 0 && (temp < checkTemp)){
      checkStatus = false;
    };
    if (!checkStatus){
      _startTimer();
    }
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => StatefulBuilder(builder: (context, StateSetter setState){
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
                          machine.doc('program').collection('program').doc('${counter - index - 1}').get().then((DocumentSnapshot documentSnapshot) {
                            int speed = int.parse(documentSnapshot['speed'].toString());
                            machine.doc('program').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                              makeDio('start',{'api_key': '$id',
                                'speed':'$speed',
                                'flow':'${documentSnapshot['flow'].toString()}',
                                'time':'$timePhun',
                              });
                            });
                          });
                          Navigator.pop(context);
                          checkBell();
                          timer!.cancel;
                        };
                      });
                      return timeApp(counter - index - 1, checkStatus);
                    })
                    : Container(),
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
                          timer!.cancel();
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
                            machine.doc('program').collection('program').doc('${counter - index - 1}').get().then((DocumentSnapshot documentSnapshot) {
                              int speed = int.parse(documentSnapshot['speed'].toString());
                              machine.doc('program').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                                makeDio('start',{'api_key': '$id',
                                  'speed':'$speed',
                                  'flow':'${documentSnapshot['flow'].toString()}',
                                  'time':'$timePhun',
                                });
                              });
                            });
                            timer!.cancel;
                            Navigator.pop(context);
                            checkBell();
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
      }),
    );
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
                    Text("Đang kiểm tra còi...",style: TextStyle(fontSize: 15)),
                  ],
                ),
              )
          ),
        );
      },
    );
    Future.delayed(Duration(seconds: 5), () async {
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TimerApp()),
      );
    });
  }

  void deleteProgram(int index){
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
                    setState(() {
                      showProgram = false;
                    });
                    Navigator.pop(context);
                    if (index < counter - 1 && index > 0) {
                      setState(() {
                        counter--;
                      });
                      for (int i = counter; i > counter - index; i--) {
                        getDataFireStore((i).toString(), i - 1);
                        if (i == counter - index + 1){
                          Timer.periodic(Duration(milliseconds: 500), (Timer t)
                          => machine.doc('program').collection('program').doc('$counter').delete());
                        }
                      }
                    }
                    else if (index == 0) {
                      setState(() {
                        counter--;
                      });
                      machine.doc('program').collection('program').doc('$counter').delete();
                    }
                    else if (index == counter - 1 && index != 1) {
                      for (int i = 1; i <= counter - 1; i++) {
                        getDataFireStore((i).toString(), i - 1);
                        if (i == counter - 1){
                          Timer.periodic(Duration(milliseconds: 500), (Timer t)
                          => machine.doc('program').collection('program').doc('$counter').delete());
                        }
                      }
                      setState(() {
                        counter--;
                      });
                    }
                    Timer.periodic(Duration(milliseconds: 1500), (Timer t) => setState(() {
                      setState(() {
                        showProgram = true;
                      });
                    }));
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

  Widget timeApp(int index, bool checkStatus) {
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
                          ?  SizedBox(height: 23, width: 23, child: CircularProgressIndicator(),
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