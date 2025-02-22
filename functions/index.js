/* eslint-disable */
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// HTTP endpoint example
exports.helloWorld = functions.https.onRequest((request, response) => {
    console.log('Hello logs!');
    response.json({ message: 'Hello from Firebase!' });
});

// Firestore trigger example
exports.onUserCreated = functions.firestore
    .document('users/{userId}')
    .onCreate(async (snap, context) => {
        const newUser = snap.data();
        console.log('New user created:', newUser);
    });

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
        const token = receiverData && receiverData.fcmToken;

        if (!token) return;

        // Gönderici bilgilerini al
        const senderDoc = await admin.firestore()
            .collection('Users')
            .doc(message.senderId)
            .get();

        const senderData = senderDoc.data();
        const senderName = senderData && senderData.displayName || 'Birisi';

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