// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 0;

  @override
  Client read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Client(
      firstName: fields[13] as String,
      lastName: fields[14] as String,
      phone: fields[1] as String,
      email: fields[2] as String,
      address: fields[3] as String,
      createdAt: fields[4] as DateTime?,
      totalInvoiced: fields[5] as double,
      clientStatus: fields[6] as String,
      matterDescription: fields[7] as String,
      consultationDate: fields[8] as DateTime?,
      retainerSigned: fields[9] as bool,
      nonEngagementLetterSent: fields[10] as bool,
      dateOfBirth: fields[11] as String?,
      companyName: fields[12] as String?,
      isArchived: fields[15] as bool,
      invoiceTaxRate: fields[16] as double,
    )..name = fields[0] as String;
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.totalInvoiced)
      ..writeByte(6)
      ..write(obj.clientStatus)
      ..writeByte(7)
      ..write(obj.matterDescription)
      ..writeByte(8)
      ..write(obj.consultationDate)
      ..writeByte(9)
      ..write(obj.retainerSigned)
      ..writeByte(10)
      ..write(obj.nonEngagementLetterSent)
      ..writeByte(11)
      ..write(obj.dateOfBirth)
      ..writeByte(12)
      ..write(obj.companyName)
      ..writeByte(13)
      ..write(obj.firstName)
      ..writeByte(14)
      ..write(obj.lastName)
      ..writeByte(15)
      ..write(obj.isArchived)
      ..writeByte(16)
      ..write(obj.invoiceTaxRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
