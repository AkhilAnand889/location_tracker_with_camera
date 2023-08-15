import 'dart:io';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  Uint8List? imgBytes;
  XFile? _image;
  bool isLoading = false;
  String locationText = 'Location: N/A';
  bool showImageWithLocation = false;
  String timeText = '';
  String latLongText = '';
  double _imageQuality = 100;
  String currentImagePath = '';
  String currentPath = 'watermarked_image';
  late final TextEditingController _fileNameController;
  late CroppedFile _croppedFile;
  double _maxSliderValue = 100;
  double imageSizeText = 000;
  List<String> sizeLabels = [];

  String crops = '';

  GlobalKey _globalKey = GlobalKey();
  pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (image != null) {
      _image = image;
      var t = await image.readAsBytes();
      imgBytes = Uint8List.fromList(t);
      currentImagePath = image.path;
      showImageWithLocation = false;

      _croppedFile = (await ImageCropper().cropImage(
        sourcePath: _image!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
            presentStyle: CropperPresentStyle.dialog,
            boundary: const CroppieBoundary(
              width: 520,
              height: 520,
            ),
            viewPort:
                const CroppieViewPort(width: 480, height: 480, type: 'circle'),
            enableExif: true,
            enableZoom: true,
            showZoomer: true,
          ),
        ],
      ))!;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
    _fileNameController = TextEditingController(text: currentImagePath);
    setupMaxSliderValue();
    _imageQuality = 100;
  }

  Future<void> requestLocationPermission() async {
    if (await Permission.location.isGranted) {
      return;
    }

    var status = await Permission.location.request();
    if (status.isDenied) {
    } else if (status.isPermanentlyDenied) {}
  }

// get current location

  Future<void> getCurrentLocationAndShowImage() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      DateTime pictureTime = DateTime.fromMillisecondsSinceEpoch(
        position.timestamp!.millisecondsSinceEpoch,
      );
      timeText =
          '   Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(pictureTime)}';

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark placemark = placemarks.first;

      String address =
          '   ${placemark.postalCode} ,${placemark.locality}, ${placemark.country}, ${placemark.subLocality}';
      locationText = address;

      latLongText =
          '   Latitude: ${position.latitude.toStringAsFixed(6)}       Longitude: ${position.longitude.toStringAsFixed(6)}';
      setState(() {
        this.locationText = locationText;
        showImageWithLocation = true;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        locationText = 'Error getting location';
        showImageWithLocation = false;
      });
    }
  }

// to save the watermark image to gallery

  Future<void> saveImageWithWatermark() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 4.0);
    var byteData = await image.toByteData(format: ImageByteFormat.png);
    var buffer = byteData!.buffer.asUint8List();

    String fileName = _fileNameController.text.isEmpty
        ? 'watermarked_image.png'
        : '${_fileNameController.text}_${((buffer.length / 1024) / 2).toStringAsFixed(1)}KB.png';
    final newvalue = convertKBToPercentage();
    final bearervalue = convertPercentageToImageSize(newvalue);
    final something = bearervalue / 2;
    print(newvalue);
    final result = await ImageGallerySaver.saveImage(Uint8List.fromList(buffer),
        name: fileName, quality: newvalue.toInt());

    double sizeInKB = buffer.length / 1024;
    String sizeLabel;
    if (sizeInKB > 1024) {
      double sizeInMB = (sizeInKB / 1024) / 2;
      sizeLabel = '${sizeInMB.toStringAsFixed(1)} MB';
      print(sizeLabel);
    } else {
      sizeLabel = '${sizeInKB} KB';
      print(sizeLabel);
    }

    setState(() {
      _maxSliderValue = sizeInKB / 2;
      sizeLabels.add(sizeLabel);
    });

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.green,
        ),
        SizedBox(width: 8),
        Text(
          'Image successfully saved to the gallery',
          style: TextStyle(color: Colors.white),
        ),
      ],
    ),
    backgroundColor: Colors.black87,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    action: SnackBarAction(
      label: 'Close',
      textColor: Colors.white,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  ),
);

  }

  double convertKBToPercentage() {
    // Calculate the percentage relative to the maximum slider value
    double percentage = (_imageQuality / _maxSliderValue) * 100;

    // Ensure the percentage is within the range of 0 to 100
    percentage = percentage.clamp(0.0, 100.0);
    return percentage;
  }


double convertPercentageToImageSize(double percentage) {
  // Calculate the corresponding image quality based on the percentage
  double imageQuality = (percentage * (_maxSliderValue / 100));

  // Calculate the image file size in kilobytes based on image quality
  double imageSizeKB = imageQuality * 2;

  return imageSizeKB;
}

  Future<double> calculateImageSize() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 4.0);
    var byteData = await image.toByteData(format: ImageByteFormat.png);
    var buffer = byteData!.buffer.asUint8List();

    double imageSizeKB = buffer.length / 1024;
    return imageSizeKB;
  }

// for getting image size in kilobytes
  Widget buildCustomSlider({
    required double value,
    required double minValue,
    required double maxValue,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
        thumbColor: Color.fromARGB(255, 26, 26, 26),
        activeTrackColor: Color.fromARGB(255, 48, 49, 48),
        inactiveTrackColor: Color.fromARGB(255, 205, 210, 207),
        overlayColor: Color.fromARGB(99, 26, 26, 26),
        valueIndicatorColor: Color.fromARGB(255, 37, 39, 37),
        valueIndicatorTextStyle: TextStyle(
          color: Colors.white,
        ),
      ),
      child: Slider(
        value: value,
        min: minValue,
        max: maxValue,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }

  void setupMaxSliderValue() async {
    if (showImageWithLocation) {
      double imageSizeKB = await calculateImageSize();
      setState(() {
        _maxSliderValue = imageSizeKB / 2;
      });
    }
  }

  Future<void> showButtonFlushbar() async {
    Flushbar(
      mainButton: ButtonBar(
        children: [
          GestureDetector(
            onTap: () {
              print("You clicked me!");
            },
            child: const Text(
              "Click me",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      backgroundColor: Colors.black,
      title: "No Image Selected",
      message: "first select an image before downloading...",
      messageSize: 17,
      duration: const Duration(seconds: 4),
    ).show(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 200, 219, 147),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Text(
                'Location Tracker',
                style: GoogleFonts.audiowide(fontSize: 30, letterSpacing: 2),
              )),
              SizedBox(height: 40),
              GestureDetector(
                onTap: () async {
                  await pickImage();
                  isLoading
                      ? const CircularProgressIndicator()
                      : await getCurrentLocationAndShowImage();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  height: 300,
                  child: _image == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40),
                              SizedBox(height: 10),
                              Text(
                                'Click here to choose an image',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : Image.file(
                          File(_croppedFile.path),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
             
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(),
              if (showImageWithLocation)
                RepaintBoundary(
                  key: _globalKey,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (imgBytes != null)
                        Image.file(
                          File(_croppedFile.path),
                          fit: BoxFit.cover,
                        ),
                      Positioned(
                        bottom: 15,
                        left: 30,
                        right: 30,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(96, 0, 0, 0),
                            backgroundBlendMode: BlendMode.overlay,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 11),
                              Text(
                                locationText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: 11),
                              Text(
                                timeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: 8),
                              Text(
                                latLongText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 7),
              const Center(
                child: Text(
                  'Customize the image file name',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 218, 70, 159),
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.grey,
                        offset: Offset(2, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(
                height: 15,
              ),
              TextField(
                controller: _fileNameController,
                decoration: InputDecoration(
                  labelText: 'Image File Name',
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal, // Change label color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.teal, width: 2.0), // Change border color
                    borderRadius:
                        BorderRadius.circular(12.0), // Add border radius
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                    borderRadius:
                        BorderRadius.circular(12.0), // Add border radius
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.image,
                    color: Colors.teal, // Change icon color
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.teal, // Change icon color
                    ),
                    onPressed: () {
                      _fileNameController.clear();
                    },
                  ),
                ),
              ),
              SizedBox(height: 13),
              const Center(
                child: Text(
                  'Customize the image quality',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 218, 70, 159),
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.grey,
                        offset: Offset(2, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              buildCustomSlider(
                value: _imageQuality,
                minValue: 0,
                maxValue: _maxSliderValue,
                divisions: 100,
                label: '${_imageQuality.round()} KB',
                onChanged: (double value) {
                  setState(() {
                    _imageQuality = value;
                  });

                  double percentage = convertKBToPercentage();
                  print(percentage);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_croppedFile == null) {
                    // Show a Snackbar to inform the user to select an image first
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select an image first.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return; // Exit the function early
                  }

                  double imageSizeKB = await calculateImageSize();
                  double imageQuality = convertKBToPercentage();

                  setState(() {
                    _maxSliderValue = imageSizeKB / 2;
                    imageSizeText = (imageSizeKB.toDouble() / 2);
                    _imageQuality = imageQuality;
                  });
                },
                style: ElevatedButton.styleFrom(
                  primary: const Color.fromARGB(255, 33, 243, 75),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.generating_tokens,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Get image file size',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  if (_croppedFile == null) {
                    // Show a Snackbar to inform the user to select an image first
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select an image first.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return; // Exit the function early
                  }

                  double imageSizeKB = await calculateImageSize();
                  print(imageSizeKB / 2);

                  setState(() {
                    _maxSliderValue = imageSizeKB / 2;
                    imageSizeText = (imageSizeKB.toDouble() / 2);
                  });

                  await saveImageWithWatermark();
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Download Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Example of using the compressImage method
              
            ],
          ),
        ),
      ),
    );
  }
}
