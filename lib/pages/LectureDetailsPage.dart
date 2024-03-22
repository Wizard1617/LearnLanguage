import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:learning_languages/models/PDFScreen.dart';
import 'package:learning_languages/service/AuthService.dart';
import 'package:path_provider/path_provider.dart';

class LectureDetailsPage extends StatelessWidget {
  final int lectureId;

  LectureDetailsPage({Key? key, required this.lectureId}) : super(key: key);

  Future<void> openPDF(BuildContext context, int materialId, String title) async {
    try {
      // Запрос на скачивание файла PDF
      var response = await Dio().get(
        '$api/Materials/download/$materialId',
        options: Options(
          responseType: ResponseType.bytes, // Важно, чтобы получать файл в виде байтов
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      // Получение временной директории для сохранения файла
      var tempDir = await getTemporaryDirectory();
      var tempPath = tempDir.path;
      var filePath = '$tempPath/$title';

      // Сохранение файла на устройстве
      File file = File(filePath);
      await file.writeAsBytes(response.data);

      // Открытие PDF
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PDFScreen(filePath)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке файла: ${e.toString()}')),
      );
    }
  }

  Future<List<dynamic>> fetchMaterials(int lectureId) async {
    final response = await Dio().get('$api/Materials?lectureId=$lectureId');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to load materials');
    }
  }

  void _showAddMaterialDialog(BuildContext context) async {
    // Запускаем FilePicker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      print("Выбран файл: ${file.name}, размер: ${file.size}");

      if (file.path != null) {
        try {
          File fileToUpload = File(file.path!);
          List<int> fileBytes = await fileToUpload.readAsBytes();

          FormData formData = FormData.fromMap({
            "materialContent": await MultipartFile.fromFile(file.path!, filename: file.name),
            "fileName": file.name,
            "lectureId": lectureId.toString(), // Преобразование в строку, если ваш API ожидает строку
          });


          var response = await Dio().post(
            '$api/Materials',
            data: formData,
            options: Options(
              headers: {
                "Content-Type": "multipart/form-data",
              },
            ),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Материал успешно добавлен!')));
          } else {
            throw Exception("Failed to upload material");
          }
        } catch (e) {
          print(e);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при загрузке материала: ${e.toString()}')));
        }

      } else {
        print("Файл не содержит пути");
      }
    } else {
      print("Отмена выбора файла");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Материалы лекции'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchMaterials(lectureId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var material = snapshot.data![index];
                return ListTile(
                  title: Text(material['fileName']),
                  subtitle: Text('Размер файла: ${material['fileSize']}'),
                  onTap: () {
                    openPDF(context, material['materialId'], material['fileName']);
                  },
                );
              },
            );

          } else {
            return Center(child: Text('Нет данных'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMaterialDialog(context),
        tooltip: 'Добавить материал',
        child: Icon(Icons.add),
      ),

    );
  }
}


