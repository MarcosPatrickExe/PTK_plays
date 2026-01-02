import 'package:flutter/material.dart';
import '../models/video_notification.dart';
import '../components/video_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<VideoNotification> _notifications = const [
    VideoNotification(
      id: '1',
      title: 'video 1',
      channelName: 'Flutter Dev',
      thumbnailUrl: 'https://i.ytimg.com/vi/EQ-5OnYjN9I/hqdefault.jpg?sqp=-oaymwEnCNACELwBSFryq4qpAxkIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB&rs=AOn4CLBpEJwoxSWZ3EHnYoQayJml6urn1g', // Invalid but placeholder
      avatarUrl: 'https://avatars.githubusercontent.com/u/14101776?s=200&v=4',
      timeAgo: Duration(hours: 2),
    ),
    VideoNotification(
      id: '2',
      title: 'video 2',
      channelName: 'DesignMaster',
      thumbnailUrl: 'https://i.ytimg.com/vi/EQ-5OnYjN9I/hqdefault.jpg?sqp=-oaymwEnCNACELwBSFryq4qpAxkIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB&rs=AOn4CLBpEJwoxSWZ3EHnYoQayJml6urn1g',
      avatarUrl: 'https://placeholder.com/avatar1.jpg',
      timeAgo: Duration(hours: 5),
    ),
    VideoNotification(
      id: '3',
      title: 'video model 4',
      channelName: 'Tech Today',
      thumbnailUrl: 'https://i.ytimg.com/vi/EQ-5OnYjN9I/hqdefault.jpg?sqp=-oaymwEnCNACELwBSFryq4qpAxkIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB&rs=AOn4CLBpEJwoxSWZ3EHnYoQayJml6urn1g',
      avatarUrl: 'https://placeholder.com/avatar2.jpg',
      timeAgo: Duration(days: 1),
    ),
    VideoNotification(
      id: '4',
      title: 'Top 10 Coding Mistakes to Avoid',
      channelName: 'Pro Coder',
      thumbnailUrl: 'https://i.ytimg.com/vi/EQ-5OnYjN9I/hqdefault.jpg?sqp=-oaymwEnCNACELwBSFryq4qpAxkIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB&rs=AOn4CLBpEJwoxSWZ3EHnYoQayJml6urn1g',
      avatarUrl: 'https://placeholder.com/avatar3.jpg',
      timeAgo: Duration(days: 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF121212),
        title: Row(
          children: [
            const Icon(Icons.play_circle_filled, color: Colors.red, size: 32),
            const SizedBox(width: 8),
            const Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          CircleAvatar(
            backgroundColor: Colors.grey[800],
            radius: 16,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return VideoCard(
            notification: notification,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Clicked: ${notification.title}')),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: 1, // Notifications tab selected
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Shorts'),
        ],
      ),
    );
  }
}
