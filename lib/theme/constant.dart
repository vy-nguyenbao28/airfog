import 'package:mist_app/network_request/user_model.dart';

int timePhun = 0;
String Roomname = '';

String id = '';

int temp = 26;
int loadcell = 3000;

List<History> history= [];
List<UserModel>? model;

bool viewedHistory = false;

int firstyear = selectedLastDate.year;
int firstmonth = selectedLastDate.month;
int firstday = selectedLastDate.day - 2;

int lastyear = selectedLastDate.year;
int lastmonth = selectedLastDate.month;
int lastday = selectedLastDate.day;

DateTime selectedFirstDate = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -2);
DateTime selectedLastDate = DateTime.now();

class History{ //modal class for Person object
  int? year, month, day, sum;
  History({required this.year, required this.month, required this.day, required this.sum});
}



