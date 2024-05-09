// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_duration_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoDurationRecordAdapter extends TypeAdapter<VideoDurationRecord> {
  @override
  final int typeId = 1;

  @override
  VideoDurationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    
    return VideoDurationRecord()
      ..videoPosition =  fields[0] as Duration?;
      
  }

  @override
  void write(BinaryWriter writer, VideoDurationRecord obj) {
    
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.videoPosition);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoDurationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
