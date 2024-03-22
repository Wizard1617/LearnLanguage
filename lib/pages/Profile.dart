import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learning_languages/main.dart';
import 'dart:convert';

import 'package:learning_languages/service/AuthService.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic> userProfile = {};

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final response = await http.get(
      Uri.parse('$api/Users/$UserId'),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        userProfile = json.decode(response.body);
      });
    } else {
      // Обработка ошибки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки профиля пользователя')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль '),
      ),
      body: Center(
        child: userProfile.isEmpty
            ? CircularProgressIndicator()
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                // Пример использования изображения
                backgroundImage: NetworkImage(userProfile['imageUrl'] ?? 'https://via.placeholder.com/150'),
              ),
              SizedBox(height: 20),
              Text(
                '${userProfile['firstName']} ${userProfile['lastName']}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userProfile['email'],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),

              // Добавьте другие Card виджеты для отображения оставшейся информации
            ],
          ),
        ),
      ),
    );
  }
}
