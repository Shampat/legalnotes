// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 2;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      clientKey: fields[0] as int,
      amount: fields[1] as double,
      description: fields[2] as String,
      dueDate: fields[3] as DateTime,
      paidDate: fields[4] as DateTime?,
      taxApplicable: fields[5] as bool,
      taxRate: fields[6] as double,
      modeOfPayment: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.clientKey)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.paidDate)
      ..writeByte(5)
      ..write(obj.taxApplicable)
      ..writeByte(6)
      ..write(obj.taxRate)
      ..writeByte(7)
      ..write(obj.modeOfPayment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
