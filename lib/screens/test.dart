// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
// import '../models/message_model.dart';
//
// class MessageCard extends StatelessWidget {
//   final MessageModel message;
//   final MessageModel? previousMessage;
//   final MessageModel? nextMessage;
//   final bool isSender;
//
//   MessageCard({
//     super.key,
//     required this.message,
//     this.previousMessage,
//     this.nextMessage,
//     required this.isSender,
//   });
//
//   final AudioPlayer _audioPlayer = AudioPlayer();
//
//   @override
//   Widget build(BuildContext context) {
//     bool isFirstInGroup = previousMessage == null ||
//         previousMessage!.senderId != message.senderId ||
//         _hasTimeGap(previousMessage!.timestamp, message.timestamp);
//
//     bool isLastInGroup = nextMessage == null ||
//         nextMessage!.senderId != message.senderId ||
//         _hasTimeGap(message.timestamp, nextMessage!.timestamp);
//
//     BorderRadiusGeometry borderRadius;
//     if (isFirstInGroup && isLastInGroup) {
//       borderRadius = BorderRadius.circular(50);
//     } else if (isFirstInGroup) {
//       borderRadius = BorderRadius.only(
//         topLeft: isSender ? const Radius.circular(20) : const Radius.circular(5),
//         topRight: isSender ? const Radius.circular(5) : const Radius.circular(20),
//         bottomLeft: isSender ? const Radius.circular(20) : const Radius.circular(20),
//         bottomRight: isSender ? const Radius.circular(20) : const Radius.circular(20),
//       );
//     } else if (isLastInGroup) {
//       borderRadius = BorderRadius.only(
//         topLeft: isSender ? const Radius.circular(20) : const Radius.circular(20),
//         topRight: isSender ? const Radius.circular(20) : const Radius.circular(20),
//         bottomLeft: isSender ? const Radius.circular(20) : const Radius.circular(5),
//         bottomRight: isSender ? const Radius.circular(5) : const Radius.circular(20),
//       );
//     } else {
//       borderRadius = BorderRadius.only(
//         topLeft: isSender ? const Radius.circular(20) : const Radius.circular(5),
//         topRight: isSender ? const Radius.circular(5) : const Radius.circular(20),
//         bottomLeft: isSender ? const Radius.circular(20) : const Radius.circular(5),
//         bottomRight: isSender ? const Radius.circular(5) : const Radius.circular(20),
//       );
//     }
//
//     return Padding(
//       padding: EdgeInsets.only(
//         top: 1,
//         left: 15,
//         right: 15,
//       ),
//       child: Align(
//         alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
//         child: message.contentType == "image"
//             ? ClipRRect(
//           borderRadius: BorderRadius.circular(10),
//           child: Image.network(
//             message.content,
//             width: 200,
//             height: 200,
//             fit: BoxFit.cover,
//           ),
//         )
//             : message.contentType == "audio"
//             ? Container(
//           decoration: BoxDecoration(
//             color: isSender ? Colors.blueAccent : Colors.grey[300],
//             borderRadius: borderRadius,
//           ),
//           padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//           constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
//           child: Row(
//             children: [
//               Icon(Icons.headset, color: isSender ? Colors.white : Colors.black),
//               SizedBox(width: 8),
//               Text("Voice Message", style: TextStyle(color: isSender ? Colors.white : Colors.black)),
//               Spacer(),
//               IconButton(
//                 icon: Icon(Icons.play_arrow, color: isSender ? Colors.white : Colors.black),
//                 onPressed: () async {
//                   // تشغيل الصوت باستخدام الرابط من Firebase Storage
//                   await _audioPlayer.setSourceUrl(message.content); // نمرر الرابط مباشرة
//                   await _audioPlayer.resume(); // بدء التشغيل
//                 },
//               ),
//             ],
//           ),
//         )
//             : Container(
//           decoration: BoxDecoration(
//             color: isSender ? Colors.blueAccent : Colors.grey[300],
//             borderRadius: borderRadius,
//           ),
//           padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//           constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
//           child: Text(
//             message.content,
//             style: TextStyle(color: isSender ? Colors.white : Colors.black),
//           ),
//         ),
//       ),
//     );
//   }
//
//   bool _hasTimeGap(Timestamp prevTime, Timestamp currentTime) {
//     DateTime prevDateTime = prevTime.toDate();
//     DateTime currentDateTime = currentTime.toDate();
//     return currentDateTime.difference(prevDateTime).inMinutes > 5; // أكثر من 5 دقائق يعني انفصال
//   }
// }
