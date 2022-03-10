import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:mist_app/theme/constant.dart';
import '../counttime.dart';
import 'package:connectivity/connectivity.dart';

class SwitchHistory extends StatefulWidget {
  const SwitchHistory({Key? key}) : super(key: key);
  @override
  _SwitchHistory createState() => _SwitchHistory();
}

class _SwitchHistory extends State<SwitchHistory> {
  //Khai báo biến
  int firstyear = 0;
  int firstmonth = 0;
  int firstday = 0;

  int lastyear = 0;
  int lastmonth = 0;
  int lastday = 0;


  bool? _isConnected;
  bool showHistory = false;
  bool checkHistory = false;

  DateTime selectedFirstDate = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -2);
  DateTime selectedLastDate = DateTime.now();

  CollectionReference machine = FirebaseFirestore.instance.collection('tbraa162-notv-hyan-h969-99nk1u6t2017');

  //Các hàm gọi
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
      duration: Duration(seconds: 2),
      shape: StadiumBorder(),
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ));
  }

  _selectDate(BuildContext context, bool select) async {
    final DateTime? picked = await showDatePicker(
      locale: const Locale("vi"),
      context: context,
      initialDate: (select) ? selectedFirstDate : selectedLastDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (select){
      if (picked != null && picked != selectedFirstDate){
        if ((picked.year > lastyear)
            || ((picked.year == lastyear) && (picked.month > lastmonth))
            || ((picked.year == lastyear) && (picked.month == lastmonth) && (picked.day > lastday))){
          notification('Thời gian không hợp lệ');
        }
        if ((picked.year < lastyear)
            || ((picked.year == lastyear) && (picked.month < lastmonth))
            || ((picked.year == lastyear) && (picked.month == lastmonth) && (picked.day < lastday))){
          setState(() {
            firstyear = picked.year;
            firstmonth = picked.month;
            firstday = picked.day;
            selectedFirstDate = DateTime.utc(firstyear, firstmonth, firstday);
          });
          history.clear();
          searchHistory();
        }
      }
    } else {
      if (picked != null && picked != selectedLastDate){
        if ((picked.year < firstyear)
            || ((picked.year == firstyear) && (picked.month < firstmonth))
            || ((picked.year == firstyear) && (picked.month == firstmonth) && (picked.day < firstday))){
          notification('Thời gian không hợp lệ');
        }
        if ((picked.year > firstyear)
            || ((picked.year == firstyear) && (picked.month > firstmonth))
            || ((picked.year == firstyear) && (picked.month == firstmonth) && (picked.day > firstday))){
          setState(() {
            lastyear = picked.year;
            lastmonth = picked.month;
            lastday = picked.day;
            selectedLastDate = DateTime.utc(lastyear, lastmonth, lastday);
          });
          history.clear();
          searchHistory();
        }
      }
    }
  }

  List<History> history= [];

  searchHistory(){
    if (firstyear == lastyear){ //Nếu cùng 1 năm
      if(firstmonth == lastmonth){
        for (int k = lastday; k >= firstday; k--){
          getValueHistory(firstyear, firstmonth, k);
        }
      }
      if (firstmonth < lastmonth){
        for (int j = lastmonth; j >= firstmonth; j--){
          if (j == lastmonth){
            for (int k = lastday; k >= 1; k--){
              getValueHistory(firstyear, j, k);
            }
          }
          if ((j < lastmonth && j > firstmonth) || (j < lastmonth && j != firstmonth)){
            for (int k = DateTime(firstyear, j + 1, 0).day; k >= 1; k--){
              getValueHistory(firstyear, j, k);
            }
          }
          if (j == firstmonth){
            for (int k = firstday; k <= DateTime(firstyear, j + 1, 0).day; k++){
              getValueHistory(firstyear, j, k);
            }
          }
        }
      }
    }
    if (lastyear > firstyear){ // Nếu khác năm
      for (int i = lastyear; i >= firstyear; i--){
        if (i == lastyear){ //quét năm đầu tiên
          for (int j = lastmonth; j >= 1; j--){
            if (j == lastmonth){ //quét tháng lẻ đầu tiên
              for (int k = lastday; k >= 1; k--){
                getValueHistory(i, j, k);
              }
            }
            if ((j < lastmonth && j >= 1)){ //quét các tháng tiếp theo trong năm đầu tiên
              for (int k = DateTime(i, j + 1, 0).day; k >= 1; k--){
                getValueHistory(i, j, k);
              }
            }
          }
        }
        if ((i < lastyear && i > firstyear) || (i < lastyear && i != firstyear)){ //quét trường hợp 2 năm cách nhau ít nhất 1 năm
          for (int j = 12; j >= 1; j--){
            for (int k = DateTime(i, j + 1, 0).day; k >= 1; k--){
              getValueHistory(i, j, k);
            }
          }
        }
        if (i == firstyear && firstmonth == 12){ // quét trường hợp 2 năm sát nhau và tháng quét là tháng 12
          for (int k = DateTime(i, 13, 0).day; k >= firstday; k--){
            getValueHistory(i, 12, k);
          }
        }
        if (i == firstyear && firstmonth != 12){ // quét trường hợp 2 năm sát nhau và tháng quét khác tháng 12
          for (int j = 12; j >= firstmonth; j--){
            if (j <= 12 && j > firstmonth){
              for (int k = DateTime(i, j + 1, 0).day; k >= 1; k--){
                getValueHistory(i, j, k);
              }
            }
            if (j == firstmonth){
              for (int k = DateTime(i, j + 1, 0).day; k >= firstday; k--){
                getValueHistory(i, j, k);
              }
            }
          }
        }
      }
    }
  }

  loadHistoryWhenStart(){
    firstyear = selectedLastDate.year;
    firstmonth = selectedLastDate.month;
    firstday = selectedLastDate.day - 2;

    lastyear = selectedLastDate.year;
    lastmonth = selectedLastDate.month;
    lastday = selectedLastDate.day;
  }

  getValueHistory(int year, int month, int day) async {
    QuerySnapshot querySnapshot = await machine.doc('history').
    collection('$year').doc('$month').collection('$day').get();
    if (querySnapshot.docs.isNotEmpty){
      List<DocumentSnapshot> _myDocCount = querySnapshot.docs;
      print('$year/$month/$day/${_myDocCount.length}');
      history.add(History(year: year, month: month, day: day, sum: _myDocCount.length));
    }
  }

  void initState(){
    loadHistoryWhenStart();
    searchHistory();
    Timer.periodic(Duration(seconds: 2), (Timer t) => setState(() {
      setState(() {
        showHistory = true;
      });
    }));
    super.initState();
  }

  Widget build(BuildContext context) {
    checkConnectivty();
    return Scaffold(
        body: Column(
          children: [
            SizedBox(height: 50),
            Container(
                height: 40,
                margin: EdgeInsets.all(5),
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lighterGray,
                        blurRadius: 10,
                      )
                    ]),
                child:Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SetupCalendar(firstyear, firstmonth, firstday, true),
                    Icon(Icons.wysiwyg),
                    SetupCalendar(lastyear, lastmonth, lastday, false),
                  ],
                ),
            ),
            Container(
              height: 45,
              padding: EdgeInsets.only(right: 15,left: 23),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Gần đây',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),),
                  deleteHistory()
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                print('${history.length}');
              },
              icon: Icon(Icons.send),
            ),
            (showHistory)
                ? (history.length != 0)
                      ? Container(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: history.map((value){
                              return SizedBox(
                                  height: int.parse(value.sum.toString()) * 115,
                                  child:ListView.builder(
                                    padding: EdgeInsets.zero,
                                    scrollDirection: Axis.vertical,
                                    itemCount: value.sum,
                                    itemBuilder: (context, index) => HistoryCard(index, value.year!, value.month!, value.day!, int.parse(value.sum.toString())),
                                  )
                              );
                            }).toList(),
                          ),
                        )
                      : Center(child: Text('Không có lịch sử', style: TextStyle(fontSize: 30), textAlign: TextAlign.center))
                : Center(child: CircularProgressIndicator())
          ],
        )
    );
  }

  Widget HistoryCard(int index, int year, int month, int day, int sum) {
    return Container(
        margin: EdgeInsets.only(right: 10, top: 0, bottom: 10, left: 10),
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.lighterGray,
                blurRadius: 10,
              )
            ]),
        child: Row(
            children: [
              SizedBox(width: 10),
              Image.asset('assets/medical-history.png', width: 47),
              SizedBox(width: 10),
              Container(height: 60, width: 1.5, color: Colors.grey),
              SizedBox(width: 10),
              Column(
                children: [
                  Container(
                    height: 95,
                    width: MediaQuery.of(context).size.width - 120,
                    child: StreamBuilder<DocumentSnapshot>(
                        stream: machine.doc('history').collection('$year').
                                doc('$month').collection('$day').
                                doc('${sum - index - 1}').snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                                child: CircularProgressIndicator());
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text('${snapshot.data!["room_name"]}',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500)),
                              Text('Ngày phun: ${snapshot.data!["date_created"]}',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff696969),),
                                  overflow: TextOverflow.clip, maxLines: 1, softWrap: false
                              ),
                              Text('Thời gian phun: ${snapshot.data!["run_time"]}',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff696969)
                                  )),
                              Text('${snapshot.data!["status"]}',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: (snapshot.data!["status"] == 'Dừng đột ngột')
                                          ? Colors.red
                                          : AppColors.tertiary
                                  )),
                            ],
                          );
                        })
                  )
                ],
              ),
            ]));
  }

  Widget SetupCalendar(int year, int month, int day, bool select){
    return GestureDetector(
      onTap: (){
        _selectDate(context, select);
      },
      child: (select)
          ? Text('Từ ${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      )
          : Text('Đến ${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      )
    );
  }

  Widget deleteHistory(){
    return TextButton.icon(
      icon: Icon(Icons.delete_sharp, color: AppColors.tertiary),
      label: Text('Xóa lịch sử',
        style: TextStyle(fontSize: 13,fontWeight: FontWeight.w400, color: AppColors.tertiary),),
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
                title: Text('Xóa lịch sử',
                    style: TextStyle(
                        fontSize: 23, fontWeight: FontWeight.w500)),
                content: Text(
                    'Bạn có chắc chắn muốn xóa lịch sử không?',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w400)),
                actions: [
                  CupertinoDialogAction(
                      child: TextButton(
                        child: Text('Có',
                            style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w500,
                                color: Colors.red)),
                        onPressed: () {
                          // history.doc('counthistory').get().then((DocumentSnapshot documentSnapshot) {
                          //   for (int i = 0; i<int.parse(documentSnapshot['counthistory'].toString()); i++){
                          //     history.doc('$i').delete();
                          //   }
                          // });
                          // history.doc("counthistory").set({'counthistory': '0'});
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
    );
  }
}

class History{ //modal class for Person object
  int? year, month, day, sum;
  History({required this.year, required this.month, required this.day, required this.sum});
}