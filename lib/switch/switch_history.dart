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
import 'package:collection/collection.dart';

class SwitchHistory extends StatefulWidget {
  const SwitchHistory({Key? key}) : super(key: key);
  @override
  _SwitchHistory createState() => _SwitchHistory();
}

class _SwitchHistory extends State<SwitchHistory> {
  //Khai báo biến



  bool? _isConnected;
  bool showHistory = false;
  bool checkHistory = false;


  CollectionReference machine = FirebaseFirestore.instance.collection('$id');

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
            || ((picked.year == lastyear) && (picked.month == lastmonth) && (picked.day <= lastday))){
          setState(() {
            showHistory = false;
            firstyear = picked.year;
            firstmonth = picked.month;
            firstday = picked.day;
            selectedFirstDate = DateTime.utc(firstyear, firstmonth, firstday);
          });
          history.clear();
          searchHistory();
          Timer.periodic(Duration(seconds: 2), (Timer t) => setState(() {
            setState(() {
              showHistory = true;
            });
          }));
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
            || ((picked.year == firstyear) && (picked.month == firstmonth) && (picked.day >= firstday))){
          setState(() {
            showHistory = false;
            lastyear = picked.year;
            lastmonth = picked.month;
            lastday = picked.day;
            selectedLastDate = DateTime.utc(lastyear, lastmonth, lastday);
          });
          history.clear();
          searchHistory();
          Timer.periodic(Duration(microseconds: 1500), (Timer t) => setState(() {
            setState(() {
              showHistory = true;
            });
          }));
        }
      }
    }
  }

  String Status(String input){
    String output = 'Hoàn thành';
    if (input == '2'){
      output = 'Dừng đột ngột';
    }
    if (input == '3'){
      output = 'Quá nhiệt động cơ';
    }
    if (input == '4'){
      output = 'Hết dung dịch';
    }
    return output;
  }

  searchHistory(){
    history.clear();
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

  sortHistory(){
    for (int i = 0; i <= history.length - 2; i++){
      for (int j = i + 1; j <= history.length - 1; j++){
        if (history[i].year! < history[j].year!){
          swapItem(i,j);
        }
        if (history[i].year! == history[j].year!){
          if (history[i].month! < history[j].month!){
            swapItem(i,j);
          }
          if (history[i].month! == history[j].month!){
            if (history[i].day! < history[j].day!){
              swapItem(i,j);
            }
          }
        }
      }
    }
  }

  swapItem(int i, int j){
    List a = [0,1,2,3];
    a[0] = history[i].year;
    a[1] = history[i].month;
    a[2] = history[i].day;
    a[3] = history[i].sum;

    history[i].year = history[j].year;
    history[i].month = history[j].month;
    history[i].day = history[j].day;
    history[i].sum = history[j].sum;

    history[j].year = a[0];
    history[j].month = a[1];
    history[j].day = a[2];
    history[j].sum = a[3];

  }

  getValueHistory(int year, int month, int day) async {
    QuerySnapshot querySnapshot = await machine.doc('history').
    collection('$year').doc('$month').collection('$day').get();
    if (querySnapshot.docs.isNotEmpty){
      List<DocumentSnapshot> _myDocCount = querySnapshot.docs;
      history.add(History(year: year, month: month, day: day, sum: _myDocCount.length));
      sortHistory();
    }
  }

  Future<Null> refeshApp() async{
    await Future.delayed(Duration(milliseconds: 500));
    history.clear();
    searchHistory();
  }

  void initState(){
    Timer.periodic(Duration(seconds: 2), (Timer t) => setState(() {
      setState(() {
        showHistory = true;
      });
    }));
    if (!viewedHistory){
      searchHistory();
      setState(() {
        viewedHistory = true;
      });
    }
    super.initState();
  }

  Widget build(BuildContext context) {
    checkConnectivty();
    return Scaffold(
        body: RefreshIndicator(
          child: Column(
            children: [
              Container(
                height: 40,
                margin: EdgeInsets.only(top: 5),
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lighterGray,
                        blurRadius: 10,
                      )
                    ]),
                child: Row(
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
                height: 40,
                padding: EdgeInsets.only(right: 15,left: 23),
                margin: EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Gần đây',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),),
                    SortHistory() // comment
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 250,
                child: ListView(
                  children: [
                    (showHistory)
                        ? (history.length != 0)
                            ? Column(
                                children: history.map((value){
                                    return SizedBox(
                                        height: int.parse(value.sum.toString()) * 118,
                                        child: ListView.builder(
                                          physics: NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                          scrollDirection: Axis.vertical,
                                          itemCount: value.sum,
                                          itemBuilder: (context, index) =>
                                              HistoryCard(index, value.year!, value.month!, value.day!, int.parse(value.sum.toString())),
                                        )
                                    );
                                }).toList(),
                              )
                            : Center(child: Text('Không có lịch sử', style: TextStyle(fontSize: 30), textAlign: TextAlign.center))
                        : SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  ],
                ),
              )
            ],
          ),
          onRefresh: refeshApp,
        )

    );
  }

  Widget HistoryCard(int index, int year, int month, int day, int sum) {
    return Container(
      height: 108,
        margin: EdgeInsets.only(right: 10, top: 0, bottom: 10, left: 10),
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            border: Border.all(
              color: AppColors.primary,
              width: 1.5, //                   <--- border width here
            ),
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
                                        fontFamily: (snapshot.data!["room_name"] == 'Chạy nhanh') ? 'Poppins' : '',
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
                                Text('${Status(snapshot.data!["status"])}',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: (snapshot.data!["status"] == '1')
                                            ? AppColors.tertiary
                                            : Colors.red
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

  Widget SortHistory(){
    return TextButton.icon(
      icon: Icon(Icons.history, color: AppColors.tertiary),
      label: Text('Đồng bộ',
        style: TextStyle(fontSize: 13,fontWeight: FontWeight.w400, color: AppColors.tertiary),),
      onPressed: () {
        if (_isConnected == false){
          notification('Không có kết nối Internet !!!');
        }
        else if (_isConnected == true){
          final inputs = ['a', 'b', 'c', 'd', 'e', 'f'];
          final indexes = inputs.mapIndexed((index, element) => index).toList();

          inputs.forEachIndexed((index, element) {
            print('index: $index, element: $element');
          });
          print(indexes);
        }
      },
    );
  }
}