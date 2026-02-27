// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtAdapter extends TypeAdapter<Debt> {
  @override
  final int typeId = 5;

  @override
  Debt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Debt(
      id: fields[0] as String,
      loanName: fields[1] as String,
      principalAmount: fields[2] as double,
      interestRate: fields[3] as double,
      tenureMonths: fields[4] as int,
      monthlyEmi: fields[5] as double,
      remainingBalance: fields[6] as double,
      startDate: fields[7] as DateTime,
      endDate: fields[8] as DateTime?,
      createdAt: fields[9] as DateTime,
      payments: (fields[10] as List).cast<EMIPayment>(),
      currency: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Debt obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.loanName)
      ..writeByte(2)
      ..write(obj.principalAmount)
      ..writeByte(3)
      ..write(obj.interestRate)
      ..writeByte(4)
      ..write(obj.tenureMonths)
      ..writeByte(5)
      ..write(obj.monthlyEmi)
      ..writeByte(6)
      ..write(obj.remainingBalance)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.payments)
      ..writeByte(11)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EMIPaymentAdapter extends TypeAdapter<EMIPayment> {
  @override
  final int typeId = 6;

  @override
  EMIPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EMIPayment(
      id: fields[0] as String,
      monthNumber: fields[1] as int,
      principalAmount: fields[2] as double,
      interestAmount: fields[3] as double,
      totalAmount: fields[4] as double,
      remainingBalance: fields[5] as double,
      dueDate: fields[6] as DateTime,
      isPaid: fields[7] as bool,
      paidDate: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EMIPayment obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.monthNumber)
      ..writeByte(2)
      ..write(obj.principalAmount)
      ..writeByte(3)
      ..write(obj.interestAmount)
      ..writeByte(4)
      ..write(obj.totalAmount)
      ..writeByte(5)
      ..write(obj.remainingBalance)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.isPaid)
      ..writeByte(8)
      ..write(obj.paidDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EMIPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
