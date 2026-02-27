// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      paymentMethod: fields[4] as String,
      date: fields[5] as DateTime,
      notes: fields[6] as String?,
      tags: (fields[7] as List).cast<String>(),
      receiptImagePath: fields[8] as String?,
      isRecurring: fields[9] as bool,
      recurringFrequency: fields[10] as String?,
      currency: fields[11] as String,
      accountId: fields[12] as String?,
      transactionType: fields[13] as String?,
      destinationAccountId: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.paymentMethod)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.receiptImagePath)
      ..writeByte(9)
      ..write(obj.isRecurring)
      ..writeByte(10)
      ..write(obj.recurringFrequency)
      ..writeByte(11)
      ..write(obj.currency)
      ..writeByte(12)
      ..write(obj.accountId)
      ..writeByte(13)
      ..write(obj.transactionType)
      ..writeByte(14)
      ..write(obj.destinationAccountId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
