import 'dart:async';
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
  //TabBar
  late TabController _tabController;

  List<CheckConnect>? modelconnect;
  Timer? timerLoadData;

  CollectionReference machine = FirebaseFirestore.instance.collection('$id');

  void sendData(String mode, final dataSend)async  {
    Dio().getUri(Uri.http('192.168.16.2','/$mode',dataSend));
  }

  void getDataHttp() async {
    var response = await Dio().getUri(Uri.http('192.168.16.2', '/getweighttemp', {'api_key': '$id'}));
    //var response = await Dio().getUri(Uri.http('61add905d228a9001703afe3.mockapi.io', '/api/vyii'));
    if (response.statusCode == 200){
      List<dynamic> body = cnv.jsonDecode(response.data);
      model = body.map((dynamic item) => UserModel.fromJson(item)).cast<UserModel>().toList();
      setState(() {
        temp = int.parse(model![0].temp.toString());
        loadcell = int.parse(model![0].loadcell.toString());
      });
      if (model![0].data.toString() == '1'){
        var check = await Dio().getUri(Uri.http('192.168.16.2', '/checkconnect', {'api_key': '$id'}));
        if (check.statusCode == 200){
          List<dynamic> body = cnv.jsonDecode(check.data);
          modelconnect = body.map((dynamic item) => CheckConnect.fromJson(item)).cast<CheckConnect>().toList();
          if (modelconnect![0].datastate.toString() == '1'){
            sendData('response',{'api_key': '$id',
              'rescode':'2',  //dữ liệu đã được ghi
            });
          } else
            sendData('response',{'api_key': '$id',
              'rescode':'1',   //dữ liệu chưa được ghi
            });
        }
      }
    } else print('chưa có');
  }

  updateHistoryToFireStore() async {
    QuerySnapshot querySnapshot = await machine.doc('history').
      collection('${modelconnect![0].monthstart}').
      doc('${modelconnect![0].monthstart}').
      collection('${modelconnect![0].daystart}').get();
    List<DocumentSnapshot> _myDocCount = querySnapshot.docs;
    print('${_myDocCount.length}');
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
    timerLoadData = Timer.periodic(Duration(seconds: 3), (Timer t) async {
      getDataHttp();
    });
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  CollectionReference login = FirebaseFirestore.instance.collection('login');
  @override
  Widget build(BuildContext context) {
    double font = MediaQuery.of(context).size.width / 5 * 0.125;
    return Scaffold(
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
              onPressed: () async{
                getDataHttp();
                print('$temp');
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (BuildContext context) => QRScan()));
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
                    child: Text('Chạy nhanh',style: TextStyle(fontSize: font),textAlign: TextAlign.center, overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.drive_eta_outlined, size: 30),
                  child: Center(
                    child: Text('Kiểm tra',style: TextStyle(fontSize: font),textAlign: TextAlign.center, overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.home, size: 30,),
                  child: Center(
                    child: Text('Trang chủ',style: TextStyle(fontSize: font),textAlign: TextAlign.center, overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.fact_check_outlined, size: 30,),
                  child: Center(
                    child: Text('Lịch sử',style: TextStyle(fontSize: font),textAlign: TextAlign.center, overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.settings_outlined, size: 30),
                  child: Center(
                    child: Text('Cài đặt',style: TextStyle(fontSize: font),textAlign: TextAlign.center, overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
                  ),
                ),
              ],
            )),
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
                            style: TextStyle(fontSize: font, fontWeight: FontWeight.w500, color: Colors.white)),
                        Text("${FirebaseAuth.instance.currentUser!.email}",
                            style: TextStyle(fontSize: font - 6, color: Colors.white)),
                        SizedBox(height: 2)
                      ],
                    )
                  ],
                ),
              )
          ),
          ListTile(
            leading: Icon(Icons.supervised_user_circle, size: 35),
            title: Text("Trang cá nhân",
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
            title: Text("Đổi mật khẩu",
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
            title: Text("Hỗ trợ khách hàng",
              style: TextStyle(fontSize: 15)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, size: 30),
            title: Text("Đăng xuất",
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
              'Đăng xuất',
              style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w500)),
          content: Padding(
            padding: EdgeInsets.fromLTRB(0,7,0,7),
            child: Text(
                'Bạn có chắc chắn muốn đăng xuất tài khoản không?',
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
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.remove('email');
                FirebaseAuth.instance.signOut();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
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
}
