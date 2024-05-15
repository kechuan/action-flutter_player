//import 'package:flutter/material.dart';
import 'dart:async';

import 'package:dio/dio.dart';

import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_player/internal/enum_define.dart';

import 'package:flutter_player/internal/hive.dart';

import 'package:flutter_player/internal/request_encode.dart';
import 'package:flutter_player/internal/url_request.dart';
import 'package:flutter_player/model/playerUI_model.dart';

import 'package:flutter_player/model/user_model.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

//预计分离:VideoModel(List->Update) -> PlayerUiModel(Obx.obs)
class VideoModel extends GetxController{
    
    VideoModel(){
      initModel();
    }

    //[VideoModel]

    static bool videoModelInitaled = false;

    late Player player; //解码
    late VideoController playerController; //播放。。控制?

    final List onlinePlayList = [];
    final List localPlayList = [];
    final List localDeleteList = [];
    final List onlineRelatedList = [];
    
    final Map<String,Map<String,Object?>> localDownloadTaskQueue = {
      
    };
    
    Map<String,dynamic> currentPlayingInformation = {
      "title":"",
      "author":"",
      "videoUrl":"",
      "audioUrl":null,
      "bvid":null,
      "cid":null,
      "qualityMap":<String,String>{

      },
      "size":[]

    };
    
    int currentPlayingLocalVideoIndex = 1;

    RxBool playerinitalFlag = false.obs;
    double videoVolume = 50;

    bool isMuted = false;

  Future initPlayer() async {

    //目前执行顺序如下

    if(!playerinitalFlag.value){
      print("init player trigged");
      player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 5*1024*1024, //应当跟着config配置
        )
      );

      player.setVolume(videoVolume);

      playerController = VideoController(player);

      var pp = player.platform;

      await pp!.waitForPlayerInitialization.then((value) async {

        if(player.platform is NativePlayer){

          //mpv -setting: https://hooke007.github.io/official_man/mpv.html#id49
          await (player.platform as dynamic).setProperty('cache', 'yes');
          await (player.platform as dynamic).setProperty('cache-secs', '5');
          await (player.platform as dynamic).setProperty('demuxer-seekable-cache', 'no');  // --demuxer-seekable-cache=<yes|no|auto> Redundant with cache but why not.
          await (player.platform as dynamic).setProperty('demuxer-max-back-bytes', '0');   // --demuxer-max-back-bytes=<bytesize>
          await (player.platform as dynamic).setProperty('demuxer-donate-buffer', 'no');   // --demuxer-donate-buffer==<yes|no>

          print("all prop loaded");
          print("player.hashCode: ${player.hashCode} was created");

          playerinitalFlag.value = true;

          update(["video"]); 

          //销毁之后需要重新更新videoPage的video 
          //否则。。videoPage调用的还是旧版的controller实例

        }

      });

    }
    
  }

  void initModel() async {
      if(!videoModelInitaled){

        await initPlayer();
        initRequestStatus();
        loadDownloadData();

        
        //这个执行顺序比videoPage初始化还要晚的多的多 真的不太明白 那个顺序是怎么搞的
        print("VideoModel was initaled");

        videoModelInitaled = true;
        
      }
  }

  void initRequestStatus(){

    HttpApiClient.clientOption.baseUrl = SuffixHttpString.baseUrl;
    HttpApiClient.clientOption.headers = HttpApiClient.broswerHeader;

    HttpApiClient.client.options = HttpApiClient.clientOption;

    HttpApiClient.client.interceptors.add(
      CookieManager(ClientCookies.cookieJar)
    );


    if(ClientCookies.sessData.isNotEmpty){
      UserModel.isLogined = true;
      print("is Logined");
    }

    else{
      UserModel.isLogined = false;
    }
  }

  void loadDownloadData(){
    
    for(int currentTaskIndex = 0; currentTaskIndex<MyHive.videoDownloadDataBase.keys.length; currentTaskIndex++ ){
      localDownloadTaskQueue.addAll(
        {
          MyHive.videoDownloadDataBase.keys.elementAt(currentTaskIndex):
          {
            "fileSize":MyHive.videoDownloadDataBase.values.elementAt(currentTaskIndex)?.fileSize,
            "rate":MyHive.videoDownloadDataBase.values.elementAt(currentTaskIndex)?.rate,
            "speed":null
          }
          
        }

      );
    }
  }

  void playerVideoLoad(Playable video,[String? dashAudioUri]) async {

    final playerControlPanel = Get.find<PlayerUIModel>();

    //被销毁暂停时 重建player
    if(playerinitalFlag.value==false){
      print("disposed, rebuild player");
      initPlayer();
    }

    update(["controlPanel"]);

    if(video is Media){
      if(video.uri.isNotEmpty){

        if(dashAudioUri!=null){

          print("it has audio:$dashAudioUri");

          playerControlPanel.togglePlayerUIStatus(PlayerStatus.loading);

          await Future.wait(
            [
              player.open(video,play:false),
              playerAudioLoad(dashAudioUri)
            ]
          ).then((value){
            player.play();
          });

        }

        else{
          currentPlayingInformation["audioUrl"] = null;
          await player.open(video);
        }

      }
    }

    else if(video is Playlist){
      currentPlayingInformation["audioUrl"] = null;
      await player.open(video);
    }

    playerControlPanel.togglePlayerUIStatus(PlayerStatus.playing);

  }

  Future<void> playerAudioLoad(String dashAudioUri){
      Completer audioLoadCompleter = Completer();

      player.setAudioTrack(AudioTrack.uri(dashAudioUri));

      var timeoutTimer = Timer(const Duration(seconds: 6),(){
        print("audio loaded fail,${player.state.tracks.audio}");
        

        player.setAudioTrack(AudioTrack.uri(dashAudioUri)); //request Again
        
      });

      player.stream.audioParams.listen((event) {
        print("loading audio Stream,$event");
        
          if(event.format!=null){
            //好像 触发了两次回调? : (2) flutter: loading
            //不知道这是为什么 总之加个判断吧

            if(audioLoadCompleter.isCompleted){
              return;
            }

            audioLoadCompleter.complete();
            timeoutTimer.cancel();
            print("audio Stream Loaded");

          }

      });

      return audioLoadCompleter.future;

    }

  Future<Media> parsingVideo(String orignalUrl,bool dashFlag,[bool? videoLoadFlag]) async {

    Media onlineMediaInformation = Media("");

    String parsingVideoUrl = "";
    String? parsingAudioUrl;


    if(UserModel.isLogined){ 
      //Access With Member 
      print("Member Mode");
      parsingVideoUrl = encodeHTTPRequest(orignalUrl);
    
    }

    else{  
      //Access With Guest
      print("Guest Mode");
      parsingVideoUrl = orignalUrl;
    }

    parsingVideoUrl = parsingVideoUrl.split(SuffixHttpString.baseUrl)[1];

    print("After Split:$parsingVideoUrl");

    await HttpApiClient.client.get(
      parsingVideoUrl,
      queryParameters:dashFlag?{RequestParams.fnval:16}:null,
      options: Options(
        
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    ).then((response){

      //print("response:$response");
      
      // 解析错误 判断
      if(dashFlag){
        if(response.data["data"]?["dash"]!=null && response.data["data"]?["dash"].isEmpty){
          print("DASH parse fail:$response");
          return;
        }
      }

      else{
        if(response.data["data"]?["durl"]!=null && response.data["data"]?["durl"].isEmpty){
          print("FLV parse fail:$response");
          return;
        }
      }

      if(response.data["data"]["result"] == "suee"){

        Map responseInformation = response.data["data"]; 

        Map<String,String> videoQualityInforamtion = currentPlayingInformation['qualityMap'];
        List<dynamic> sizeInformation = currentPlayingInformation["size"];

        if(dashFlag && UserModel.isLogined){

          List<dynamic> accept_description = responseInformation['accept_description'];
          List<dynamic> accept_quality = responseInformation['accept_quality'];

          List<dynamic> videoInforamtion = response.data["data"]["dash"]["video"];
          List<dynamic> audioInforamtion = response.data["data"]["dash"]["audio"];

          //一个画质里面有多少个编码 比如id:80 avc,hevc 则有2个编码
          //int encodeStack = videoInforamtion.length ~/(responseInformation["accept_quality"].length - 1);

          int encodeStack = videoInforamtion.length ~/(responseInformation["accept_quality"].length - 1);

          int codecOffset = 0; // avc/hevc/av1 7 12 13
          int qualifyOffset = 0;
          int codecID = 12;

          switch(UserModel.configList["encodeSetting"]){
            case 'AVC': codecID = 7;break;
            case 'HEVC': codecID = 12;break;
            case 'AV1': codecID = 13;break;
          }

          switch(UserModel.configList["qualifiySetting"]){
            case 'FHD': qualifyOffset = 0;break;
            case 'HD': qualifyOffset = 1;break;
            case 'Mediumn': qualifyOffset = 2;break;
            case 'Low': qualifyOffset = 3;break;
            case 'VeryLow': qualifyOffset = 4;break;
          }

          videoQualityInforamtion.clear();
          sizeInformation.clear();

          //数据来源:API

          //b站不知道为什么 有时候audio的第一个是低品质的音源(30232)。。 最高品质的反而是在第二个(30280)
          Map selectedAudioInformation;
          
          //根据设置偏好的codec 选择自适应选择offset


          for(int codecIndex = 0;codecIndex<encodeStack; codecIndex++){

            if(videoInforamtion[codecIndex]["codecid"] != codecID){
               codecOffset++;
            }

            else{
              break;
            }
          }

          //Audio Select
          selectedAudioInformation = audioInforamtion[0];
          for(int audioIndex = 0; audioIndex<audioInforamtion.length;audioIndex++){
            if(audioInforamtion[audioIndex]["id"] == 30280){
              selectedAudioInformation = audioInforamtion[audioIndex];
              break;
            }
          }

          double currentVideoSize = 0;
          double currentAudioSize = selectedAudioInformation["bandwidth"]/8*response.data["data"]["dash"]["duration"]/1024/1024;

          print("code Offset:$codecOffset, encodeStack:$encodeStack, accept_quality_length:${responseInformation["accept_quality"].length}");
          
          //Video Select
          for(int currentQuality = 0; currentQuality < responseInformation["accept_quality"].length; currentQuality++){

            //1080P+ 的信息 目前置为空
            if(currentQuality == 0){
              videoQualityInforamtion.addAll(
                {accept_description[0]:""}
              );
              sizeInformation.add(null);

              continue;

            }

              int selectIndex = encodeStack*(currentQuality-1)+codecOffset;


              print("已选择 index: $selectIndex");
              currentVideoSize = (videoInforamtion[selectIndex]["bandwidth"]/8*response.data["data"]["dash"]["duration"]/1024/1024);

            videoQualityInforamtion.addAll(
              {accept_description[currentQuality]:videoInforamtion[selectIndex]["baseUrl"]}
            );
            
            sizeInformation.add(currentVideoSize+currentAudioSize);
            
          }

          parsingVideoUrl = videoInforamtion[(encodeStack*qualifyOffset)+codecOffset]["baseUrl"];
          parsingAudioUrl = selectedAudioInformation["baseUrl"];

          currentPlayingInformation["videoUrl"] = parsingVideoUrl;
          currentPlayingInformation["audioUrl"] = parsingAudioUrl;

          print("accept_description:${accept_description}, accept_quality:${accept_quality}");

        }

        else{
          parsingVideoUrl = response.data["data"]["durl"][0]["url"];
          currentPlayingInformation["videoUrl"] = parsingVideoUrl;
          sizeInformation.add(response.data["data"]["durl"][0]["size"]/1024/1024); //durl请求的视频size的大小是 Byte为单位
        }

        onlineMediaInformation = Media(
          parsingVideoUrl,
          httpHeaders:HttpApiClient.broswerHeader
        );

        //debug模式 置为false时 则只输出文字
        if(videoLoadFlag==null || videoLoadFlag==true){
          playerVideoLoad(onlineMediaInformation,parsingAudioUrl);
        }

        else{
          print("onlineInformation:$videoQualityInforamtion");
        }

      }

      else{
        print("parse error:$response");
        
      }

    });

    return onlineMediaInformation;

  }

  void playModeHandler(){
    //Data占据主导地位 就这样处理 否则是UI主要处理
    //唉 反正结果都是耦合。。 没什么办法

    final playerControlPanel = Get.find<PlayerUIModel>();

    if(playerControlPanel.currentPlayingVideoType.value != VideoType.localVideo.index){ 
      playerControlPanel.togglePlayerUIStatus(PlayerStatus.completed);
    }

    else{
      MyHive.videoRecordDataBase.delete(currentPlayingInformation["title"]); //已观看完毕 删除时长记录

      if(currentPlayingLocalVideoIndex != localPlayList.length){

        currentPlayingInformation["title"] = localPlayList[currentPlayingLocalVideoIndex]["title"];

        Duration? recordDuration = MyHive.videoRecordDataBase.get(currentPlayingInformation["title"])?.videoPosition;

        currentPlayingLocalVideoIndex += 1;

        player.open(Media(localPlayList[currentPlayingLocalVideoIndex]["uri"])); 

        if(recordDuration!=null){
          player.seek(recordDuration);
          playerControlPanel.toggleToasterMessage();
        }

        playerControlPanel.togglePlayerUIStatus(PlayerStatus.playing);

      }

      else{
        print("playlist completed.");
      }
    }

  }

  void loadOnlineVideo(Map<String, dynamic> onlineVideoInformation){

    currentPlayingInformation["title"] = onlineVideoInformation["title"];
    currentPlayingInformation["author"] = onlineVideoInformation["author"];
    currentPlayingInformation["bvid"] = onlineVideoInformation["bvid"];
    currentPlayingInformation["cid"] = onlineVideoInformation["cid"];

    parsingVideo("${SuffixHttpString.baseUrl}${PlayerApi.playerUri}?bvid=${onlineVideoInformation["bvid"]}&cid=${onlineVideoInformation["cid"]}&high_quality=1&platform=html5&qn=112",true); //Dash Request

    //parsingVideo("${SuffixHttpString.baseUrl}${PlayerApi.playerUri}?bvid=${onlineVideoInformation["bvid"]}&cid=${onlineVideoInformation["cid"]}&high_quality=1&platform=html5&qn=112",true,false); //3rd arg:Debug use

  }

  Duration? loadLocalVideo(Map<String, dynamic> localVideoInformation){

    Duration? recordDuration = (MyHive.videoRecordDataBase.get(localVideoInformation["title"]));

      print("[read Duration] ${localVideoInformation["title"]}: $recordDuration");
                      
      //print("list:${MyHive.videoRecordDataBase.keys}");
                      
      currentPlayingInformation["title"] = localVideoInformation["title"];
      
      //重新划定index
      playerVideoLoad(Media(localVideoInformation["uri"]),localVideoInformation["audioUri"] as String?);

      
    return recordDuration;

  }

  void playerCompletedStatusListen(){
    player.stream.completed.listen((completedStatus) {

      print("status: initModel ${playerinitalFlag.value}, ${player.state.position.inMilliseconds}/${player.state.duration.inMilliseconds}");

      if(playerinitalFlag.value){ //一重验证 是在播放器载入之后才应触发

        print("endStream evented trigged");

      //不确定性验证 触发completed回调后 如果播放进度差值低于1s 则允许触发
        if(player.state.duration.inMilliseconds - player.state.position.inMilliseconds < 1000 && player.state.duration.inSeconds != 0){
          print("completed event trigged, reset prop");

          //决定是否触发本地模式下的播放列表
          playModeHandler();

        }
            
      }

    });
  }

  void playerHotSwitch(String? videoUrl){

    if(videoUrl!=null){

      Duration currentPosition = player.state.position;

      playerVideoLoad(
        Media(
          videoUrl,
          httpHeaders:HttpApiClient.broswerHeader
        ),
        currentPlayingInformation["audioUrl"]

      );

      player.seek(currentPosition);

      
    }
    
  }

  void disposePlayer(){

    if(!playerinitalFlag.value) return;

    player.dispose().then((value){
      print("player.hashCode: ${player.hashCode} was disposed");
      playerinitalFlag.value = false;
    });

  }

  
}