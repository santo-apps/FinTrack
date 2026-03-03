// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 9;

  @override
  Loan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      id: fields[0] as String,
      lender: fields[1] as String,
      borrowedAmount: fields[2] as double,
      interestRate: fields[3] as double,
      tenureMonths: fields[4] as int,
      monthlyEmi: fields[5] as double,
      startDate: fields[6] as DateTime,
      endDate: fields[7] as DateTime,
      emiDate: fields[8] as int,
      paidAmount: fields[9] as double,
      createdAt: fields[10] as DateTime,
      currency: fields[11] as String,
      notes: fields[12] as String?,
      accountId: fields[13] as String?,
      lastPaymentDate: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lender)
      ..writeByte(2)
      ..write(obj.borrowedAmount)
      ..writeByte(3)
      ..write(obj.interestRate)
      ..writeByte(4)
      ..write(obj.tenureMonths)
      ..writeByte(5)
      ..write(obj.monthlyEmi)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.emiDate)
      ..writeByte(9)
      ..write(obj.paidAmount)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.currency)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.accountId)
      ..writeByte(14)
      ..write(obj.lastPaymentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
