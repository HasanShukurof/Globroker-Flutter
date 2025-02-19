import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:globroker/screens/chat_screen.dart';
import 'package:globroker/screens/users_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Söhbətlər'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Messages')
            .where('senderId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Xəta: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Benzersiz kullanıcı ID'lerini topla
          final Set<String> chatUserIds = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['senderId'] == currentUser.uid) {
              chatUserIds.add(data['receiverId'] as String);
            } else {
              chatUserIds.add(data['senderId'] as String);
            }
          }

          if (chatUserIds.isEmpty) {
            return const Center(
              child: Text('Hələ heç bir söhbətiniz yoxdur'),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .where(FieldPath.documentId, whereIn: chatUserIds.toList())
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return Center(child: Text('Xəta: ${userSnapshot.error}'));
              }

              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = userSnapshot.data!.docs;

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['photoURL'] != null
                          ? NetworkImage(userData['photoURL'])
                          : null,
                      child: userData['photoURL'] == null
                          ? Text(userData['displayName'][0].toUpperCase())
                          : null,
                    ),
                    title: Text(userData['displayName'] ?? 'İstifadəçi'),
                    subtitle: const Text(
                        'Son mesaj...'), // İsteğe bağlı: son mesajı göster
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: users[index].id,
                            receiverName: userData['displayName'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UsersScreen()),
          );
        },
        backgroundColor: const Color(0xFF5C6BC0),
        child: const Icon(Icons.message),
      ),
    );
  }
}
