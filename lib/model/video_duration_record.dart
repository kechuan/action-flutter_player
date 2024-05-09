
import 'package:hive/hive.dart';

part 'video_duration_record.g.dart';

//新Hive TypeAdapter的引入似乎会导致对Box的写入出现问题
@HiveType(typeId: 1) //VideoDurationRecord
//HiveObject 提供额外的方法: save/delete()
class VideoDurationRecord extends HiveObject{
  VideoDurationRecord({this.videoPosition});

  @HiveField(0)
  Duration? videoPosition;

  @override
  String toString() {
    return 'VideoDurationRecord{videoPosition: $videoPosition}';
  }

  //记录 观看历史 以及观看的Duration 以及..自动跳转上次播放的位置

}
