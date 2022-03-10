import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mist_app/qr_code/qr_code_picture.dart';
import 'package:mist_app/theme/colors.dart';
import 'json_qr_code.dart';


class CreateQrCode extends StatefulWidget {
  const CreateQrCode({Key? key}) : super(key: key);
  @override
  _CreateQrCode createState() => _CreateQrCode();
}

class _CreateQrCode extends State<CreateQrCode>{
  //TextController
  final textRoom = TextEditingController();
  final textVolume = TextEditingController();
  double speed = 0;

  //ErrorText
  String? get _errorTextRoom {
    final text = textRoom.value.text;
    if (text.isEmpty) {
      return '*Bắt buộc';
    }
    return null;
  }
  String? get _errorTextVolume {
    final text = textVolume.value.text;
    if (text.isEmpty) {
      return '*Bắt buộc';
    }
    if (text.length == 1) {
      return 'Thể tích quá nhỏ';
    }
    return null;
  }

  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.fromLTRB(5,0,5,0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoomName(),
            Volume(),
            Text("Nồng độ: ${speed.toInt().toString().padLeft(2, '0')} ml/m\u00B3",
                style: TextStyle(fontSize: 18)),
            Speed(),
            CreateButton()
          ],
        )
    );
  }

  Widget RoomName(){
    return ValueListenableBuilder(
      valueListenable: textRoom,
      builder: (context, TextEditingValue value, __) {
        return TextFormField(
          decoration: InputDecoration(
            icon: Icon(
              Icons.drive_file_rename_outline_outlined,
              color: Colors.blue,
              size: 25,
            ),
            labelText: 'Tên phòng',
            focusColor: Colors.black,
            errorText: _errorTextRoom,
          ),
          textInputAction: TextInputAction.send,
          maxLength: 100,
          textCapitalization: TextCapitalization.words,
          controller: textRoom,
          cursorColor: Colors.blueGrey,
        );
      },
    );
  }

  Widget Volume(){
    return ValueListenableBuilder(
      valueListenable: textVolume,
      builder: (context, TextEditingValue value, __) {
        return TextFormField(
          decoration: InputDecoration(
            icon: Icon(
              Icons.home_work_outlined,
              color: Colors.blue,
              size: 25,
            ),
            labelText: 'Thể tích (m\u00B3)',
            focusColor: Colors.black,
            errorText: _errorTextVolume,
          ),
          textInputAction: TextInputAction.send,
          maxLength: 3,
          controller: textVolume,
          keyboardType: TextInputType.number,
          cursorColor: Colors.blueGrey,
        );
      },
    );
  }

  Widget Speed(){
    return SliderTheme(
        data: SliderThemeData(trackHeight: 7),
        child: Slider(
          value: speed,
          min: 0,
          max: 16,
          divisions: 16,
          label: speed.round().toString(),
          onChanged: (double Value) {
            setState(() {
              speed = Value;
              (context as Element).markNeedsBuild();
            });
          },
          activeColor: Colors.blue,
          inactiveColor: Color(0xffC0C0C0),
        ));
  }

  Widget CreateButton(){
    return Padding(
        padding: EdgeInsets.fromLTRB(10,0,10,15),
        child: ElevatedButton(
          onPressed: () {
            if (textRoom.text == '' ||
                textVolume.text.length <=1 ||
                speed == 0 ){
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Chưa nhập đủ thông tin',
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
            if (textRoom.text != '' &&
                textVolume.text.length >1 &&
                speed != 0 ){
              String objText  = '{"room": "${textRoom.text}", '
                  '"volume": "${textVolume.text}", '
                  '"speed": ${speed.toInt()}}';
              String qrData = objText;
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>
                    QrPicture(room: '${textRoom.text}', qrCode: '${qrData}')),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(0,10,0,10),
            child: Center(
              child: Text('Khởi tạo', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ),
          style: ElevatedButton.styleFrom(elevation: 3, primary: AppColors.tertiary),
        )
    );
  }
}