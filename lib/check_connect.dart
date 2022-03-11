class CheckConnect {
  String? datastate;
  String? timestart;
  String? daystart;
  String? monthstart;
  String? yearstart;
  String? errorcode;
  String? runtime;
  String? roomname;

  CheckConnect(
      {this.datastate,
        this.timestart,
        this.daystart,
        this.monthstart,
        this.yearstart,
        this.errorcode,
        this.runtime,
        this.roomname});

  CheckConnect.fromJson(Map<String, dynamic> json) {
    datastate = json['datastate'];
    timestart = json['timestart'];
    daystart = json['daystart'];
    monthstart = json['monthstart'];
    yearstart = json['yearstart'];
    errorcode = json['errorcode'];
    runtime = json['runtime'];
    roomname = json['roomname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['datastate'] = this.datastate;
    data['timestart'] = this.timestart;
    data['daystart'] = this.daystart;
    data['monthstart'] = this.monthstart;
    data['yearstart'] = this.yearstart;
    data['errorcode'] = this.errorcode;
    data['runtime'] = this.runtime;
    data['roomname'] = this.roomname;
    return data;
  }
}
