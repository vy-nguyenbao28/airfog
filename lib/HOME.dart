import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:convert' as cnv;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mist_app/check_connect.dart';
import 'package:mist_app/drawer/change_password.dart';
import 'package:mist_app/login/login.dart';
import 'package:mist_app/network_request/user_model.dart';
import 'package:mist_app/qr_code/qr_code_scan.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:mist_app/switch/switch_history.dart';
import 'package:mist_app/switch/switch_home.dart';
import 'package:mist_app/switch/switch_runnow.dart';
import 'package:mist_app/switch/switch_settings.dart';
import 'package:mist_app/switch/switch_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mist_app/drawer/personal_page.dart';
import 'package:mist_app/theme/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTime pre_backpress = DateTime.now();

  List<CheckConnect>? modelconnect;

  CollectionReference machine = FirebaseFirestore.instance.collection('$id');

  void sendData(String mode, final dataSend)async  {
    Dio().getUri(Uri.http('192.168.16.2','/$mode',dataSend));
  }

  void sendDataBLE(String mode, final dataSend)async  {
    Dio().getUri(Uri.http('192.168.16.2','/$mode',dataSend));
  }

  int demcheckdata = 0;

  void getDataHttp() async {
    var response = await Dio().getUri(Uri.http('192.168.16.2', '/getweighttemp', {'api_key': '$id'}));
    if (response.statusCode == 200){
      List<dynamic> body = cnv.jsonDecode(response.data);
      model = body.map((dynamic item) => UserModel.fromJson(item)).cast<UserModel>().toList();
      setState(() {
        temp = int.parse(model![0].temp.toString());
        loadcell = int.parse(model![0].loadcell.toString());
      });
      if (model![0].data.toString() == '1'){
        while (demcheckdata < 1){
          demcheckdata++;
          var check = await Dio().getUri(Uri.http('192.168.16.2', '/checkconnect', {'api_key': '$id'}));
          if (check.statusCode == 200){
            List<dynamic> body = cnv.jsonDecode(check.data);
            modelconnect = body.map((dynamic item) => CheckConnect.fromJson(item)).cast<CheckConnect>().toList();
            if (modelconnect![0].datastate.toString() == '1'){
              updateHistoryToFireStore();
              sendData('response',{'api_key': '$id',
                'rescode':'2',  //d??? li???u ???? ???????c ghi
              });
            } else
              sendData('response',{'api_key': '$id',
                'rescode':'1',   //d??? li???u ch??a ???????c ghi
              });
          }
        }
      }
    }
  }

  updateHistoryToFireStore() async {
    QuerySnapshot querySnapshot = await machine.doc('history').
      collection('${modelconnect![0].monthstart}').
      doc('${modelconnect![0].monthstart}').
      collection('${modelconnect![0].daystart}').get();
    List<DocumentSnapshot> _myDocCount = querySnapshot.docs;
    int seconds = int.parse(modelconnect![0].runtime.toString()) % 60;
    int minutes = (int.parse(modelconnect![0].runtime.toString()) % (3600)) ~/ 60;
    int hours = int.parse(modelconnect![0].runtime.toString()) ~/ (3600);
    machine.doc('history').
    collection('${modelconnect![0].yearstart}').
    doc('${modelconnect![0].monthstart}').
    collection('${modelconnect![0].daystart}').doc('${_myDocCount.length}').set({
      'date_created': '${modelconnect![0].yearstart}/${modelconnect![0].monthstart}/${modelconnect![0].daystart} ${modelconnect![0].timestart}',
      'room_name': '${modelconnect![0].roomname}',
      'run_time': '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      'status': '${modelconnect![0].errorcode}'
    });
  }

  @override
  void initState() {
    Timer.periodic(Duration(seconds: 3), (Timer t) async {
      getDataHttp();
    });
    _tabController = TabController(length: 5, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double font = MediaQuery.of(context).size.width / 5 * 0.125;
    return WillPopScope(
      onWillPop: () async {
        final timeout = DateTime.now().difference(pre_backpress);
        final cantExit = timeout >= Duration(seconds: 2);
        pre_backpress = DateTime.now();
        if (!cantExit){
          exit(0);
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('B???m l???n n???a ????? tho??t',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Color(0xff898989),
            duration: Duration(seconds: 2),
            shape: StadiumBorder(),
            margin: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            behavior: SnackBarBehavior.floating,
            elevation: 0,
          ));
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xffF8F8FF),
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: AppColors.tertiary,
          centerTitle: false,
          flexibleSpace: Image(
            image: AssetImage('assets/headerdrawer.png'),
            fit: BoxFit.cover,
          ),
          elevation: 2.5,
          title: Text(
            "Mist App",
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 26, color: Colors.white),
          ),
          actions: [
            TextButton(
              child: Icon(
                Icons.qr_code_scanner_sharp,
                size: 30,
                color: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => QRScan()));
              },
            ),
          ],
        ),
        drawer: StreamBuilder(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (ctx, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.none) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            return  UserDrawer();
          },
        ),
        body: Center(
          child: TabBarView(
            controller: _tabController,
            children: [
              SwitchRunNow(),
              SwitchCheck(),
              SwitchHome(),
              SwitchHistory(),
              SwitchSettings(),
            ],
          ),
        ),
        bottomNavigationBar: Container(
            height: 75,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(25),
                    topLeft: Radius.circular(25)),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xffC0C0C0),
                    blurRadius: 13,
                  )
                ]),
            // color: Colors.white,
            child: TabBar(
              isScrollable: false,
              indicatorColor: AppColors.tertiary,
              indicatorWeight: 3,
              controller: _tabController,
              unselectedLabelColor: Color(0xff555555),
              labelColor: AppColors.tertiary,
              tabs: [
                Tab(
                  icon: Icon(Icons.flash_on_sharp, size: 30),
                  child: SizedBox(
                    child: Text('Ch???y nhanh',style: TextStyle(fontSize: font),textAlign: TextAlign.center, overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.drive_eta_outlined, size: 30),
                  child: Center(
                    child: Text('Ki???m tra',style: TextStyle(fontSize: font),textAlign: TextAlign.center, overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.home, size: 30,),
                  child: Center(
                    child: Text('Trang ch???',style: TextStyle(fontSize: font),textAlign: TextAlign.center, overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.fact_check_outlined, size: 30,),
                  child: Center(
                    child: Text('L???ch s???',style: TextStyle(fontSize: font),textAlign: TextAlign.center, overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.settings_outlined, size: 30),
                  child: Center(
                    child: Text('C??i ?????t',style: TextStyle(fontSize: font),textAlign: TextAlign.center, overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
                  ),
                ),
              ],
            )),
      )
    );
  }

  Widget UserDrawer(){
    double font = MediaQuery.of(context).size.width * 0.052;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
              margin: EdgeInsets.only(bottom: 5),
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage('assets/headerdrawer.png'),
                  )
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    (FirebaseAuth.instance.currentUser!.photoURL == null)
                        ? Padding(
                        padding: EdgeInsets.fromLTRB(15,0,15,0),
                        child: Image.asset('assets/add-user.png', width: 70)
                    )
                        : Container(
                      margin: EdgeInsets.fromLTRB(15,0,15,0),
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage('${FirebaseAuth.instance.currentUser!.photoURL}'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${FirebaseAuth.instance.currentUser!.displayName}",
                            style: TextStyle(fontSize: font, fontWeight: FontWeight.w500, color: Colors.white),
                            overflow: TextOverflow.clip, maxLines: 1, softWrap: false),
                        Text("${FirebaseAuth.instance.currentUser!.email}",
                            style: TextStyle(fontSize: font - 6, color: Colors.white),
                            overflow: TextOverflow.clip, maxLines: 1, softWrap: false),
                        SizedBox(height: 2)
                      ],
                    )
                  ],
                ),
              )
          ),
          ListTile(
            leading: Icon(Icons.supervised_user_circle, size: 35),
            title: Text("Trang c?? nh??n",
                style: TextStyle(fontSize: 15)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PersonalPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.vpn_key_rounded, size: 30),
            title: Text("?????i m???t kh???u",
              style: TextStyle(fontSize: 15)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePassword()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.call, size: 30),
            title: Text("H??? tr??? kh??ch h??ng",
              style: TextStyle(fontSize: 15)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, size: 30),
            title: Text("????ng xu???t",
                style: TextStyle(fontSize: 15)),
            onTap: () {
              LogOut();
            },
          ),
        ],
      ),
    );
  }

  void LogOut(){
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context)=> CupertinoAlertDialog(
          title: Text(
              '????ng xu???t',
              style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w500)),
          content: Padding(
            padding: EdgeInsets.fromLTRB(0,7,0,7),
            child: Text(
                'B???n c?? ch???c ch???n mu???n ????ng xu???t t??i kho???n kh??ng?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400)),
          ),
          actions: [
            CupertinoDialogAction(child: TextButton(
              child: Text(
                  'C??',
                  style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w500,color: Colors.red)),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
                SharedPreferences prefs = await SharedPreferences.getInstance();
                Future.delayed(new Duration(milliseconds: 3000), () {
                  FirebaseAuth.instance.signOut();
                  prefs.remove('email');
                });
              },
            )),
            CupertinoDialogAction(child: TextButton(
              child: Text(
                  'Kh??ng',
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
}
