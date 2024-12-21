const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendConnectionRequestNotification = functions.https.onRequest(async (req, res) => {
    const { token, notification, data } = req.body;
    
    try {
        await admin.messaging().send({
            token: token,
            notification: notification,
            data: data
        });
        res.status(200).send('Notification sent successfully');
    } catch (error) {
        res.status(500).send('Error sending notification');
    }
}); 