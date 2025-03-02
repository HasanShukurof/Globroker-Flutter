import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:globroker/screens/chat_screen.dart';
import 'package:globroker/screens/profile_image_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  // Profil resmini büyük göster
  void _showProfileImage(
      BuildContext context, String imageUrl, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileImageScreen(
          imageUrl: imageUrl,
          userName: userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstifadəçilər'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Xəta: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUser?.uid)
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: GestureDetector(
                  onTap: user['photoURL'] != null
                      ? () => _showProfileImage(
                          context, user['photoURL'], user['displayName'])
                      : null,
                  child: CircleAvatar(
                    backgroundImage: user['photoURL'] != null
                        ? NetworkImage(user['photoURL'])
                        : null,
                    child: user['photoURL'] == null
                        ? Text(user['displayName'][0].toUpperCase())
                        : null,
                  ),
                ),
                title: Text(user['displayName'] ?? 'İstifadəçi'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: user['uid'],
                        receiverName: user['displayName'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
