import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:globroker/screens/chat_screen.dart';
import 'package:globroker/screens/users_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  // Son mesajı ve okunmamış mesaj sayısını getiren yardımcı fonksiyon
  Future<Map<String, dynamic>> _getMessageInfo(
      String userId, String currentUserId) async {
    // İki kullanıcı arasındaki son mesajı al
    final messages = await FirebaseFirestore.instance
        .collection('Messages')
        .where(Filter.and(
          Filter.or(
            Filter('senderId', isEqualTo: userId),
            Filter('senderId', isEqualTo: currentUserId),
          ),
          Filter.or(
            Filter('receiverId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: currentUserId),
          ),
        ))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    String lastMessage = '';
    String lastMessageSender = '';
    int unreadCount = 0;
    DateTime? timestamp;

    if (messages.docs.isNotEmpty) {
      final lastMessageData = messages.docs.first.data();
      // Sadece bu iki kullanıcı arasındaki mesajı kontrol et
      if ((lastMessageData['senderId'] == userId &&
              lastMessageData['receiverId'] == currentUserId) ||
          (lastMessageData['senderId'] == currentUserId &&
              lastMessageData['receiverId'] == userId)) {
        lastMessage = lastMessageData['content'] as String;
        lastMessageSender = lastMessageData['senderId'] as String;
        lastMessage = lastMessageSender == currentUserId
            ? "Siz: $lastMessage"
            : lastMessage;
        timestamp = (lastMessageData['timestamp'] as Timestamp).toDate();
      }

      // Okunmamış mesaj sayısı sorgusu aynı kalacak
      final unreadMessages = await FirebaseFirestore.instance
          .collection('Messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('senderId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      unreadCount = unreadMessages.docs.length;
    }

    return {
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'timestamp': timestamp,
    };
  }

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
            .where(Filter.or(
              Filter('senderId', isEqualTo: currentUser.uid),
              Filter('receiverId', isEqualTo: currentUser.uid),
            ))
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Xəta: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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
              if (!userSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _sortUsersByLastMessage(
                    userSnapshot.data!.docs, currentUser.uid),
                builder: (context, sortedSnapshot) {
                  if (!sortedSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ListView.builder(
                    itemCount: sortedSnapshot.data!.length,
                    itemBuilder: (context, index) {
                      final userData = sortedSnapshot.data![index].data()
                          as Map<String, dynamic>;
                      final userId = sortedSnapshot.data![index].id;

                      return FutureBuilder<Map<String, dynamic>>(
                        future: _getMessageInfo(userId, currentUser.uid),
                        builder: (context, messageSnapshot) {
                          if (!messageSnapshot.hasData ||
                              messageSnapshot.data!['timestamp'] == null) {
                            return const SizedBox.shrink();
                          }

                          final unreadCount =
                              messageSnapshot.data?['unreadCount'] ?? 0;
                          final lastMessage =
                              messageSnapshot.data?['lastMessage'] ?? '';
                          final timestamp =
                              messageSnapshot.data?['timestamp'] as DateTime?;

                          // Tarih formatını ayarla
                          String formattedTime = '';
                          if (timestamp != null) {
                            final now = DateTime.now();
                            final today =
                                DateTime(now.year, now.month, now.day);
                            final messageDate = DateTime(
                                timestamp.year, timestamp.month, timestamp.day);

                            // Bugün gönderilmiş mesajlar için sadece saat
                            if (messageDate.isAtSameMomentAs(today)) {
                              formattedTime =
                                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                            }
                            // Dün gönderilmiş mesajlar
                            else if (messageDate.isAtSameMomentAs(
                                today.subtract(const Duration(days: 1)))) {
                              formattedTime = 'Dün';
                            }
                            // Bu hafta içinde
                            else if (now.difference(messageDate).inDays < 7) {
                              final weekdays = [
                                'Bazar',
                                'Bazar ertəsi',
                                'Çərşənbə axşamı',
                                'Çərşənbə',
                                'Cümə axşamı',
                                'Cümə',
                                'Şənbə'
                              ];
                              formattedTime = weekdays[
                                  messageDate.weekday % 7]; // 0-6 arası indeks
                            }
                            // Diğer günler için tarih
                            else {
                              formattedTime =
                                  '${messageDate.day.toString().padLeft(2, '0')}.${messageDate.month.toString().padLeft(2, '0')}.${messageDate.year}';
                            }
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: userData['photoURL'] != null
                                  ? NetworkImage(userData['photoURL'])
                                  : null,
                              child: userData['photoURL'] == null
                                  ? Text(
                                      userData['displayName'][0].toUpperCase())
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      userData['displayName'] ?? 'İstifadəçi'),
                                ),
                                if (formattedTime.isNotEmpty)
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    receiverId: userId,
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

  Future<List<QueryDocumentSnapshot>> _sortUsersByLastMessage(
      List<QueryDocumentSnapshot> users, String currentUserId) async {
    Map<String, DateTime?> userTimestamps = {};
    for (var user in users) {
      final info = await _getMessageInfo(user.id, currentUserId);
      userTimestamps[user.id] = info['timestamp'] as DateTime?;
    }

    List<QueryDocumentSnapshot> sortedUsers = List.from(users);
    sortedUsers.sort((a, b) {
      final aTime = userTimestamps[a.id];
      final bTime = userTimestamps[b.id];
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return sortedUsers;
  }
}
