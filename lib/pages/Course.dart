import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learning_languages/pages/LecturesPage.dart';
import 'dart:typed_data';

import 'package:learning_languages/service/AuthService.dart';

class Course extends StatefulWidget {
  const Course({super.key});

  @override
  State<Course> createState() => _CourseState();
}

class _CourseState extends State<Course> {
  String courseName = '';
  XFile? _image;
  Uint8List? _imageBytes;

  final ImagePicker _picker = ImagePicker();

  Future pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _image = image;
      });
    }
  }

  Future<List<dynamic>> fetchCourses() async {
    final response = await Dio().get('$api/LanguageCourses');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to load courses');
    }
  }

  Future<Uint8List?> fetchCourseImage(int pictureId) async {
    try {
      final response = await Dio().get(
        '$api/Pictures/$pictureId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      print('Failed to load image: $e');
      return null;
    }
  }



  Future<void> uploadCourseData() async {
    if (courseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Введите название курса')));
      return;
    }

    try {
      int? pictureId;

      // Шаг 1: Загрузка изображения
      if (_imageBytes != null) {
        String fileName = _image!.name;

        FormData formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(_imageBytes!, filename: fileName),
        });

        var imageResponse = await Dio().post(
          "$api/Pictures",
          data: formData,
        );

        if (imageResponse.statusCode == 200 || imageResponse.statusCode == 201) {
          pictureId = imageResponse.data['idPicture']; // Убедитесь, что ключ соответствует ключу в ответе вашего API
        } else {
          throw Exception("Failed to upload image");
        }
      }

      // Шаг 2: Добавление курса с ID изображения
      if (pictureId != null) {
        var courseResponse = await Dio().post(
          "$api/LanguageCourses",
          data: {
            "courseName": courseName,
            "pictureId": pictureId,
          },
        );

        if (courseResponse.statusCode == 200 || courseResponse.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Курс успешно добавлен!')));
          Navigator.of(context).pop(); // Возвращение на предыдущий экран
        } else {
          throw Exception("Failed to add course");
        }
      } else {
        throw Exception("Picture ID is null");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при отправке данных: ${e.toString()}')));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Курсы'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            return GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: snapshot.data!.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                var course = snapshot.data![index];
                return FutureBuilder<Uint8List?>(
                  future: fetchCourseImage(course['pictureId']),
                  builder: (context, imageSnapshot) {
                    Widget imageWidget = imageSnapshot.hasData
                        ? Image.memory(imageSnapshot.data!, fit: BoxFit.cover)
                        : Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Изображение не доступно"),
                    );
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LecturesPage(courseId: course['languageCourseId'])),
                          );
                        },
                        child: Column(
                          children: [
                            Expanded(child: imageWidget),
                            ListTile(
                              title: Text(course['courseName']),
                            ),
                          ],
                        ),
                      ),
                    );

                  },
                );
              },
            );
          } else {
            return Center(child: Text("Нет данных"));
          }
        },
      ),
      floatingActionButton: Visibility(
        visible: kIsWeb,
        child: FloatingActionButton(
          onPressed: _showAddCourseDialog,
          tooltip: 'Добавить курс',
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Используем StatefulBuilder для обновления состояния внутри диалога
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Создать курс'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        courseName = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Название курса',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await pickImage();
                        // Обновление локального состояния диалога для отображения изображения
                        setState(() {});
                      },
                      child: Text('Добавить фото'),
                    ),
                    _imageBytes != null
                        ? Image.memory(_imageBytes!, width: 200)
                        : Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text("Изображение не выбрано"),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    uploadCourseData();
                  },
                  child: Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }


}
