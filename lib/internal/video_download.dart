
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_player/internal/hive.dart';
import 'package:flutter_player/internal/url_request.dart';
import 'package:flutter_player/model/playerUI_model.dart';
import 'package:flutter_player/model/video_download_record.dart';
import 'package:flutter_player/model/video_model.dart';
import 'package:get/get.dart';


//value 本质就是  {[战地2042]听不清楚该上市: 1} 1 => 画质 画质 本质 -> videoSize 所以传size数据就够了
void videoDownload(String videoTitle,String videoUrl,double videoSize,[String? currentAudioUrl,int? rangeInformation]) async {

  final playerController = Get.find<VideoModel>();
  final playerControlPanel = Get.find<PlayerUIModel>();

    String currentStoragePath = "${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle";

    double recordRate = 0;
    double newRecordRate = 0;

    print("key:$videoTitle,size:$videoSize");

    int basicTimer = DateTime.now().millisecondsSinceEpoch;

    CancelToken currentCancelToken = CancelToken();

    int downloadedRange = 0;


    currentCancelToken.whenCancel.then((value){
      print("task was cancel. downloadedRange:$downloadedRange, was record to Hive");

      playerController.localDownloadTaskQueue[videoTitle]!
      .update("speed",(value){
        //return {"rate":-1.0,"speed":null,"size":videoSize};
        return null;
      });

      //如果当前存储目标存在partA 应合并当前的partA/partB 为新的partA
      //称作mergeBody

      playerControlPanel.updateDownloadList();

      MyHive.videoDownloadDataBase.put(
        videoTitle, VideoDownloadRecord()
        ..rangeStart = downloadedRange
        ..fileSize = videoSize
        ..rate = newRecordRate
        ..videoUrl = videoUrl
        ..audioUrl = currentAudioUrl
      );

      //rename to .PartA

      
    //难道是whenCacnel执行完毕之后才不占用?
    }).then((value){

      if(currentStoragePath.contains(RegExp(r'partA$'))){
        mergeVideo(videoTitle,".partA");
      }

      //幽默了。。此时取消 文件依旧被占用 但我又不知道什么时候才不会被占用

      else{
        File partA = File('${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle.mp4');
        partA.renameSync('${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle.partA');
      }

    });

      playerController.localDownloadTaskQueue.addAll(
        // recover / new
        {videoTitle:{"rate":null,"speed":null,"size":videoSize,"cancelToken":currentCancelToken}}
      );

      try{

        if(rangeInformation!=null){
          //不为null 则说明刚刚被暂停 说明当前目录应该留有partA文件
          currentStoragePath+=".partB";
        }

        else{
          currentStoragePath+=".mp4";
        }

        Future.wait(
          [
            HttpApiClient.client.download(
              videoUrl,
              currentStoragePath,
              
              options: 
                rangeInformation != null ? 
                Options(headers:{"range":"bytes=$rangeInformation-"}) : 
                null ,

              onReceiveProgress:(count, total) {

                //如果有旧的range信息加入 那么此处的rate信息则不准确 
                //这会附带影响到Speed属性

                int currentTimeStamp = DateTime.now().millisecondsSinceEpoch;

                if(rangeInformation!=null){
                  downloadedRange = count+rangeInformation;
                  newRecordRate = downloadedRange/(videoSize*1024*1024);
                }

                else{
                  downloadedRange = count;
                  newRecordRate = count/total;
                }

                //隔0.5s update一次
                if(currentTimeStamp > basicTimer+500){

                  double currentSpeed = (newRecordRate-recordRate)*videoSize; //默认MB级别Label

                  print("speed:${currentSpeed*1024}KB/s, rate:$newRecordRate");

                  Map<String,Object?>? currentTask = playerController.localDownloadTaskQueue[videoTitle];

                  if(currentTask!=null){

                    currentTask.update("rate", (value) => newRecordRate);
                    currentTask.update("speed", (value) => currentSpeed);

                    recordRate = newRecordRate;
                    basicTimer = currentTimeStamp;
                    playerControlPanel.updateDownloadList();

                  }

                }
                
              },
              cancelToken: currentCancelToken,
              deleteOnError: false, //cancelToken也属于 Error的一种。。 嗯。。。
              //要不干脆使用raf接管?
            ).then((value){
              print("video complete");

              if(currentStoragePath.contains(RegExp(r'partB$'))){
                mergeVideo(videoTitle,".mp4");
              }
            }),

            
            //音频为隐秘下载 如果真出现了视频下完音频没下完 到时候就显示message在上面吧。。
            currentAudioUrl!=null ?
            HttpApiClient.client.download(
              currentAudioUrl,
              "${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle.mp3",
              cancelToken: currentCancelToken,
              
            ).then((value){print("audio complete");})
            :
            Future(() => null)

          ]
        ).then((value){
          playerController.localDownloadTaskQueue.update(videoTitle,(value){
            return {"rate":-1.0,"speed":null,"size":videoSize};
          });
          playerControlPanel.updateDownloadList();
        });

      }

      on DioException catch(error){
        print(error);
      }


}
  
void mergeVideo(String videoTitle,String extName) async {

  File outputFile = File('${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle.temp');
  
  IOSink connectSink = outputFile.openWrite(
    mode: FileMode.writeOnlyAppend
  );

  File targetA = File('${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle.partA');
  File targetB = File('${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle.partB');

  await connectSink.addStream(targetA.openRead());
  await targetA.delete();

  await connectSink.addStream(targetB.openRead());
  await targetB.delete();

  await connectSink.close();

  print("rename ext: $extName");

  outputFile.renameSync("${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle.$extName");

  MyHive.videoDownloadDataBase.delete(videoTitle);
 
}