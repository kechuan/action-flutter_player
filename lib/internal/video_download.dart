
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:flutter_player/internal/hive.dart';
import 'package:flutter_player/internal/log.dart';
import 'package:flutter_player/internal/url_request.dart';
import 'package:flutter_player/model/player_ui_model.dart';
import 'package:flutter_player/model/video_download_record.dart';
import 'package:flutter_player/model/video_model.dart';


import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:flutter_player/widget/component/prompt_dialog.dart';

void showDownloadDialog({String? bvid,int? cid,String? title}) async {
  final playerController = Get.find<VideoModel>();

  if(!playerController.localDownloadTaskQueue.containsKey(playerController.currentPlayingInformation["title"])){
    
    if(bvid !=null && cid != null){
      //如果提供ID了 则应根据提供的ID信息来获取数据 以进行下载
      //在这期间势必牵扯到Future和网络请求问题

      await Get.dialog<RxMap>(

        FutureBuilder(
          future: playerController.parsingVideo(
            orignalUrl: "${SuffixHttpString.baseUrl}${PlayerApi.playerUri}?bvid=$bvid&cid=$cid&high_quality=1&platform=html5&qn=112",
            dashFlag:true,
            videoLoadFlag:false,
            isrcmd: true
          ),
          builder: (_,snapshot){
            
            switch(snapshot.connectionState){

              case ConnectionState.waiting:{
                return Dialog(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      color: const Color.fromARGB(231, 85, 83, 83),
                    ),
                    height: 400,
                    width: 400,
                    child: const Center(
                      child: Text("request Data..."),
                    ),
                  ),
                );
              }

              case ConnectionState.done:{
                return Dialog(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      color: const Color.fromARGB(231, 85, 83, 83),
                    ),
                    height: 400,
                    width: 400,
                    child: DownloadQualifySelectPanel(isrcmd: true,rcmdTitle: title),
                  ),
                );
              }

              default: return const SizedBox.shrink();

            }
          
          }
        ),

        transitionCurve: Curves.ease,
        transitionDuration: const Duration(milliseconds: 300)
          
            
        ).then((resultMap){
          //resultMap的内容是 {"name":index}
          //Log.logprint(resultMap); 

          if(resultMap!=null){
            videoDownload(
              videoTitle:resultMap.keys.first, //name
              videoUrl:playerController.rcmdDownloadVideoQualityMap.values.elementAt(resultMap.values.first.value),
              videoSize:playerController.rcmdDownloadQualitySize[resultMap.values.first.value], //size
              currentAudioUrl:playerController.rcmdDownloadAudioUrl,
            );
          }

          else{
            Log.logprint("task was existed or canceld");
          }
        });
    }

    else{

      //如果没有主动提供ID 则以当前播放信息进行下载
        await Get.dialog<RxMap>(
          Dialog(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: const Color.fromARGB(231, 85, 83, 83),
              ),
              height: 400,
              width: 400,
              child: const DownloadQualifySelectPanel(),
            ),
          ),

          transitionCurve: Curves.ease,
          transitionDuration: const Duration(milliseconds: 300)
            
        ).then((value){
          //value的内容是 {"name":index}
          Log.logprint(value); 

          if(value!=null){
            videoDownload(
              videoTitle:value.keys.first, //name
              videoUrl:playerController.currentPlayingInformation["videoUrl"],
              videoSize:playerController.currentPlayingInformation["size"][value.values.first.value], //size
              currentAudioUrl:playerController.currentPlayingInformation["audioUrl"],
            );
          }

          else{
            Log.logprint("task was existed");
          }
        });

    }

      

  }

  else{
    //如已存在 弹出toaster 提示
    Get.snackbar(
      '下载任务已存在于队列中',
      '',
      snackPosition: SnackPosition.BOTTOM,
      colorText:Colors.white,
      maxWidth: 300
    );
  }
  
}

//value 本质就是  {[战地2042]听不清楚该上市: 1} 1 => 画质 画质 本质 -> videoSize 所以传size数据就够了

//注意 这里的double videoSize 在传入时已经是以 MB 为单位了
void videoDownload({required String videoTitle,required String videoUrl,required double videoSize,String? currentAudioUrl,int? rangeInformation}) async {

  final playerController = Get.find<VideoModel>();
  final playerControlPanel = Get.find<PlayerUIModel>();

    String currentStoragePath = "${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle";

    double recordRate = 0;
    double newRecordRate = 0;

    Log.logprint("key:$videoTitle,size:$videoSize");

    int basicTimer = DateTime.now().millisecondsSinceEpoch;

    CancelToken currentCancelToken = CancelToken();

    int downloadedRange = 0;

    //cancelToken触发时行为
    currentCancelToken.whenCancel.then((value){

      //videoDownloadCancel()

      Log.logprint("task was cancel. downloadedRange:$downloadedRange, was record to Hive");

      playerController.localDownloadTaskQueue[videoTitle]!
      .update("speed",(value) => null);

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
    }).then((value){
      //如已存在(被暂停过不止1次).PartA 则融合它和新文件为新的PartA
      if(currentStoragePath.contains(RegExp(r'partA$'))){
        mergeVideo(videoTitle,".partA");
      }

      //否则正常转变为.PartA
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
                //所以需要range拼接更新
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

                Log.logprint("speed:${currentSpeed*1024}KB/s, rate:$newRecordRate");

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
            Log.logprint("video complete");

            if(currentStoragePath.contains(RegExp(r'partB$'))){
              mergeVideo(videoTitle,".mp4");
            }
          }),

          //音频为隐秘下载 如果真出现了视频下完音频没下完 到时候就显示message在上面吧。。
          //待处理(如果音频没下载完毕的做法[吃力不讨好])
          currentAudioUrl!=null ?
          HttpApiClient.client.download(
            currentAudioUrl,
            "${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle.mp3",
            cancelToken: currentCancelToken,
            
          ).then((value){Log.logprint("audio complete");}) :
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
      Log.logprint(error);
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

  Log.logprint("rename ext: $extName");

  outputFile.renameSync("${StoragePath.downloadPath}${Platform.pathSeparator}$videoTitle.$extName");

  MyHive.videoDownloadDataBase.delete(videoTitle);
 
}