import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFScreen extends StatelessWidget {
  final String path;

  PDFScreen(this.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Просмотр PDF'),
      ),
      body: PDFView(
        filePath: path,
        autoSpacing: true,
        enableSwipe: true,
        pageSnap: true,
        swipeHorizontal: true,
        nightMode: false,
      ),
    );
  }
}
