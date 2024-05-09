
import 'package:hive/hive.dart';

part 'video_download_record.g.dart';

//新Hive TypeAdapter的引入似乎会导致对Box的写入出现问题
@HiveType(typeId: 2) //VideoDurationRecord
class VideoDownloadRecord extends HiveObject{
  VideoDownloadRecord({this.rangeStart,this.fileSize});

  @HiveField(0)
  int? rangeStart;

  @HiveField(1)
  double? fileSize;
  
  @HiveField(2)
  double? rate;

  @HiveField(3)
  String? videoUrl;

  @HiveField(4)
  String? audioUrl;

}
