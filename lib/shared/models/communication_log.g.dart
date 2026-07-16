// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'communication_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommunicationLogAdapter extends TypeAdapter<CommunicationLog> {
  @override
  final int typeId = 4;

  @override
  CommunicationLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommunicationLog(
      clientKey: fields[0] as int,
      note: fields[1] as String,
      channel: fields[3] as String,
      status: fields[4] as String,
      createdAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CommunicationLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.clientKey)
      ..writeByte(1)
      ..write(obj.note)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.channel)
      ..writeByte(4)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunicationLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
