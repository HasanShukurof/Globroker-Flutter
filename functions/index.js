/* eslint-disable */
const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();

// HTTP endpoint
exports.helloWorld = onRequest((request, response) => {
    console.log('Hello logs!');
    response.json({ message: 'Hello from Firebase!' });
});

// User created trigger
exports.onUserCreated = onDocumentCreated('users/{userId}', (event) => {
    const newUser = event.data.data();
    console.log('New user created:', newUser);
});

// Message notification trigger
exports.sendNotification = onDocumentCreated('Messages/{messageId}', async (event) => {
    const firestore = admin.firestore();

    console.log('YENİ MESAJ TETİKLENDİ:', event.params.messageId);
    const message = event.data.data();
    console.log('MESAJ DATA:', message);

    try {
        // Gönderici bilgilerini al
        const senderDoc = await firestore
            .collection('Users')
            .doc(message.senderId)
            .get();

        console.log('GÖNDEREN BİLGİLERİ:', senderDoc.exists ? senderDoc.data() : 'Bulunamadı');
        const senderName = senderDoc.exists ? senderDoc.data().displayName : 'Birisi';

        // Alıcı bilgilerini al
        const receiverDoc = await firestore
            .collection('Users')
            .doc(message.receiverId)
            .get();

        console.log('ALICI BİLGİLERİ:', receiverDoc.exists ? receiverDoc.data() : 'Bulunamadı');

        if (!receiverDoc.exists) {
            console.error('HATA: Alıcı bulunamadı');
            return;
        }

        // FCM token kontrolü
        const receiverData = receiverDoc.data();
        console.log('ALICI FCM TOKEN:', receiverData.fcmToken);

        if (!receiverData.fcmToken) {
            console.error('HATA: FCM token bulunamadı');

            // Token yoksa, kullanıcı koleksiyonundaki tüm FCM tokenları listele
            const usersSnapshot = await firestore.collection('Users').get();
            console.log('TÜM KULLANICILAR VE FCM TOKENLARI:');
            usersSnapshot.docs.forEach(doc => {
                console.log(`Kullanıcı ID: ${doc.id}, FCM Token: ${doc.data().fcmToken || 'Yok'}`);
            });

            return;
        }

        const notification = {
            token: receiverData.fcmToken,
            notification: {
                title: 'Yeni mesaj',
                body: `${senderName}: ${message.content}`,
            },
            android: {
                notification: {
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                    channelId: 'high_importance_channel'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1
                    }
                }
            },
            data: {
                senderId: message.senderId,
                senderName: senderName,
                type: 'message'
            }
        };

        console.log('BİLDİRİM GÖNDERİLİYOR:', notification);
        const response = await admin.messaging().send(notification);
        console.log('BİLDİRİM BAŞARILI:', response);

    } catch (error) {
        console.error('BİLDİRİM HATASI:', error.stack);
    }
});