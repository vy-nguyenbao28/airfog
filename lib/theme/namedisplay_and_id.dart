class UserId {
  String? id;
  String? photourl;

  UserId({this.id, this.photourl});

  UserId.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    photourl = json['photourl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['photourl'] = this.photourl;
    return data;
  }
}
