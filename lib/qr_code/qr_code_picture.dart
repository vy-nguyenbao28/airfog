import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:share/share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class QrPicture extends StatefulWidget {
  QrPicture({required this.room, required this.qrCode}) ;
  final String room;
  final String qrCode;
  @override
  _QrPicture createState() => _QrPicture();
}

class _QrPicture extends State<QrPicture> {
  final GlobalKey _key = GlobalKey();

  void _takeScreenshot() async {
    RenderRepaintBoundary boundary =
    _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      Uint8List pngBytes = byteData.buffer.asUint8List();
      // Saving the screenshot to the gallery
      final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(pngBytes),
          quality: 100,
          name: '${widget.room} - (${DateTime.now()})');
      print(result);
      if (Permission.storage.status.isDenied == false){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Vui lòng cấp quyền truy cập bộ nhớ',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Color(0xff898989),
          duration: Duration(seconds: 5),
          shape: StadiumBorder(),
          margin: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lưu tại: storage/0/emulated/Pictures/${widget.room} - (${DateTime.now()}).jpg',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Color(0xff898989),
          duration: Duration(seconds: 5),
          shape: StadiumBorder(),
          margin: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ));
      }
    }
  }
  Future<void> _captureSocialPng() {
    List<String> imagePaths = [];
    final RenderBox box = context.findRenderObject() as RenderBox;
    return new Future.delayed(const Duration(milliseconds: 20), () async {
      RenderRepaintBoundary? boundary = _key.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      final directory = (await getApplicationDocumentsDirectory()).path;
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      File imgFile = new File('$directory/${widget.room} - (${DateTime.now()}.png');
      imagePaths.add(imgFile.path);
      imgFile.writeAsBytes(pngBytes).then((value) async {
        await Share.shareFiles(imagePaths,
            text: 'Mã QR phòng ${widget.room}',
            sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
      }).catchError((onError) {
        print(onError);
      });
    });
  }

  _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();
    final info = statuses[Permission.storage].toString();
    print(info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        flexibleSpace: Image(
          image: AssetImage('assets/headerdrawer.png'),
          fit: BoxFit.cover,
        ),
        centerTitle: false,
        title: Text(
          "Mục hình ảnh",
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 26,
              color: Colors.white),
        ),
      ),
      body: Padding(
          padding: EdgeInsets.all(20),
          child: ListView(
            children: [
              RepaintBoundary(
                key: _key,
                child:Container(
                  color: Colors.white,
                  width: MediaQuery.of(context).size.width,
                  child: QrImage(
                    errorStateBuilder: (context, error) =>
                        Text(error.toString()),
                    data: widget.qrCode,
                  ),
                ),
              ),
            ],
          )
      ),
      bottomNavigationBar: Container(
        height: 80,
        padding: EdgeInsets.only(bottom: 10),
        child:  SaveAndShare(context),
      ),
    );
  }
  Widget SaveAndShare(BuildContext context){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        SizedBox(
          width: 135,
          height: 46,
          child: ElevatedButton(
            onPressed: () {
              _requestPermission();
              _takeScreenshot();
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(0,10,0,10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.save),
                  Text('Lưu ảnh', style: TextStyle(fontSize: 18, color: Colors.white)),
                ]
              ),
            ),
            style: ElevatedButton.styleFrom(elevation: 3, primary: AppColors.tertiary),
          ),
        ),
        SizedBox(
          width: 135,
          height: 46,
          child: ElevatedButton(
            onPressed: () async {
              _captureSocialPng();
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(0,10,0,10),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.share),
                    Text('Chia sẻ', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ]
              ),
            ),
            style: ElevatedButton.styleFrom(elevation: 3, primary: AppColors.tertiary),
          ),
        ),
      ],
    );
  }
}