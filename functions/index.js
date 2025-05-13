const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const { getStorage } = require("firebase-admin/storage");

exports.deleteStoryMediaOnFirestoreDelete = functions.firestore
  .document("users/{userId}/stories/{storyId}")
  .onDelete(async (snap, context) => {
    const data = snap.data();
    const mediaUrl = data.mediaUrl;

    if (!mediaUrl) {
      console.log("⚠️ No mediaUrl found. Skipping deletion.");
      return null;
    }

    try {
      const bucket = getStorage().bucket();
      const path = decodeURIComponent(mediaUrl.split("/o/")[1].split("?")[0]);
      await bucket.file(path).delete();
      console.log("🔥 Deleted from Storage:", path);
    } catch (error) {
      console.error("❌ Failed to delete file:", error);
    }

    return null;
  });
