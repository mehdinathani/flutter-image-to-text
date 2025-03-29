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

  // Variables for invoice details
  String nameValue = "";
  String invoiceNumberValue = "";
  String amountValue = "";

  // Variables for dynamic tag lookup
  final TextEditingController tagController = TextEditingController();
  String dynamicValue = "";

  @override
  void initState() {
    super.initState();
    // Listen for changes in the tag input.
    tagController.addListener(() {
      final tag = tagController.text;
      if (tag.isNotEmpty && extractedText.isNotEmpty) {
        setState(() {
          dynamicValue = extractTagValue(tag, extractedText);
        });
      } else {
        setState(() {
          dynamicValue = "";
        });
      }
    });
  }

  @override
  void dispose() {
    tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OCR Invoice Scanner")),
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
      extractInvoiceDetails(extractedText);
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
      extractInvoiceDetails(extractedText);
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
    await textRecognizer.close(); // Free resources
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

  /// Extracts invoice details (Name, Invoice No, Amount) using preset tags.
  void extractInvoiceDetails(String text) {
    nameValue = extractTagValue("Name:", text);
    invoiceNumberValue = extractTagValue("Invoice No:", text);
    amountValue = extractTagValue("Amount:", text);
  }

  /// This function accepts a tag (e.g., "Name:") and searches for it in the text.
  /// It returns the value following the tag (trimmed) if found, otherwise "Not Found".
  String extractTagValue(String tag, String text) {
    final pattern = RegExp(RegExp.escape(tag) + r'\s*(.*)', multiLine: true);
    final match = pattern.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim() ?? "Not Found";
    }
    return "Not Found";
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
                    // Display preview: PDF icon for PDFs, or image for images.
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
                            buildDetailRow("Name", nameValue),
                            buildDetailRow("Invoice No", invoiceNumberValue),
                            buildDetailRow("Amount", amountValue),
                            const SizedBox(height: 20),
                            // Dynamic TextField for user to input a tag.
                            TextField(
                              controller: tagController,
                              decoration: const InputDecoration(
                                labelText: "Enter tag (e.g., Name:)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Value: " +
                                  (dynamicValue.isNotEmpty
                                      ? dynamicValue
                                      : "Not Found"),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
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
                              label: const Text("Copy All Text"),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
    );
  }

  Widget buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("$title copied!")));
            },
          ),
        ],
      ),
    );
  }
}
