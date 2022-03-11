import 'dart:async';
import 'dart:convert' as cnv;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mist_app/qr_code/qr_code_create.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:mist_app/theme/constant.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:rxdart/rxdart.dart';
import 'package:image_picker/image_picker.dart';
import '../counttime.dart';
import '../network_request/user_model.dart';
import 'json_qr_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:dio/dio.dart';

class QRScan extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRScan();
}

class _QRScan extends State<QRScan> with SingleTickerProviderStateMixin{
  String qrCode = 'Unknown';
  CollectionReference mistapp = FirebaseFirestore.instance.collection('mistapp');
  CollectionReference machine = FirebaseFirestore.instance.collection('$id');

  //Khai báo QR
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  final picker = ImagePicker();
  String? _data;

  //Hàm check trạng thái
  int temp = 0;
  int checkTemp = 0;
  int checkFlow = 0;
  int loadcell = 0;
  bool _isConnected = false;
  bool checkStatus = false;
  bool checkQr = false;
  String? speed;
  Timer? timerLoadData;

  List<UserModel>? model;
  Future<void> getDataHttp() async {
    timerLoadData = Timer.periodic(Duration(seconds: 3), (Timer t) async {
      var response = await Dio().getUri(Uri.http('192.168.16.2', '/getweighttemp', {'api_key': '$id'}));
      if (response.statusCode == 200){
        List<dynamic> body = cnv.jsonDecode(response.data);
        model = body.map((dynamic item) => UserModel.fromJson(item)).cast<UserModel>().toList();
        setState(() {
          temp = int.parse(model![0].temp.toString());
          loadcell = int.parse(model![0].loadcell.toString());
        });
      }
      temp = int.parse(model![0].temp.toString());
      loadcell = int.parse(model![0].loadcell.toString());
    });
  }

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

  @override
  void initState() {
    timerLoadData = Timer.periodic(Duration(seconds: 1), (Timer t) {
      getDataHttp();
    });
    _events = StreamController<int>.broadcast();
    super.initState();
  }


  void _getPhotoByGallery() {
    Stream.fromFuture(picker.pickImage(source: ImageSource.gallery))
        .flatMap((file) {
      return Stream.fromFuture(QrCodeToolsPlugin.decodeFrom(file!.path));
    }).listen((data) {
      setState(() {
        _data = data;
        UserQrCode user = UserQrCode.fromJson(cnv.jsonDecode(_data!));
        speed = user.speed.toString();
        FeedBackQr(user.room.toString(), user.volume.toString(), int.parse(user.speed.toString()));
      });
    }).onError((error, stackTrace) {
      setState(() {
        _data = '';
      });
    }) ;
  }

  void FeedBackQr(String room, String volume, int speed,){
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
                  new Text("Đang kiểm tra..."),
                ],
              ),
            )
        );
      },
    );
    new Future.delayed(new Duration(seconds: 2), () {
      Navigator.pop(context); //pop dialog
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return SimpleDialog(
              contentPadding: EdgeInsets.only(left: 10, right: 10, bottom: 15),
              titlePadding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Xác nhận thông tin',
                        style: TextStyle(color: AppColors.tertiary, fontSize: 20)),
                    Container(
                      margin: EdgeInsets.fromLTRB(30,10,30,0),
                      height: 1.5,
                      color: Color(0xffDDDDDD),
                    )
                  ]),
              children: <Widget>[
                InformationQr('Tên phòng:','$room'),
                InformationQr('Thể tích phòng:','$volume m\u00B3'),
                InformationQr('Nồng độ:','$speed ml/m\u00B3'),
                ActionButton('$room', '$speed', '$volume'),
              ],
            );
          }
      );
    });
  }


  void dispose() {
    super.dispose();
    controller!.dispose();
    timerLoadData!.cancel();
    timer!.cancel();
  }

  @override
  void reassemble() async {
    // TODO: implement reassemble
    super.reassemble();
    if (Platform.isAndroid){
      await controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context){
    checkConnectivty();
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          buildQrView(context),
          Positioned(
            child: Options(),
            top: 37,
            right: 15,
          ),
          Positioned(
            child: CameraButton(),
            top: 25,
            left: 5,
          ),
          Positioned(
            child: FlashButton(),
            bottom: 70,
          ),
          Positioned(
            child: buildResult(),
            bottom: 20,
          ),
        ],
      ),
    );
  }

  void ShowdialogStatus(int timeQr){
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
                  new Text("Kiểm tra trạng thái máy..."),
                ],
              ),
            )
        );
      },
    );
    new Future.delayed(new Duration(seconds: 2), () {
      _startTimer();
      Navigator.pop(context); //pop dialog
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.only(
                left: 10, right: 10, bottom: 15),
            titlePadding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  !checkStatus
                      ? Image.asset('assets/checked.png', width: 60)
                      : Image.asset('assets/error.png', width: 60),
                  SizedBox(height: 10),
                  !checkStatus
                      ? Text('Tiến hành phun sau',
                      style: TextStyle(
                          color: AppColors.tertiary, fontSize: 20))
                      : Text('Phát hiện lỗi',
                      style: TextStyle(color: Colors.red, fontSize: 20)),
                  Container(
                    margin: EdgeInsets.fromLTRB(30, 10, 30, 0),
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
                      builder: (BuildContext context,
                          AsyncSnapshot<int> snapshot) {
                        SchedulerBinding.instance!.addPostFrameCallback((
                            _) {
                          if (secondsPassed == 0 && !checkStatus) {
                            timePhun = timeQr;
                            Navigator.pop(context);
                            machine.doc('user').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                              sendData('start',{'api_key': '${id}',
                                'speed':'$speed',  //cần sửa do đây là chạy nhanh ko có
                                'flow':'${documentSnapshot['flow'].toString()}',
                                'time':'$timePhun',
                              });
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TimerApp()),
                            );
                            timer!.cancel;
                          };
                        });
                        return timeApp(timeQr);
                      })
                      : Container(),
                  statusCard(checkTemp, checkFlow),
                  SizedBox(height: 10),
                  (checkStatus)
                      ? Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Material(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              checkQr = false;
                              result = null;
                            });
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
                              timePhun = timeQr;
                              result = null;
                              timer!.cancel;
                              Navigator.pop(context);
                              machine.doc('user').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
                                sendData('start',{'api_key': '$id',
                                  'speed':'$speed',  //cần sửa do đây là chạy nhanh ko có
                                  'flow':'${documentSnapshot['flow'].toString()}',
                                  'time':'$timePhun',
                                });
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TimerApp()),
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
                              setState(() {
                                checkQr = false;
                                result = null;
                              });
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
        },
      );
    });
  }

  Widget Options(){
    return PopupMenuButton(
      offset: Offset(0, 33),
      initialValue: 2,
      onSelected: (result){
        if (result == 1){
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
                        Text('    Nhập thông tin'),
                        Spacer(flex: 1),
                        ElevatedButton(
                      child: Icon(Icons.clear,size: 22, color: AppColors.tertiary),
                      onPressed: () {
                        Navigator.pop(context);
                        },
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        elevation: 2,
                        primary: Colors.white),
                        )
                      ]),
                      children: <Widget>[
                        CreateQrCode()
                      ]
              )
          );
        }
      },
      child: Image.asset(
        "assets/options.png",
        color: Colors.white,
        width: 25,
      ),
      itemBuilder: (context) =>[
        PopupMenuItem(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 2),
                Image.asset('assets/gallery.png', color: Colors.black, width: 25,),
                SizedBox(width: 12),
                Text('Duyệt ảnh', style: TextStyle(color: Colors.black)),
              ],
            ),
          onTap: () {
            _getPhotoByGallery();
          },
        ),
        PopupMenuItem(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.qr_code_sharp, color: Colors.black, size: 31,),
              SizedBox(width: 9),
              Text('Tạo mã', style: TextStyle(color: Colors.black)),
            ],
          ),
          value: 1,
        ),
      ],

    );
  }

  Widget FlashButton(){
    return IconButton(
        onPressed: () async {
          await controller?.toggleFlash();
          setState(() {});
        },
        icon: FutureBuilder<bool?>(
            future: controller?.getFlashStatus(),
            builder: (context, snapshot){
              if (snapshot.data != null){
                return Icon(snapshot.data! ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 30,
                );
              }
              return Container();
            }
        )
    );
  }

  Widget CameraButton(){
    return IconButton(
        onPressed: () async {
          await controller?.flipCamera();
          setState(() {});
        },
        icon: Image.asset('assets/switch-camera.png', width: 30, color: Colors.white,),
    );
  }

  Icon _getCorrectIcon(String iconName) {
    switch (iconName) {
      case 'Tên phòng:':
        return Icon(Icons.drive_file_rename_outline_outlined);
      case 'Thể tích phòng:':
        return Icon(Icons.home_work_outlined);
      case 'Lưu lượng:':
        return Icon(Icons.water);
      case 'Mức nhiệt độ:':
        return Icon(Icons.device_thermostat);
      case 'Nồng độ:':
        return Icon(Icons.waterfall_chart);
      default:
        return Icon(Icons.drive_file_rename_outline_outlined);
    }
  }

  Widget InformationQr(String name, String data){
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _getCorrectIcon(name),
                  Text(" ${name}",  style: TextStyle(fontSize: 16)),
                ],
              ),
              Text('$data', style: TextStyle(fontSize: 16)),
            ]
        )
    );
  }

  Widget ActionButton(String roomname, String speed, String volume){
    machine.doc('user').collection('settings').doc('settings').get().then((DocumentSnapshot documentSnapshot) {
      timePhun = int.parse(speed.toString()) * int.parse(volume.toString()) * 60
          ~/ int.parse(documentSnapshot['flow'].toString());
      checkTemp = int.parse(documentSnapshot['temp'].toString());
      checkFlow = int.parse(documentSnapshot['flow'].toString());
    });
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Material(
            child: InkWell(
              onTap: () {
                if (!_isConnected) {
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
                if (_isConnected && (model == null)) {
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
                else if (_isConnected == true && model != null) {
                  if (((timePhun * checkFlow) / 60 - loadcell > 0) || temp >= checkTemp) {
                    setState(() {
                      checkStatus = true;
                    });
                  }
                  else if ((timePhun * checkFlow) / 60 - loadcell < 0 && temp < checkTemp) {
                    checkStatus = false;
                  }
                  print('checkTemp = ${checkTemp}');
                  print('checkFlow = ${checkFlow}');
                  print('chemicalLevel = ${loadcell}');
                  print('checkStatus = ${checkStatus}');
                  Navigator.pop(context);
                  Roomname = roomname;
                  ShowdialogStatus(timePhun);
                }
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
                setState(() {
                  checkQr = false;
                  result = null;
                });
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
    );
  }

  Widget buildResult(){
    return Container(
      padding: EdgeInsets.all(11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white24
      ),
      child:  Text(result != null ? 'Quét thành công !' : 'Đang quét mã ...',
        style: TextStyle(fontSize: 15, color: Colors.white)),
    );
  }

  Widget buildQrView(BuildContext context){
    return QRView(
      key: qrKey,
      onQRViewCreated: onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderRadius: 10,
        borderColor: (result == null) ? Color(0xffFF3030) : Color(0xff00FA9A),
        borderLength: 15,
        borderWidth: 10,
        cutOutSize: 280,
        cutOutBottomOffset: MediaQuery.of(context).size.width * 0.1,
      ),
    );
  }

  void onQRViewCreated(QRViewController controller){
    setState(() {
      this.controller = controller;
      controller.scannedDataStream.listen((scanData) {
        setState(() {
          result = scanData;
        });
        if (result != null && !checkQr){
          UserQrCode user = UserQrCode.fromJson(cnv.jsonDecode(result!.code.toString()));
          FeedBackQr(user.room.toString(), user.volume.toString(), int.parse(user.speed.toString()));
          setState(() {
            checkQr = true;
          });
        }
      });
    });
  }

  Widget timeApp(int timeQr) {
    int hours = timeQr ~/ (3600);
    int minute = (timeQr % (3600)) ~/ 60;
    int second = timeQr % 60;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Column(
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
                  Text(
                    '${hours.toString().padLeft(2, '0')}'
                        ':${minute.toString().padLeft(2, '0')}'
                        ':${second.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 17,
                    ),
                  )
                ],
              ),
              SizedBox(height: 15),
            ],
          ),
        ],
      ),
    );
  }

  Widget statusCard(int checkTemp, int checkFlow){
    timePhun =0;
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
            (temp<checkTemp)
                ? Text('Nhiệt độ động cơ: Cho phép',
              style: TextStyle(fontSize: 18, color: AppColors.tertiary),)
                : Text('Nhiệt độ động cơ: Quá tải',
              style: TextStyle(fontSize: 18, color: Colors.red),),
          ],
        )
    );
  }
}