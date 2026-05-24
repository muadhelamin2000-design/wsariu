// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KnowledgeEntryAdapter extends TypeAdapter<KnowledgeEntry> {
  @override
  final int typeId = 1;

  @override
  KnowledgeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KnowledgeEntry(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as KnowledgeType,
      contentText: fields[3] as String,
      sourceName: fields[4] as String?,
      detail: fields[5] as String?,
      benefits: (fields[6] as List).cast<String>(),
      tags: (fields[7] as List).cast<String>(),
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, KnowledgeEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.contentText)
      ..writeByte(4)
      ..write(obj.sourceName)
      ..writeByte(5)
      ..write(obj.detail)
      ..writeByte(6)
      ..write(obj.benefits)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NodeAdapter extends TypeAdapter<Node> {
  @override
  final int typeId = 3;

  @override
  Node read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Node(
      id: fields[0] as String,
      userId: fields[1] as String,
      categoryIds: (fields[2] as List).cast<String>(),
      contentText: fields[3] as String,
      sourceName: fields[4] as String?,
      detail: fields[5] as String?,
      benefits: (fields[6] as List).cast<String>(),
      tags: (fields[7] as List).cast<String>(),
      linkedNodeIds: (fields[8] as List).cast<String>(),
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Node obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.categoryIds)
      ..writeByte(3)
      ..write(obj.contentText)
      ..writeByte(4)
      ..write(obj.sourceName)
      ..writeByte(5)
      ..write(obj.detail)
      ..writeByte(6)
      ..write(obj.benefits)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.linkedNodeIds)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 0;

  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(
      id: fields[0] as String,
      name: fields[1] as String,
      userId: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class KnowledgeTypeAdapter extends TypeAdapter<KnowledgeType> {
  @override
  final int typeId = 2;

  @override
  KnowledgeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return KnowledgeType.quran;
      case 1:
        return KnowledgeType.hadith;
      case 2:
        return KnowledgeType.book;
      default:
        return KnowledgeType.quran;
    }
  }

  @override
  void write(BinaryWriter writer, KnowledgeType obj) {
    switch (obj) {
      case KnowledgeType.quran:
        writer.writeByte(0);
        break;
      case KnowledgeType.hadith:
        writer.writeByte(1);
        break;
      case KnowledgeType.book:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
