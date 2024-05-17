import 'dart:io';

import 'package:flutter_player/internal/url_request.dart';
import 'package:flutter_player/model/duration_adapter.dart';
import 'package:hive/hive.dart';

import 'package:flutter_player/model/video_download_record.dart';
import 'package:flutter_player/model/video_duration_record.dart';


class MyHive {
  const MyHive._();

  //Hive需要什么?
  //需要一个具体的地方存储数据

  static late final Directory filesDir; //存储目录

  static late final Box<List<int>> listDataBase; //存储目标
  static late final Box<String> userDataBase; //存储目标

  static late final Box videoRecordDataBase; //存储目标
  static late final Box videoDownloadDataBase; //存储目标

  //static late final Box<VideoDurationRecord> videoRecordDataBase; //存储目标

  static Future<void> init() async {

    if(Platform.isAndroid){
      filesDir = Directory('storage/emulated/0/Download/flutter_player');
      StoragePath.downloadPath = 'storage/emulated/0/Download/flutter_player/downloads';
    }

    else{
      filesDir = Directory('.${Platform.pathSeparator}downloads');
    }
    
    

    Hive.init('${filesDir.path}${Platform.pathSeparator}hivedb');

    Hive.registerAdapter(DurationAdapter());
    Hive.registerAdapter(VideoDurationRecordAdapter());
    Hive.registerAdapter(VideoDownloadRecordAdapter());

    //疑问:注册了适配器之后 Box那边要怎 么仅靠key Name就能和 adapter联系起来?

    listDataBase = await Hive.openBox(HiveBoxKey.listDataBase);
    userDataBase = await Hive.openBox(HiveBoxKey.userDataBase);
    videoRecordDataBase = await Hive.openBox(HiveBoxKey.videoDurationDatabase);
    videoDownloadDataBase = await Hive.openBox(HiveBoxKey.videoDownloadDatabase);

  }

}

class HiveBoxKey {
  const HiveBoxKey._();

  //Dart 允许这么简便书写
  static const String listDataBase = 'infiniteList',
                      userDataBase = 'userInformation',
                      videoDurationDatabase = 'VideoDurationDataRecord',
                      videoDownloadDatabase = 'VideoDownloadDataRecord';

}

