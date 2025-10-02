import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../providers/providers.dart';
import '../../router/app_router.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});
  
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).setIndex(index);
          _navigateToPage(context, index);
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.playBox),
            label: 'Shorts',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.bookOpenPageVariant),
            label: 'Courses',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.shorts);
        break;
      case 2:
        context.go(AppRoutes.courses);
        break;
      case 3:
        context.go(AppRoutes.events);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }
}