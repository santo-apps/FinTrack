// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentAccountAdapter extends TypeAdapter<PaymentAccount> {
  @override
  final int typeId = 11;

  @override
  PaymentAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentAccount(
      id: fields[0] as String,
      name: fields[1] as String,
      accountType: fields[2] as String,
      accountNumber: fields[3] as String?,
      bankName: fields[4] as String?,
      balance: fields[5] as double,
      currency: fields[6] as String,
      color: fields[7] as String?,
      icon: fields[8] as String?,
      isDefault: fields[9] as bool,
      isActive: fields[10] as bool,
      createdAt: fields[11] as DateTime,
      lastUpdated: fields[12] as DateTime?,
      notes: fields[13] as String?,
      creditLimit: fields[14] as double?,
      expiryDate: fields[15] as DateTime?,
      cardNetwork: fields[16] as String?,
      linkedAccountId: fields[17] as String?,
      billingCycleDay: fields[18] as int?,
      dueDate: fields[19] as DateTime?,
      statementDate: fields[20] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentAccount obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.accountType)
      ..writeByte(3)
      ..write(obj.accountNumber)
      ..writeByte(4)
      ..write(obj.bankName)
      ..writeByte(5)
      ..write(obj.balance)
      ..writeByte(6)
      ..write(obj.currency)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.icon)
      ..writeByte(9)
      ..write(obj.isDefault)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.lastUpdated)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.creditLimit)
      ..writeByte(15)
      ..write(obj.expiryDate)
      ..writeByte(16)
      ..write(obj.cardNetwork)
      ..writeByte(17)
      ..write(obj.linkedAccountId)
      ..writeByte(18)
      ..write(obj.billingCycleDay)
      ..writeByte(19)
      ..write(obj.dueDate)
      ..writeByte(20)
      ..write(obj.statementDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
