// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receivable_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceivableAdapter extends TypeAdapter<Receivable> {
  @override
  final int typeId = 14;

  @override
  Receivable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final amount = fields[2] as double;
    final isReceived = fields[5] as bool;
    return Receivable(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: amount,
      dueDate: fields[3] as DateTime,
      currency: fields[4] as String,
      isReceived: isReceived,
      receivedDate: fields[6] as DateTime?,
      remindBeforeDays: fields[7] as int,
      notes: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      accountId: fields[10] as String?,
      isRecurring: fields[11] as bool? ?? false,
      recurringEndDate: fields[12] as DateTime?,
      recurrenceGroupId: fields[13] as String?,
      receivedAmount: (fields[14] as double?) ?? (isReceived ? amount : 0),
    );
  }

  @override
  void write(BinaryWriter writer, Receivable obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.isReceived)
      ..writeByte(6)
      ..write(obj.receivedDate)
      ..writeByte(7)
      ..write(obj.remindBeforeDays)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.accountId)
      ..writeByte(11)
      ..write(obj.isRecurring)
      ..writeByte(12)
      ..write(obj.recurringEndDate)
      ..writeByte(13)
      ..write(obj.recurrenceGroupId)
      ..writeByte(14)
      ..write(obj.receivedAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
