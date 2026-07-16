// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hearing.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HearingAdapter extends TypeAdapter<Hearing> {
  @override
  final int typeId = 1;

  @override
  Hearing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Hearing(
      caseTitle: fields[0] as String,
      clientKey: fields[1] as int,
      dateTime: fields[2] as DateTime,
      court: fields[3] as String,
      notes: fields[4] as String,
      opposingParty: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Hearing obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.caseTitle)
      ..writeByte(1)
      ..write(obj.clientKey)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.court)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.opposingParty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HearingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
