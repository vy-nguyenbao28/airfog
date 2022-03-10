class UserQrCode {
  String? room;
  String? volume;
  int? speed;

  UserQrCode({this.room, this.volume, this.speed});

  UserQrCode.fromJson(Map<String, dynamic> json) {
    room = json['room'];
    volume = json['volume'];
    speed = json['speed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['room'] = this.room;
    data['volume'] = this.volume;
    data['speed'] = this.speed;
    return data;
  }
}