import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:learning_languages/pages/Course.dart';
import 'package:learning_languages/pages/Profile.dart';

class Navigation extends StatefulWidget {
  @override
  _NavigationBarState createState() => _NavigationBarState();
}

class _NavigationBarState extends State<Navigation> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    Course(),
    Profile(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Адаптация для веба
    if (kIsWeb) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: onTabTapped,
              labelType: NavigationRailLabelType.selected,
              destinations: [
                NavigationRailDestination(
                  icon: Transform.scale(
                    scale: 1.5, // Увеличение масштаба иконок
                    child: Icon(Icons.home),
                  ),
                  label: Text('Курсы'),
                ),
                NavigationRailDestination(
                  icon: Transform.scale(
                    scale: 1.5, // Увеличение масштаба иконок
                    child: Icon(Icons.account_circle),
                  ),
                  label: Text('Профиль'),
                ),
              ],
            ),
            Expanded(
              child: _children[_currentIndex],
            ),
          ],
        ),
      );
    } else {
      // Мобильная версия
      return Scaffold(
        body: _children[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Курсы',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Профиль',
            ),
          ],
        ),
      );
    }
  }
}
