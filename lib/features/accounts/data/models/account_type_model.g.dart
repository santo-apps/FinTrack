// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_type_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountTypeModelAdapter extends TypeAdapter<AccountTypeModel> {
  @override
  final int typeId = 13;

  @override
  AccountTypeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountTypeModel(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] as String?,
      color: fields[3] as String?,
      isDefault: fields[4] as bool,
      order: fields[5] as int,
      createdAt: fields[6] as DateTime,
      isActive: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AccountTypeModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.isDefault)
      ..writeByte(5)
      ..write(obj.order)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
