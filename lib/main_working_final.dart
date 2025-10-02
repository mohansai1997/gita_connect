import 'package:flutter/material.dart';

void main() {
  runApp(const GitaConnectApp());
}

class GitaConnectApp extends StatelessWidget {
  const GitaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gita Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const GitaConnectHomePage(title: 'Gita Connect - ISKCON Youth'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GitaConnectHomePage extends StatefulWidget {
  const GitaConnectHomePage({super.key, required this.title});

  final String title;

  @override
  State<GitaConnectHomePage> createState() => _GitaConnectHomePageState();
}

class _GitaConnectHomePageState extends State<GitaConnectHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeTab(),
    CoursesTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange.shade100,
                  Colors.orange.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.temple_hindu,
                  size: 64,
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome to Gita Connect',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Spiritual Learning Journey',
                  style: TextStyle(
                    color: Colors.deepOrange.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quote Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepOrange.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Wisdom',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '"If one reads Bhagavad-gītā regularly and attentively, he can surpass all studies of Vedic literature"',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '— A. C. Bhaktivedanta Swami Prabhupada',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.deepOrange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // YouTube Shorts Section
          Text(
            'Spiritual Shorts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_filled,
                        size: 40,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Short ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Lecture Videos Section
          Text(
            'Lecture Videos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepOrange.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bhagavad Gita Lecture ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Deep spiritual insights',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Success indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gita Connect Successfully Running! 🎉',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Your ISKCON spiritual learning app is ready!',
                        style: TextStyle(color: Colors.green.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoursesTab extends StatelessWidget {
  const CoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 64, color: Colors.deepOrange),
          SizedBox(height: 16),
          Text(
            'Courses',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('Coming Soon!'),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.deepOrange),
          SizedBox(height: 16),
          Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('Your Spiritual Journey'),
        ],
      ),
    );
  }
}