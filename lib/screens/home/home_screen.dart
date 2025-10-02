import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../widgets/shorts/shorts_section.dart';
import '../../widgets/quote/quote_section.dart';
import '../../widgets/gallery/gallery_section.dart';
import '../../widgets/lectures/lectures_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gita Connect',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.light 
                  ? Icons.dark_mode 
                  : Icons.light_mode,
            ),
            onPressed: () {
              ref.read(themeNotifierProvider.notifier).toggleTheme();
            },
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Section 1: Shorts (Top Section)
            const ShortsSection(),
            
            // Section 2: Daily Quote
            const QuoteSection(),
            
            // Section 3: Gallery
            const GallerySection(),
            
            // Section 4: Lecture Videos (Bottom Section)
            const LecturesSection(),
          ],
        ),
      ),
    );
  }






}