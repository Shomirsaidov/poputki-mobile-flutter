import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/my-rides')) {
      currentIndex = 1;
    } else if (location.startsWith('/create')) {
      currentIndex = 2;
    } else if (location.startsWith('/my-tickets')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      currentIndex = 4;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/');
                break;
              case 1:
                context.go('/my-rides');
                break;
              case 2:
                context.go('/create');
                break;
              case 3:
                context.go('/my-tickets');
                break;
              case 4:
                context.go('/profile');
                break;
            }
          },
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Поиск',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              label: 'Поездки',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              label: 'Создать',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              label: 'Билеты',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}
