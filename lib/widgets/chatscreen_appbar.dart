// import 'package:flutter/material.dart';
//
//
// class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final String name;
//   final String receiverId;
//
//   const ChatAppBar({
//     super.key,
//     required this.name,
//     required this.receiverId,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<UserEntity>(
//         stream: AuthCubit.get(context).getUserById(receiverId),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Loader();
//           }
//           UserEntity userdata = snapshot.data!;
//           return AppBar(
//             elevation: 0,
//             leading:  IconButton(onPressed: () {
//               Navigator.pop(context);
//             },
//                 icon: const Icon(Icons.arrow_back_ios)
//             ),
//             clipBehavior: Clip.antiAliasWithSaveLayer,
//             shadowColor: AppColorss.iconsColors,
//             iconTheme:  IconThemeData(color: AppColorss.iconsColors),
//             backgroundColor: AppColorss.primaryColor,
//             centerTitle: false,
//             titleSpacing: 0,
//             title: InkWell(
//               onTap: () {
//                 navigateTo(
//                   context,
//                   Routes.senderUserProfileRoute,
//                   arguments: userdata,
//                 );
//               },
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 // crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   MyCachedNetImage(
//                     imageUrl: userdata.profilePic,
//                     radius: 19,
//                   ),
//                   const SizedBox(width: 5),
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(name , style:  TextStyle(
//                           fontWeight: FontWeight.normal,
//                           fontFamily: 'Arabic',
//                           fontSize: 17,
//                           height: 1.1,
//                           color: AppColorss.textColor1
//                       ),),
//                       Row(
//                         children: [
//                           Text(
//                             userdata.isOnline ? 'Online' : userdata.lastSeen.lastSeen,
//                             style: TextStyle(
//                               fontSize: 9,
//                               fontWeight: FontWeight.normal,
//                               fontFamily: 'Arabic',
//                               color: AppColorss.textColor1,
//                             ),
//                           ),
//                           const SizedBox(width: 3),
//                           Align(
//                             alignment: Alignment.center,
//                             child: CircleAvatar(
//                               radius: 3,
//                               backgroundColor: userdata.isOnline ? Colors.green : Colors.transparent,
//                             ),
//                           )
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               IconButton(
//                 color: AppColorss.iconsColors,
//                 onPressed: () {},
//                 splashRadius: 20,
//                 icon: const Icon(FluentIcons.call_28_regular, size: 28,),
//               ),
//               IconButton(
//                 color: AppColorss.iconsColors,
//                 onPressed: () {},
//                 splashRadius: 20,
//                 icon: const Icon(FluentIcons.video_28_regular, size: 28,),
//               ),
//             ],
//           );
//         });
//   }
//
//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }