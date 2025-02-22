import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

exports.sendNotification = functions.firestore
    .document('Messages/{messageId}')
    .onCreate(async (snap, context) => {
        const message = snap.data();

        // Alıcının token'ını al
        const receiverDoc = await admin.firestore()
            .collection('Users')
            .doc(message.receiverId)
            .get();

        const receiverData = receiverDoc.data();
        const token = receiverData?.fcmToken;

        if (!token) return;

        // Gönderici bilgilerini al
        const senderDoc = await admin.firestore()
            .collection('Users')
            .doc(message.senderId)
            .get();

        const senderData = senderDoc.data();
        const senderName = senderData?.displayName || 'Birisi';

        // Bildirimi gönder
        const payload = {
            notification: {
                title: 'Yeni mesaj',
                body: `${senderName}: ${message.content}`,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
            data: {
                senderId: message.senderId,
                senderName: senderName,
                type: 'message',
            }
        };

        try {
            await admin.messaging().sendToDevice(token, payload);
        } catch (error) {
            console.error('Error sending notification:', error);
        }
    }); 