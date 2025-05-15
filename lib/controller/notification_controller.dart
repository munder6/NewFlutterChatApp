import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart'; // فقط هذا
import 'package:http/http.dart' as http;

class NotificationController {
  static Future<void> sendPushNotificationV1({
    required String token,
    required String title,
    required String body,
  }) async {
    final accountCredentials = ServiceAccountCredentials.fromJson(
      File('assets/credentials/flutternewchatapp-2e8a14511709.json').readAsStringSync(),
    );

    const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(accountCredentials, scopes);

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/flutternewchatapp/messages:send',
    );

    final message = {
      "message": {
        "token": token,
        "notification": {
          "title": title,
          "body": body,
        },
        "android": {
          "priority": "high",
        },
        "apns": {
          "headers": {
            "apns-priority": "10"
          }
        }
      }
    };

    final response = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('✅ Notification sent successfully');
    } else {
      print('❌ Failed to send notification: ${response.body}');
    }

    client.close();
  }
}
