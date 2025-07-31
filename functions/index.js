const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendAnnouncementNotification = functions.firestore
  .document('groups/{groupId}/announcements/{announcementId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const groupId = context.params.groupId;

    if (!data) return null;

    const usersSnapshot = await admin.firestore().collection('users')
      .where('groupId', '==', groupId)
      .get();

    const tokens = [];
    usersSnapshot.forEach(doc => {
      const token = doc.data().fcmToken;
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) {
      console.log('🚫 No tokens found for group:', groupId);
      return null;
    }

    console.log(`📢 Sending announcement to ${tokens.length} users in group ${groupId}`);

    const message = {
      notification: {
        title: data.title || 'New Announcement',
        body: data.message || '',
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendMulticast(message);
    const failedTokens = [];

    response.responses.forEach((res, idx) => {
      if (!res.success) {
        failedTokens.push(tokens[idx]);
        console.error('❌ Failed sending to:', tokens[idx], res.error);
      }
    });

    if (failedTokens.length > 0) {
      console.log('⚠️ Failed tokens:', failedTokens);
    }

    return null;
  });
