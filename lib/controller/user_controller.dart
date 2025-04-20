import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';
import 'dart:async';


class UserController extends GetxController with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final box = GetStorage();
  late DatabaseReference presenceRef;

  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxBool isOnline = true.obs;
  Timer? typingTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    fetchCurrentUser();
    setupRealtimePresence();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = box.read('user_id');
    if (uid == null) return;

    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _setOnlineStatus(false);
    }
  }

  void _setOnlineStatus(bool isOnline) async {
    final uid = box.read('user_id');
    if (uid == null) return;

    final ref = FirebaseDatabase.instance.ref("status/$uid");
    await ref.set({
      "isOnline": isOnline,
      "lastSeen": ServerValue.timestamp,
    });

    // عشان ما نظل معتمدين عـ onDisconnect بس
    if (isOnline) {
      ref.onDisconnect().set({
        "isOnline": false,
        "lastSeen": ServerValue.timestamp,
      });
    }
  }

  Future<void> fetchCurrentUser() async {
    String? uid = box.read('user_id');
    if (uid == null) return;

    DocumentSnapshot snapshot =
    await _firestore.collection('users').doc(uid).get();

    if (snapshot.exists) {
      currentUser.value =
          UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
    }
  }

  Future<void> updateUserOnlineStatus(bool online) async {
    final uid = box.read('user_id');
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'isOnline': online,
      'lastSeen': Timestamp.now(),
    });

    isOnline.value = online;

    if (currentUser.value != null) {
      currentUser.value = UserModel(
        id: currentUser.value!.id,
        fullName: currentUser.value!.fullName,
        username: currentUser.value!.username,
        email: currentUser.value!.email,
        profileImage: currentUser.value!.profileImage,
        isOnline: online,
        lastSeen: DateTime.now(),
        showOnlineStatus: currentUser.value!.showOnlineStatus,
        createdAt: currentUser.value!.createdAt,
        isTyping: false,
      );
    }
  }

  void setTypingStatus(bool isTyping) {
    final uid = box.read('user_id');
    if (uid == null) return;

    _firestore.collection('users').doc(uid).update({
      'isTyping': isTyping,
    });

    if (isTyping) {
      typingTimer?.cancel();
      typingTimer = Timer(Duration(seconds: 2), () {
        setTypingStatus(false);
      });
    }
  }

  Future<void> toggleShowOnlineStatus(bool value) async {
    final uid = box.read('user_id');
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'showOnlineStatus': value,
    });

    if (currentUser.value != null) {
      currentUser.value = UserModel(
        id: currentUser.value!.id,
        fullName: currentUser.value!.fullName,
        username: currentUser.value!.username,
        email: currentUser.value!.email,
        profileImage: currentUser.value!.profileImage,
        isOnline: currentUser.value!.isOnline,
        lastSeen: currentUser.value!.lastSeen,
        showOnlineStatus: value,
        createdAt: currentUser.value!.createdAt,
        isTyping: currentUser.value!.isTyping,
      );
    }
  }
  void setupRealtimePresence() async {
    String? uid = box.read('user_id');
    if (uid == null) return;

    presenceRef = FirebaseDatabase.instance.ref("status/$uid");

    // إعداد onDisconnect
    await presenceRef.onDisconnect().set({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });

    // عند تشغيل التطبيق، نعتبر المستخدم أونلاين
    await presenceRef.set({
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
    });

    print("✅ Realtime Presence setup complete for user: $uid");
  }
}
