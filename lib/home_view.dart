import 'dart:io';

import 'package:advanced_media_picker/advanced_media_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  File? selectedMedia;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: buildUI(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final List<XFile> media = await AdvancedMediaPicker.openPicker(
            context: context,
            style: PickerStyle(),
            cameraStyle: CameraStyle(),
            allowedTypes: PickerAssetType.image,
            maxVideoDuration: 60,
            selectionLimit: 10,
            isNeedToShowCamera: true,
            isNeedVideoCamera: true,
          );

          if (media.isNotEmpty) {
            selectedMedia = File(media.first.path);
            setState(() {});
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget buildUI() {
    if (selectedMedia == null) {
      return Center(child: Text("No media selected"));
    } else {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(child: Image.file(selectedMedia!, width: 200)),
            _extractTextView(),
          ],
        ),
      );
    }
  }

  Widget _extractTextView() {
    if (selectedMedia == null) {
      return Center(child: Text("No media selected"));
    } else {
      return FutureBuilder(
        future: extractText(selectedMedia!),
        builder: (context, snapshot) {
          return Text(
            snapshot.data ?? "",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          );
        },
      );
    }
  }

  Future<String> extractText(File file) async {
    final textReconnizer = TextRecognizer(script: TextRecognitionScript.latin);
    final InputImage inputImage = InputImage.fromFile(selectedMedia!);
    final RecognizedText recognizedText = await textReconnizer.processImage(
      inputImage,
    );
    String text = recognizedText.text;
    textReconnizer.close();
    return text;
  }
}
