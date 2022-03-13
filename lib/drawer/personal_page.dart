import 'dart:async';
import 'dart:io';
import 'dart:convert' as cnv;
import 'package:flutter/material.dart';
import 'package:mist_app/theme/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mist_app/theme/constant.dart';
import 'package:mist_app/theme/namedisplay_and_id.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalPage extends StatefulWidget {
  @override
  _PersonalPage createState() => _PersonalPage();
}

class _PersonalPage extends State<PersonalPage> {
  FirebaseStorage storage = FirebaseStorage.instance;

  String? password;
  String? machinename;

  double heightbox = 40;

  bool Saved = false;
  bool ShowId = false;
  bool CheckError = false;
  bool checkButton = false;
  bool checkPassFaild = false;
  bool _passwordVisible = false;

  final textUserName = TextEditingController();
  final textMachinaName = TextEditingController();
  final textConfirmId = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  CollectionReference machine = FirebaseFirestore.instance.collection('$id');

  uploadImage(String input) async {
    final _storage = FirebaseStorage.instance;
    final _picker = ImagePicker();
    XFile? image;
    //Check Permissions
    await Permission.photos.request();
    var permissionStatus = await Permission.photos.status;
    if (permissionStatus.isGranted){
      //Select Image
      image = (await _picker.pickImage(source: (input == 'gallery')
          ? ImageSource.gallery
          : ImageSource.camera))!;
      var file = File(image.path);
      if (image != ''){
        WaitForChange();
        //Upload to Firebase
        var snapshot = await _storage.ref()
            .child('${FirebaseAuth.instance.currentUser!.email}/${FirebaseAuth.instance.currentUser!.displayName}')
            .putFile(file);
        var downloadUrl = await snapshot.ref.getDownloadURL();
        FirebaseAuth.instance.currentUser!.updatePhotoURL('$downloadUrl');
        Navigator.of(context).pop();
      }
    }
  }

  getMachineName(){
    CollectionReference machine = FirebaseFirestore.instance.collection('$id');
    machine.doc('machinename').get().then((DocumentSnapshot documentSnapshot) {
      setState(() {
        machinename = documentSnapshot['machinename'].toString();
      });
    });
  }

  getPassword(){
    CollectionReference user = FirebaseFirestore.instance.collection('user');
    user.doc('${FirebaseAuth.instance.currentUser!.email}').get().then((DocumentSnapshot documentSnapshot) {
      setState(() {
        password = documentSnapshot['password'].toString();
      });
    });
  }

  @override
  void initState() {
    getMachineName();
    getPassword();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (ctx, futureSnapshot) {
          if (futureSnapshot.connectionState == ConnectionState.none) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            children: [
              Cover(),
              Padding(
                padding: EdgeInsets.fromLTRB(0,15,0,15),
                child: Center(
                  child: Text('Thông tin trang cá nhân',
                    style: TextStyle(fontSize: 25),
                    textAlign: TextAlign.center,),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(15,0,15,0),
                height: 250,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DisplayName(),
                    Container(height: 1, color: Colors.grey),
                    Email(),
                    Container(height: 1, color: Colors.grey),
                    MachineName(),
                    Container(height: 1, color: Colors.grey),
                    MachineCode(),
                    Container(height: 1, color: Colors.grey),
                  ],
                ),
              )
            ],
          );
        },
      ),
      bottomNavigationBar: ChangeProfile(),
    );
  }

  Widget Cover(){
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.width * 0.5,
          width: MediaQuery.of(context).size.width,
          child: Container(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: AssetImage('assets/headerdrawer.png'),
                )
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 10, left: 5),
          child: ElevatedButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: Icon(Icons.arrow_back, color: AppColors.tertiary, size: 27,),
            style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                elevation: 2,
                primary: Colors.white),
          ),
        ),
        SizedBox(
            height: MediaQuery.of(context).size.width * 0.5,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: (){
                      ChangeImage();
                    },
                    child: (FirebaseAuth.instance.currentUser!.photoURL == null)
                        ? Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                width: 3,
                                color: Colors.white
                            )
                        ),
                        child: Image.asset('assets/add-user.png', width: MediaQuery.of(context).size.width * 0.35,)
                    )
                        : Container(
                      width: MediaQuery.of(context).size.width * 0.35,
                      height: MediaQuery.of(context).size.width * 0.35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            width: 3,
                            color: Colors.white
                        ),
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage('${FirebaseAuth.instance.currentUser!.photoURL}'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
        )
      ],
    );
  }

  Widget DisplayName(){
    double font = MediaQuery.of(context).size.width * 0.039;
    double sizewith = MediaQuery.of(context).size.width;
    return Container(
      height: heightbox,
      child: Row(
        children: [
          Container(
            width: sizewith * 0.37 - 15,
            child: Text("Tên người dùng",
                style: TextStyle(color: Colors.grey, fontSize: font),
                overflow: TextOverflow.clip, maxLines: 1, softWrap: false),
          ),
          Container(
            width: sizewith * 0.63 - 15,
            child: (Saved)
                ? SizedBox(height: font + 3, child: ChangeUserName())
                : Text("${FirebaseAuth.instance.currentUser!.displayName}",
                style: TextStyle(fontSize: font),
                overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
          ),
        ],
      ),
    );
  }

  Widget Email(){
    double font = MediaQuery.of(context).size.width * 0.039;
    double sizewith = MediaQuery.of(context).size.width;
    return Container(
      height: heightbox,
      child: Row(
        children: [
          Container(
            width: sizewith * 0.37 - 15,
            child: Text("Email đăng ký",
                style: TextStyle(color: Colors.grey, fontSize: font),
                overflow: TextOverflow.clip, maxLines: 1, softWrap: false),
          ),
          Container(
            width: sizewith * 0.63 - 15,
            child: Text("${FirebaseAuth.instance.currentUser!.email}",
                style: TextStyle(fontSize: font),
                overflow: TextOverflow.visible, maxLines: 1, softWrap: false),
          ),
        ],
      ),
    );
  }

  Widget MachineName(){
    double font = MediaQuery.of(context).size.width * 0.039;
    double sizewith = MediaQuery.of(context).size.width;
    return Container(
      height: heightbox,
      child: Row(
        children: [
          Container(
            width: sizewith * 0.37 - 15,
            child: Text("Tên máy",
                style: TextStyle(color: Colors.grey, fontSize: font),
                overflow: TextOverflow.clip, maxLines: 1, softWrap: false),
          ),
          Container(
            width: sizewith * 0.63 - 15,
            child: (Saved)
                ? SizedBox(height: font + 3, child: ChangeMachineName())
                : Text("${machinename}", style: TextStyle(fontSize: font),
              overflow: TextOverflow.fade, maxLines: 1, softWrap: false))
        ],
      ),
    );
  }

  Widget MachineCode(){
    double font = MediaQuery.of(context).size.width * 0.039;
    double sizewith = MediaQuery.of(context).size.width;
    return Container(
      height: heightbox,
      child: Row(
        children: [
          Container(
            width: sizewith * 0.37 - 15,
            child: Text("Mã đăng ký",
                style: TextStyle(color: Colors.grey, fontSize: font),
                overflow: TextOverflow.clip, maxLines: 1, softWrap: false),
          ),
          Container(
            width: sizewith * 0.63 - 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                (!ShowId)
                    ? Text("****************", style: TextStyle(fontSize: font))
                    : SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6-56,
                  child: Text("${id}", overflow: TextOverflow.fade, maxLines: 1, softWrap: false, style: TextStyle(fontSize: font)),
                ),
                SizedBox(
                  height: 17,
                  child: IconButton(
                    padding: new EdgeInsets.all(0.0),
                    splashRadius: 17,
                    icon: Icon(
                      ShowId
                          ? Icons.copy
                          : Icons.visibility_off,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      if (!ShowId){
                        ShowCode();
                      }
                      if (ShowId){
                        FlutterClipboard.copy(id.toString()).then((value) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Đã copy mã đăng ký',
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
                        });
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void ShowCode(){
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.only(left: 10, right: 10),
            titlePadding: const EdgeInsets.fromLTRB(0, 15, 0, 10),
            title: Center(child: Text('Xác minh người dùng'),),
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Form(
                          key: _formKey,
                          child: EnterPass()),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(),
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: IconButton(
                              splashRadius: 17,
                              onPressed: (){
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                                (context as Element).markNeedsBuild();
                              },
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RawMaterialButton(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          elevation: 2.0,
                          fillColor: AppColors.tertiary,
                          onPressed: () {
                            setState(() {
                              checkButton = true;
                            });
                            if (textConfirmId.text != password){
                              setState(() {
                                checkPassFaild = true;
                              });
                              Timer.periodic(Duration(seconds: 2), (timer) {
                                setState(() {
                                  checkPassFaild = false;
                                });
                              });
                            } else {
                              setState(() {
                                checkPassFaild = false;
                              });
                            }
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              setState(() {
                                ShowId = true;
                              });
                            }
                            setState(() {
                              (context as Element).markNeedsBuild();
                            });
                          },
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(15,5,15,5),
                              child: Text('Xác nhận',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white)))
                      ),
                      RawMaterialButton(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(color: AppColors.tertiary),
                              borderRadius: BorderRadius.circular(5)),
                          elevation: 2.0,
                          fillColor: Colors.white,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(24,5,24,5),
                              child: Text('Hủy bỏ',
                                  style: TextStyle(
                                      fontSize: 18, color: AppColors.tertiary)))
                      )
                    ],
                  ),
                  SizedBox(height: 10)
                ],
              )
            ],
          );
        });
  }

  Widget EnterPass(){
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val){
        if (checkButton){
          if(checkPassFaild){
            return "* Mật khẩu không hợp lệ";
          }
          if(val!.isEmpty){
            return "* Nhập mật khẩu";
          }
          if(val.length < 6){
            return "* Mật khẩu ít nhất cần 6 ký tự";
          }
        }
        return null;
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(fontSize: 17),
        hintText: 'Nhập mật khẩu',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(width: 1,color: Colors.red)
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 10),
              Image.asset('assets/pass.png',width: 30),
              SizedBox(width: 10),
              Container(
                height: 28,
                width: 1,
                color: Colors.black,
              )
            ],
          ),
        ),

      ),
      style: TextStyle(fontSize: 17, height: 1.2,
      ),
      obscureText: !_passwordVisible,
      textAlign: TextAlign.left,
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      controller: textConfirmId,
      cursorColor: Colors.black,
    );
  }

  Widget ChangeProfile(){
    return Container(
        padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width*0.13, 0,
            MediaQuery.of(context).size.width*0.13, 10),
      child: OutlinedButton(
        onPressed: () {
          if (Saved && (textUserName.text == '' ||  textMachinaName.text == '')){
            setState(() {
              CheckError = true;
            });
            DispplayError('Không nhập đủ thông tin');
          } else if (Saved && textUserName.text != '' && textMachinaName.text != ''){
            setState(() {
              CheckError = false;
            });
          }
          if (!CheckError){
            setState(() {
              Saved = !Saved;
            });
            if (!Saved){
              FirebaseAuth.instance.currentUser!.updateDisplayName(
                  '${textUserName.text}');
              machine.doc('machinename').set({
                'machinename': textMachinaName.text,
              });
              getMachineName();
            }
            if (Saved){
              textUserName.text = FirebaseAuth.instance.currentUser!.displayName.toString();
              textMachinaName.text = machinename!;
            }
          }
        },
        child: Container(
            height: 40,
            child: (!Saved)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/editprofile.png', width: 21, color: AppColors.tertiary),
                      SizedBox(width: 10),
                      Text('Chỉnh sửa trang cá nhân',
                          style: TextStyle(fontSize: 17, color:  AppColors.tertiary)),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/saveinfo.png', width: 19, color: AppColors.tertiary),
                      SizedBox(width: 10),
                      Text('Cập nhật thông tin',
                          style: TextStyle(fontSize: 17, color:  AppColors.tertiary)),
                    ],
                  )
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          primary: AppColors.tertiary, // foreground text
          side: BorderSide(color: AppColors.tertiary), // foreground border
        ),
      )
    );
  }

  void ChangeImage(){
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => SimpleDialog(
          contentPadding: EdgeInsets.only(left: 6, right: 6),
          titlePadding: EdgeInsets.fromLTRB(0, 25, 0, 25),
          title: Center(
            child: Text('Thay đổi ảnh đại diện'),
          ),
          children: <Widget>[
            Container(height: 1, color: Colors.grey),
            ListTile(
              title: Center(
                child: Text('Xem ảnh',
                  style: TextStyle(color: Colors.blue, fontSize: 16),),
              ),
              onTap: (){
                if (FirebaseAuth.instance.currentUser!.photoURL != null){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (contex) =>
                        Image.network('${FirebaseAuth.instance.currentUser!.photoURL}'),
                    ),
                  );
                }
              },
            ),
            Container(height: 1, color: Colors.grey),
            ListTile(
              title: Center(
                child: Text('Tải ảnh lên',
                  style: TextStyle(color: Colors.blue, fontSize: 16),),
              ),
              onTap: (){
                Navigator.of(context).pop();
                uploadImage('gallery');
              },
            ),
            Container(height: 1, color: Colors.grey),
            // ListTile(
            //   title: Center(
            //     child: Text('Chụp ảnh lên',
            //       style: TextStyle(color: Colors.blue, fontSize: 16),),
            //   ),
            //   onTap: (){
            //     WaitForChange();
            //     uploadImage('camera');
            //   },
            // ),
            //Container(height: 1, color: Colors.grey),
            ListTile(
              title: Center(
                child: Text('Gỡ ảnh hiện tại',
                  style: TextStyle(color: Color(0xffFF0033), fontSize: 16),),
              ),
              onTap: (){
                if (FirebaseAuth.instance.currentUser!.photoURL != null){
                  Navigator.of(context).pop();
                  FirebaseStorage.instance.ref().
                  child('${FirebaseAuth.instance.currentUser!.email}/${FirebaseAuth.instance.currentUser!.displayName}').delete();
                  FirebaseAuth.instance.currentUser!.updatePhotoURL(null);
                }
              },
            ),
            Container(height: 1, color: Colors.grey),
            ListTile(
              title: Center(
                child: Text('Hủy',
                  style: TextStyle(color: Colors.black, fontSize: 16),),
              ),
              onTap: (){
                Navigator.of(context).pop();
              },
            ),
          ],
        ));
  }

  void WaitForChange(){
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
            child: new Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  new CircularProgressIndicator(),
                  SizedBox(height: 20),
                  new Text("Đang tải ảnh lên..."),
                ],
              ),
            )
        );
      },
    );
  }

  void DispplayError(String input){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(input,
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

  Widget ChangeUserName() {
    double font = MediaQuery.of(context).size.width * 0.039;
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        isDense: true,
        fillColor: Colors.white,
        border: InputBorder.none,
        // hintStyle: TextStyle(fontSize: 17,
        //     color: AppColors.tertiary),
        // hintText: 'Tên người dùng',
        contentPadding: EdgeInsets.fromLTRB(0,0,0,0),
      ),
      style: TextStyle(fontSize: font, height: 1.2, color: AppColors.tertiary),
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.send,
      controller: textUserName,
      cursorColor: AppColors.tertiary,
      autofocus: false,
    );
  }

  Widget ChangeMachineName() {
    double font = MediaQuery.of(context).size.width * 0.039;
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        isDense: true,
        fillColor: Colors.white,
        border: InputBorder.none,
        contentPadding: EdgeInsets.fromLTRB(0,0,0,0),
      ),
      style: TextStyle(fontSize: font, height: 1.2, color: AppColors.tertiary),
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.send,
      controller: textMachinaName,
      cursorColor: AppColors.tertiary,
      autofocus: false,

    );
  }

}