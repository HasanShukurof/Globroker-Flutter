import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:globroker/models/message.dart';
import 'package:globroker/services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  // Mesajları okundu olarak işaretle
  void _markMessagesAsRead() async {
    final messagesQuery = await FirebaseFirestore.instance
        .collection('Messages')
        .where('senderId', isEqualTo: widget.receiverId)
        .where('receiverId', isEqualTo: _currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messagesQuery.docs) {
      await doc.reference.update({'isRead': true});
    }

    // Badge sayısını güncelle
    final notificationService = NotificationService();
    await notificationService.updateBadgeCount(_currentUser.uid);
  }

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında mesajları okundu olarak işaretle
    _markMessagesAsRead();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      print('MESAJ: Mesaj gönderiliyor...');

      // Mesaj gönderirken bir kilitleme mekanizması ekleyelim
      final messageText = _messageController.text.trim();
      _messageController
          .clear(); // Hemen temizle ki kullanıcı tekrar gönderemesin

      final message = Message(
        senderId: _currentUser.uid,
        receiverId: widget.receiverId,
        content: messageText,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('Messages')
          .add(message.toMap());

      print('MESAJ: Mesaj başarıyla gönderildi');
      print('MESAJ DATA: ${message.toMap()}');
    } catch (e) {
      print('MESAJ HATASI: $e');
      // Hata durumunda kullanıcıya bildir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj göndərilmədi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Messages')
                  .where('senderId',
                      whereIn: [_currentUser.uid, widget.receiverId])
                  .where('receiverId',
                      whereIn: [_currentUser.uid, widget.receiverId])
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Xəta: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs
                    .map((doc) =>
                        Message.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUser.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Mesaj yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    keyboardType: TextInputType.text,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
