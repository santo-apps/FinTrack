// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentAdapter extends TypeAdapter<Investment> {
  @override
  final int typeId = 7;

  @override
  Investment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Investment(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      investedAmount: fields[10] as double?,
      quantity: fields[3] as double?,
      buyPrice: fields[4] as double?,
      currentPrice: fields[5] as double?,
      currentValue: fields[11] as double?,
      purchaseDate: fields[6] as DateTime?,
      createdAt: fields[7] as DateTime,
      currency: fields[8] as String,
      notes: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Investment obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.buyPrice)
      ..writeByte(5)
      ..write(obj.currentPrice)
      ..writeByte(6)
      ..write(obj.purchaseDate)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.currency)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.investedAmount)
      ..writeByte(11)
      ..write(obj.currentValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
