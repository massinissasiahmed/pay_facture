import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:flutter_ocr_sdk/flutter_ocr_sdk_platform_interface.dart';
import 'package:flutter_ocr_sdk/mrz_line.dart';
import 'package:flutter_ocr_sdk/mrz_parser.dart';
import 'package:flutter_ocr_sdk/mrz_result.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'camera_page.dart';
import 'global.dart';
import 'utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();



  void scanImage() async {
    XFile? photo = await picker.pickImage(source: ImageSource.gallery);

    if (photo == null) {
      return;
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      File rotatedImage =
          await FlutterExifRotation.rotateImage(path: photo.path);
      photo = XFile(rotatedImage.path);
    }

    Uint8List fileBytes = await photo.readAsBytes();

    ui.Image image = await decodeImageFromList(fileBytes);

    ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData != null) {
      List<List<MrzLine>>? results = await mrzDetector.recognizeByBuffer(
          byteData.buffer.asUint8List(),
          image.width,
          image.height,
          byteData.lengthInBytes ~/ image.height,
          ImagePixelFormat.IPF_ARGB_8888.index);
      List<MrzLine>? finalArea;
      var information;
      if (results != null && results.isNotEmpty) {
        for (List<MrzLine> area in results) {
          if (area.length == 2) {
            finalArea = area;
            information = MRZ.parseTwoLines(area[0].text, area[1].text);
            information.lines = '${area[0].text}\n${area[1].text}';
            break;
          } else if (area.length == 3) {
            finalArea = area;
            information =
                MRZ.parseThreeLines(area[0].text, area[1].text, area[2].text);
            information.lines =
                '${area[0].text}\n${area[1].text}\n${area[2].text}';
            break;
          }
        }
      }
      if (finalArea != null) {
       print("good");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttons = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
            onTap: () {
              if (!kIsWeb && Platform.isLinux) {
                showAlert(context, "Warning",
                    "${Platform.operatingSystem} is not supported");
                return;
              }

              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const CameraPage();
              }));
            },
            child: Container(
              width: 150,
              height: 125,
              decoration: BoxDecoration(
                color: colorOrange,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    "images/icon-camera.png",
                    width: 90,
                    height: 60,
                  ),
                  const Text(
                    "Camera Scan",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  )
                ],
              ),
            )),
       
      ],
    );

 
    return Scaffold(
      body: Column(
        children: [
          
        
          buttons,
         
                      
                          
                
          
        ],
      ),
    );
  }
}
