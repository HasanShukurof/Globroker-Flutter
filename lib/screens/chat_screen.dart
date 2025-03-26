import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:globroker/models/message.dart';
import 'package:globroker/services/notification_service.dart';
import 'package:globroker/screens/profile_image_screen.dart';

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
  String? _receiverPhotoURL;

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

  // Alıcının profil bilgilerini getir
  Future<void> _getReceiverInfo() async {
    try {
      final receiverDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.receiverId)
          .get();

      if (receiverDoc.exists) {
        setState(() {
          _receiverPhotoURL = receiverDoc.data()?['photoURL'];
        });
      }
    } catch (e) {
      print('Alıcı bilgileri alınırken hata: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında mesajları okundu olarak işaretle
    _markMessagesAsRead();
    // Alıcının profil bilgilerini getir
    _getReceiverInfo();
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

  // Profil resmini büyük göster
  void _showProfileImage() {
    if (_receiverPhotoURL == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileImageScreen(
          imageUrl: _receiverPhotoURL!,
          userName: widget.receiverName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showProfileImage,
          child: Row(
            children: [
              _receiverPhotoURL != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(_receiverPhotoURL!),
                      radius: 16,
                    )
                  : const CircleAvatar(
                      child: Icon(Icons.person, size: 16),
                      radius: 16,
                    ),
              const SizedBox(width: 8),
              Text(widget.receiverName),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Messages')
                    .where(Filter.and(
                      Filter.or(
                        Filter('senderId', isEqualTo: _currentUser.uid),
                        Filter('senderId', isEqualTo: widget.receiverId),
                      ),
                      Filter.or(
                        Filter('receiverId', isEqualTo: _currentUser.uid),
                        Filter('receiverId', isEqualTo: widget.receiverId),
                      ),
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

                  final messages = snapshot.data!.docs
                      .map((doc) =>
                          Message.fromMap(doc.data() as Map<String, dynamic>))
                      .where((message) =>
                          (message.senderId == _currentUser.uid &&
                              message.receiverId == widget.receiverId) ||
                          (message.senderId == widget.receiverId &&
                              message.receiverId == _currentUser.uid))
                      .toList();

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == _currentUser.uid;

                      // Mesaj tarihini formatlama
                      final messageTime = message.timestamp;
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final messageDate = DateTime(
                          messageTime.year, messageTime.month, messageTime.day);

                      String formattedTime = '';

                      // Bugün gönderilmiş mesajlar için sadece saat
                      if (messageDate.isAtSameMomentAs(today)) {
                        formattedTime =
                            '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
                      }
                      // Dün gönderilmiş mesajlar
                      else if (messageDate.isAtSameMomentAs(
                          today.subtract(const Duration(days: 1)))) {
                        formattedTime =
                            'Dün ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
                      }
                      // Diğer günler için tarih ve saat
                      else {
                        formattedTime =
                            '${messageTime.day.toString().padLeft(2, '0')}.${messageTime.month.toString().padLeft(2, '0')}.${messageTime.year} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
                      }

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
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  top: 8.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom > 0
                      ? 8.0
                      : MediaQuery.of(context).padding.bottom + 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Mesaj yazın...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        keyboardType: TextInputType.text,
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
