// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_download_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoDownloadRecordAdapter extends TypeAdapter<VideoDownloadRecord> {
  @override
  final int typeId = 2;

  @override
  VideoDownloadRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return VideoDownloadRecord()
      ..rangeStart =  fields[0] as int?
      ..fileSize =  fields[1] as double?
      ..rate = fields[2] as double?
      ..videoUrl = fields[3] as String?
      ..audioUrl = fields[4] as String?;
    }

  @override
  void write(BinaryWriter writer, VideoDownloadRecord obj) {
    
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.rangeStart)
      ..writeByte(1)
      ..write(obj.fileSize)
      ..writeByte(2)
      ..write(obj.rate)
      ..writeByte(3)
      ..write(obj.videoUrl)
      ..writeByte(4)
      ..write(obj.audioUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoDownloadRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
