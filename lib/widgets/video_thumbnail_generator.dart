// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
//
// class VideoThumbnailWidget extends StatelessWidget {
//   final String videoUrl;
//   final BorderRadius borderRadius;
//   final VoidCallback onTap;
//
//   const VideoThumbnailWidget({
//     super.key,
//     required this.videoUrl,
//     required this.borderRadius,
//     required this.onTap,
//   });
//
//   Future<Uint8List?> _generateThumbnail() async {
//     return await VideoThumbnail.thumbnailData(
//       video: videoUrl,
//       imageFormat: ImageFormat.JPEG,
//       maxWidth: 300,
//       quality: 75,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<Uint8List?>(
//       future: _generateThumbnail(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState != ConnectionState.done) {
//           return Container(
//             width: MediaQuery.of(context).size.width * 0.6,
//             height: 200,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: borderRadius,
//             ),
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         if (!snapshot.hasData) {
//           return Container(
//             width: MediaQuery.of(context).size.width * 0.6,
//             height: 200,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade400,
//               borderRadius: borderRadius,
//             ),
//             child: Icon(Icons.error),
//           );
//         }
//
//         return GestureDetector(
//           onTap: onTap,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               ClipRRect(
//                 borderRadius: borderRadius,
//                 child: Image.memory(
//                   snapshot.data!,
//                   width: MediaQuery.of(context).size.width * 0.6,
//                   height: 200,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
