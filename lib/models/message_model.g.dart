// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 0;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String,
      senderId: fields[1] as String,
      receiverId: fields[2] as String,
      content: fields[3] as String,
      contentType: fields[4] as String,
      isRead: fields[5] as bool,
      timestamp: fields[6] as DateTime,
      receiverName: fields[7] as String,
      receiverUsername: fields[8] as String,
      replyToStoryUrl: fields[9] as String?,
      replyToStoryType: fields[10] as String?,
      replyToStoryId: fields[11] as String?,
      localPath: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.receiverId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.contentType)
      ..writeByte(5)
      ..write(obj.isRead)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.receiverName)
      ..writeByte(8)
      ..write(obj.receiverUsername)
      ..writeByte(9)
      ..write(obj.replyToStoryUrl)
      ..writeByte(10)
      ..write(obj.replyToStoryType)
      ..writeByte(11)
      ..write(obj.replyToStoryId)
      ..writeByte(12)
      ..write(obj.localPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
