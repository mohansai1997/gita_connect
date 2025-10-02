import 'package:flutter/material.dart';

void main() {
  runApp(GitaConnectSimple());
}

class GitaConnectSimple extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gita Connect',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: HomeScreenSimple(),
    );
  }
}

class HomeScreenSimple extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gita Connect',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade100,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade100, Colors.orange.shade50],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.temple_hindu, size: 60, color: Colors.orange),
                  SizedBox(height: 12),
                  Text(
                    'ISKCON Gita Connect',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    'Youth Spiritual Learning Platform',
                    style: TextStyle(color: Colors.orange.shade600),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Quote Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Daily Wisdom',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '"If one reads Bhagavad-gītā regularly and attentively, he can surpass all studies of Vedic literature"',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— A. C. Bhaktivedanta Swami Prabhupada',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Features Grid
            Text(
              'App Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            SizedBox(height: 12),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildFeatureCard('📺', 'YouTube Shorts', 'Spiritual videos'),
                _buildFeatureCard('🎓', 'Lectures', 'Deep learning'),
                _buildFeatureCard('🖼️', 'Gallery', 'Sacred images'),
                _buildFeatureCard('💰', 'Donations', 'Support mission'),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Success indicator
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Successfully Running!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Ready to add advanced features',
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
      ),
    );
  }

  Widget _buildFeatureCard(String emoji, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }
}