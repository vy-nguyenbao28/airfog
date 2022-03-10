class UserModel {
  String? loadcell;
  String? temp;
  String? data;

  UserModel({this.loadcell, this.temp, this.data});

  UserModel.fromJson(Map<String, dynamic> json) {
    loadcell = json['loadcell'];
    temp = json['temp'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['loadcell'] = this.loadcell;
    data['temp'] = this.temp;
    data['data'] = this.data;
    return data;
  }
}
