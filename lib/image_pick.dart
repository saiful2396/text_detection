import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'nid_front_back.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PickedFile _imageFile;
  dynamic _pickImageError;
  bool isVideo = false;

  File nidBackImage;
  BarcodeScanner _barcodeDetector = GoogleMlKit.vision.barcodeScanner();
  List<Barcode> barcodes;
  var barcodeString;

  var textString = '';
  RecognisedText _recognisedText;
  TextDetector _textDetector = GoogleMlKit.vision.textDetector();
  File nidFrontImage;

  var nidAllData;
  var eKycId;
  bool _isInternet = false;

  String _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController maxWidthController = TextEditingController();
  final TextEditingController maxHeightController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();

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
  Future<void> textRecognition(BuildContext context) async {
    try {
      PickedFile image = Platform.isIOS
          ? await ImagePicker()
              .getImage(source: ImageSource.camera, imageQuality: 100)
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
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  //barcode scanner
  Future<void> readBarcode(BuildContext context) async {
    try {
      PickedFile image =
          await ImagePicker().getImage(source: ImageSource.camera);
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
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  //onScreen error dialog
  fetchDataErrorDialog(String title, String msg) {
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
            onPressed: () {
              readBarcode(context);
              Navigator.pop(context);
            },
            child: Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }

  errorDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text(
              'Please submit nid both side image properly',
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

  void _onImageButtonPressed(ImageSource source, {BuildContext context}) async {
    await _displayPickImageDialog(context,
        (double maxWidth, double maxHeight, int quality) async {
      try {
        final pickedFile = await _picker.getImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: quality,
        );
        setState(() {
          _imageFile = pickedFile;
        });
      } catch (e) {
        setState(() {
          _pickImageError = e;
        });
      }
    });
  }

  @override
  void dispose() async {
    maxWidthController.dispose();
    maxHeightController.dispose();
    qualityController.dispose();
    await _barcodeDetector.close();
    await _textDetector.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _isInternet = true;
    });
  }

  Widget _previewImage() {
    final Text retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (nidBackImage == null || nidFrontImage == null) {
      return ListView(
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
                        onPressed: ()=>textRecognition(context),
                        child: const Text("Capture NID Front side Image"),
                      )
                    : textString == null ||
                            !textString
                                .replaceAll(' ', '')
                                .contains('6427886723')
                        ? ElevatedButton(
                            onPressed: ()=>textRecognition(context),
                            child: const Text("Try Again!"),
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
                        onPressed: ()=>readBarcode(context),
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
                      if (nidFrontImage != null || nidBackImage != null) {
                        //For eKycId

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EKycCustomerNidConfirmation(
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
      );
    } else if (_pickImageError == null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'You have not yet picked an image.',
        textAlign: TextAlign.center,
      );
    }
  }

  Future<void> retrieveLostData() async {
    final LostData response = await _picker.getLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _imageFile = response.file;
      });
    } else {
      _retrieveDataError = response.exception.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('widget.title'),
      ),
      body: Center(
        child: defaultTargetPlatform == TargetPlatform.android
            ? FutureBuilder<void>(
                future: retrieveLostData(),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const Text(
                        'You have not yet picked an image.',
                        textAlign: TextAlign.center,
                      );
                    case ConnectionState.done:
                      return _previewImage();
                    default:
                      if (snapshot.hasError) {
                        return Text(
                          'Pick image/video error: ${snapshot.error}}',
                          textAlign: TextAlign.center,
                        );
                      } else {
                        return const Text(
                          'You have not yet picked an image.',
                          textAlign: TextAlign.center,
                        );
                      }
                  }
                },
              )
            : _previewImage(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Semantics(
            label: 'image_picker_example_from_gallery',
            child: FloatingActionButton(
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(ImageSource.gallery, context: context);
              },
              heroTag: 'image0',
              tooltip: 'Pick Image from gallery',
              child: const Icon(Icons.photo_library),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(ImageSource.camera, context: context);
              },
              heroTag: 'image1',
              tooltip: 'Take a Photo',
              child: const Icon(Icons.camera_alt),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                isVideo = true;
                _onImageButtonPressed(ImageSource.gallery);
              },
              heroTag: 'video0',
              tooltip: 'Pick Video from gallery',
              child: const Icon(Icons.video_library),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                isVideo = true;
                _onImageButtonPressed(ImageSource.camera);
              },
              heroTag: 'video1',
              tooltip: 'Take a Video',
              child: const Icon(Icons.videocam),
            ),
          ),
        ],
      ),
    );
  }

  Text _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Future<void> _displayPickImageDialog(
      BuildContext context, OnPickImageCallback onPick) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Add optional parameters'),
            content: Column(
              children: <Widget>[
                TextField(
                  controller: maxWidthController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(hintText: "Enter maxWidth if desired"),
                ),
                TextField(
                  controller: maxHeightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(hintText: "Enter maxHeight if desired"),
                ),
                TextField(
                  controller: qualityController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(hintText: "Enter quality if desired"),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                  child: const Text('PICK'),
                  onPressed: () {
                    double width = maxWidthController.text.isNotEmpty
                        ? double.parse(maxWidthController.text)
                        : null;
                    double height = maxHeightController.text.isNotEmpty
                        ? double.parse(maxHeightController.text)
                        : null;
                    int quality = qualityController.text.isNotEmpty
                        ? int.parse(qualityController.text)
                        : null;
                    onPick(width, height, quality);
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }
}

typedef void OnPickImageCallback(
    double maxWidth, double maxHeight, int quality);
