import 'dart:io';
import 'package:camera_gallery_image_picker/camera_gallery_image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:flutter/services.dart'; // For Clipboard operations

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  File? selectedMedia;
  String extractedText = "";
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OCR Scanner")),
      body: buildUI(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "pickImage",
            onPressed: pickImage,
            icon: const Icon(Icons.image),
            label: const Text("Select Image"),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "pickPdf",
            onPressed: pickPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Select PDF"),
          ),
        ],
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
        isLoading = true;
      });

      extractedText = await extractTextFromImage(media);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickPdf() async {
    // Use FilePicker to pick a PDF file.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final File pdfFile = File(result.files.single.path!);
      setState(() {
        selectedMedia = pdfFile;
        extractedText = "";
        isLoading = true;
      });

      extractedText = await extractTextFromPdf(pdfFile);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> extractTextFromImage(File file) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(file);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    await textRecognizer.close(); // Free up resources
    return recognizedText.text;
  }

  Future<String> extractTextFromPdf(File file) async {
    try {
      String text = await ReadPdfText.getPDFtext(file.path);
      return text;
    } catch (e) {
      return "Error extracting text from PDF: $e";
    }
  }

  Widget buildUI() {
    return Center(
      child:
          selectedMedia == null
              ? const Text(
                "No file selected",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Show a preview: if it's a PDF, show a PDF icon; if it's an image, display the image.
                    selectedMedia!.path.toLowerCase().endsWith(".pdf")
                        ? const Icon(
                          Icons.picture_as_pdf,
                          size: 150,
                          color: Colors.red,
                        )
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(selectedMedia!, width: 250),
                        ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                          children: [
                            Text(
                              extractedText.isEmpty
                                  ? "No text extracted."
                                  : extractedText,
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: extractedText),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Text copied to clipboard!"),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text("Copy Text"),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
    );
  }
}
