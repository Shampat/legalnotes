// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hearing.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OpposingPartyAdapter extends TypeAdapter<OpposingParty> {
  @override
  final int typeId = 5;

  @override
  OpposingParty read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OpposingParty(
      name: fields[0] as String,
      phone: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OpposingParty obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpposingPartyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      opposingPartiesList: (fields[6] as List?)?.cast<OpposingParty>(),
      outcomeStatus: fields[7] as String?,
      outcomeNote: fields[8] as String?,
      nextAction: fields[9] as String?,
      nextActionDueDate: fields[10] as DateTime?,
      linkedFromHearingKey: fields[11] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Hearing obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.opposingParty)
      ..writeByte(6)
      ..write(obj.opposingPartiesList)
      ..writeByte(7)
      ..write(obj.outcomeStatus)
      ..writeByte(8)
      ..write(obj.outcomeNote)
      ..writeByte(9)
      ..write(obj.nextAction)
      ..writeByte(10)
      ..write(obj.nextActionDueDate)
      ..writeByte(11)
      ..write(obj.linkedFromHearingKey);
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
