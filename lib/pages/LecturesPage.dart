import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:learning_languages/pages/LectureDetailsPage.dart';
import 'package:learning_languages/service/AuthService.dart';

class LecturesPage extends StatefulWidget {
  final int courseId;

  LecturesPage({Key? key, required this.courseId}) : super(key: key);

  @override
  _LecturesPageState createState() => _LecturesPageState();
}

class _LecturesPageState extends State<LecturesPage> {
  String lectureName = '';

  Future<void> addLecture() async {
    if (lectureName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Введите название лекции')));
      return;
    }

    try {
      final response = await Dio().post(
        '$api/Lectures',
        data: {
          "courseId": widget.courseId,
          "lectureName": lectureName,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Лекция успешно добавлена!')));
        setState(() {
          lectureName = '';
        });
      } else {
        throw Exception("Failed to add lecture");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при отправке данных: ${e.toString()}')));
    }
  }

  Future<List<dynamic>> fetchLectures() async {
    final response = await Dio().get('$api/Lectures?courseId=${widget.courseId}');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to load lectures');
    }
  }


  void _showAddLectureDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Используем StatefulBuilder для обновления состояния внутри диалога
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Добавить лекцию'),
              content: TextField(
                onChanged: (value) {
                  setState(() {
                    lectureName = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Название лекции',
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    addLecture().then((_) => Navigator.of(context).pop());
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

  @override
  Widget build(BuildContext context) {
    // Ваш FutureBuilder и другой код
    return Scaffold(
      appBar: AppBar(
        title: Text('Лекции'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchLectures(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var lecture = snapshot.data![index];
                return ListTile(
                  title: Text(lecture['lectureName']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LectureDetailsPage(lectureId: lecture['lectureId']),
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
      floatingActionButton: FloatingActionButton(
      onPressed: _showAddLectureDialog,
      tooltip: 'Добавить лекцию',
      child: Icon(Icons.add),
    ),
    );
  }
}
