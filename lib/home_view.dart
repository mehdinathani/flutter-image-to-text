import 'dart:io';
import 'package:camera_gallery_image_picker/camera_gallery_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  File? selectedMedia;
  String extractedText = "";
  bool isLoading = false; // Track loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OCR Scanner")),
      body: Padding(padding: const EdgeInsets.all(16.0), child: buildUI()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: pickImage,
        label: const Text("Select Image"),
        icon: const Icon(Icons.image),
      ),
    );
  }

  Future<void> pickImage() async {
    final File? media = await CameraGalleryImagePicker.pickImage(
      context: context,
      source: ImagePickerSource.both,
    );

    if (media != null) {
      setState(() {
        selectedMedia = media;
        extractedText = "";
        isLoading = true; // Start loading
      });

      extractedText = await extractText(media);

      setState(() {
        isLoading = false; // Stop loading after text extraction
      });
    }
  }

  Widget buildUI() {
    return Center(
      child:
          selectedMedia == null
              ? const Text(
                "No media selected",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              )
              : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(selectedMedia!, width: 250),
                    ),
                    const SizedBox(height: 20),

                    // Show loading indicator while text is being processed
                    isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                extractedText.isEmpty
                                    ? "No text found"
                                    : extractedText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Copy Button
                            extractedText.isNotEmpty
                                ? ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: extractedText),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Text copied to clipboard!",
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy),
                                  label: const Text("Copy Text"),
                                )
                                : const SizedBox(),
                          ],
                        ),
                  ],
                ),
              ),
    );
  }

  Future<String> extractText(File file) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(file);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    textRecognizer.close(); // Always close the recognizer to free up resources
    return recognizedText.text;
  }
}
