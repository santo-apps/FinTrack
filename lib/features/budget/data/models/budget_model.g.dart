// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 2;

  @override
  Budget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Budget(
      id: fields[0] as String,
      monthlyIncome: fields[1] as double,
      categoryLimits: (fields[2] as Map).cast<String, double>(),
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      currency: fields[5] as String,
      enableAlerts: fields[6] as bool,
      month: fields[7] as int,
      year: fields[8] as int,
      recurrenceType: fields[9] as String?,
      endDate: fields[10] as DateTime?,
      baselineId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.monthlyIncome)
      ..writeByte(2)
      ..write(obj.categoryLimits)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.enableAlerts)
      ..writeByte(7)
      ..write(obj.month)
      ..writeByte(8)
      ..write(obj.year)
      ..writeByte(9)
      ..write(obj.recurrenceType)
      ..writeByte(10)
      ..write(obj.endDate)
      ..writeByte(11)
      ..write(obj.baselineId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
