import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class NIDFrontBackCapture extends StatefulWidget {

  @override
  _NIDFrontBackCaptureState createState() => _NIDFrontBackCaptureState();
}

class _NIDFrontBackCaptureState extends State<NIDFrontBackCapture> {
  File nidBackImage;
  BarcodeScanner _barcodeDetector = GoogleMlKit.vision.barcodeScanner();
  List<Barcode> barcodes;
  var barcodeString;

  var textString;
  RecognisedText _recognisedText;
  TextDetector _textDetector = GoogleMlKit.vision.textDetector();
  File nidFrontImage;

  var nidAllData;
  var eKycId;
  bool _isInternet = false;

  // check internet
  Future<bool> connectivityChecker() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final result2 = await InternetAddress.lookup('facebook.com');
      final result3 = await InternetAddress.lookup('microsoft.com');
      if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) ||
          (result2.isNotEmpty && result2[0].rawAddress.isNotEmpty) ||
          (result3.isNotEmpty && result3[0].rawAddress.isNotEmpty)) {
        setState(() {
          _isInternet = true;
        });
      } else {
        showInternet();
        setState(() {
          _isInternet = false;
        });
      }
    } on SocketException catch (_) {
      showInternet();
      setState(() {
        _isInternet = false;
      });
    }
    return _isInternet;
  }

  //internet response dialog
  showInternet() {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text(
              'Please check your internet connection and try again!',
              style: TextStyle(fontSize: 18),
            ),
            children: <Widget>[
              Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 10),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        });
  }

  // text scanner
  Future<void> textRecognition() async {
    PickedFile image = Platform.isIOS
        ? await ImagePicker().getImage(
            source: ImageSource.camera,
            imageQuality: 100
          )
        : await ImagePicker().getImage(source: ImageSource.camera);
    if (image != null) {
      File croppedTextImage = await ImageCropper.cropImage(
        sourcePath: image.path,
        aspectRatio: CropAspectRatio(ratioX: 16, ratioY: 9),
        aspectRatioPresets: Platform.isAndroid
            ? [CropAspectRatioPreset.ratio3x2]
            : [
                CropAspectRatioPreset.ratio3x2,
              ],
        compressQuality: 100,
        maxWidth: 700,
        maxHeight: 700,
        compressFormat: ImageCompressFormat.jpg,
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ),
      );

      final inputImage = InputImage.fromFile(File(image.path));

      final text = await _textDetector.processImage(inputImage);
      setState(() {
        nidFrontImage = croppedTextImage;
        _recognisedText = text;
      });
      textString = _recognisedText.text;
      print('Text Recognizer:' + _recognisedText.text);
      if (textString.replaceAll(' ', '').contains('6427886723')) {
        Fluttertoast.showToast(
            msg: "nid match",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
        print("text:" + textString);
        print('text nid match');
      } else {
        Fluttertoast.showToast(
            msg: "nid not found try again!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
        print('text nid not match');
      }
    }
  }

  //barcode scanner
  Future<void> readBarcode() async {
    PickedFile image = await ImagePicker().getImage(source: ImageSource.camera);
    if (image != null) {
      File cropped = await ImageCropper.cropImage(
        sourcePath: image.path,
        aspectRatio: CropAspectRatio(ratioX: 16, ratioY: 9),
        aspectRatioPresets: Platform.isAndroid
            ? [CropAspectRatioPreset.ratio3x2]
            : [
                CropAspectRatioPreset.ratio3x2,
              ],
        compressQuality: 100,
        maxWidth: 700,
        maxHeight: 700,
        compressFormat: ImageCompressFormat.jpg,
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
          aspectRatioLockDimensionSwapEnabled: false,
        ),
      );

      final inputImage = InputImage.fromFile(File(image.path));
      final result = await _barcodeDetector.processImage(inputImage);
      setState(() {
        barcodes = result;
        nidBackImage = cropped;
      });
      print('barcode length:' + '${barcodes.length}');
      if (barcodes.length != 0) {
        barcodeString = barcodes[0].value.displayValue;
        if (barcodeString.contains('6427886723')) {
          Fluttertoast.showToast(
              msg: "nid match",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
          print("barcode:" + barcodeString);
          print('nid match');
        } else {
          return null;
        }
      } else {
        fetchDataErrorDialog('', 'Barcode not detected. Please try again!');
        print('nid not matched');
      }
    }
  }

  //onScreen error dialog
  fetchDataErrorDialog(String title, String msg, {Function() onPressed}) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          msg,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('SKIP'),
          ),
          TextButton(
            onPressed: onPressed,
            child: Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }

  errorDialog(String title) {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text(
              title,
              style: TextStyle(fontSize: 18),
            ),
            children: <Widget>[
              Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 10),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OKAY',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _isInternet = true;
    });
  }

  @override
  void dispose() async {
    await _barcodeDetector.close();
    await _textDetector.close();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nid Information'),
        automaticallyImplyLeading: false,
        actions: [

        ],
      ),
      /*body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 10),
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.95,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                nidFrontImage == null
                    ? ElevatedButton(
                  onPressed: textRecognition,
                  child:
                  const Text("Capture NID Front side Image"),
                )
                    : textString == null ||
                    !textString
                        .replaceAll(' ', '')
                        .contains('6427886723')
                    ? ElevatedButton(
                  onPressed: textRecognition,
                  child: const Text("Try Again!"),
                )
                    : Container(
                  height: MediaQuery.of(context).size.height *
                      0.295,
                  width: MediaQuery.of(context).size.width *
                      0.95,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      File(nidFrontImage?.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 10),
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.95,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                nidBackImage == null
                    ? ElevatedButton(
                  onPressed: readBarcode,
                  child:
                  const Text("Capture NID Back side Image"),
                )
                    : Container(
                  height:
                  MediaQuery.of(context).size.height * 0.295,
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      File(nidBackImage?.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 12),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  try {

                    if (_isInternet) {
                      if (nidFrontImage != null ||
                          nidBackImage != null) {
                        //For eKycId

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EKycCustomerNidConfirmation(
                                  frontImg: nidFrontImage?.path,
                                  backImg: nidBackImage?.path,
                                  nid: '6427886723',
                                ),
                          ),
                        );
                      } else {
                        errorDialog();
                      }

                    } else {
                      connectivityChecker();
                    }
                  } catch (e) {
                    setState(() {
                      connectivityChecker();
                    });
                    print(e.toString());
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 12),
                  child: Text(
                    'Submit',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),*/
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.95,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                nidFrontImage == null
                    ? ElevatedButton(
                  onPressed: textRecognition,
                  child: const Text("Capture NID Front side Image"),
                )
                    : Container(
                  height: MediaQuery.of(context).size.height * 0.295,
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      File(nidFrontImage?.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.95,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                nidBackImage == null
                    ? ElevatedButton(
                  onPressed: readBarcode,
                  child: const Text("Capture NID Back side Image"),
                )
                    : Container(
                  height: MediaQuery.of(context).size.height * 0.295,
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      File(nidBackImage?.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (_isInternet) {
                      if (nidFrontImage == null) {
                        errorDialog(
                            'Please submit nid Front side image properly');
                      } else if (nidBackImage == null) {
                        errorDialog('Please submit nid Back side image properly');
                      } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EKycCustomerNidConfirmation(
                                    frontImg: nidFrontImage?.path,
                                    backImg: nidBackImage?.path,
                                    nid: '6427886723',
                                  ),
                            ),
                          );
                      }
                    } else {
                      connectivityChecker();
                    }
                  } catch (e) {
                    setState(() {
                      connectivityChecker();
                    });
                    print(e.toString());
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  child: Text(
                    'Submit',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class EKycCustomerNidConfirmation extends StatelessWidget {
  final String frontImg;
  final String backImg;
  final String nid;
  const EKycCustomerNidConfirmation({this.frontImg, this.backImg, this.nid});
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
