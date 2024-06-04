

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_player/internal/enum_define.dart';
import 'package:flutter_player/model/video_model.dart';
import 'package:get/get.dart';

class PlayerUIModel extends GetxController{
  //PlayerUIModel({required this.playerData}){
  PlayerUIModel(){
    initModel();
  }

  final VideoModel playerData = Get.find<VideoModel>();

  final RxBool gestureDragingStatus = false.obs;

  final RxBool audioLoadedStatus = false.obs;
  final RxBool videoLoadedStatus = false.obs;
  final RxBool playerPlayingStatus = false.obs;
  

  //目前用于显示loadingAudio的状态
  final RxBool playerAudioBufferingStatus = false.obs;

  final List localDeleteList = [];

  final RxInt currentPlayingVideoType = (-1).obs;

  //Drawer
  int recordVideoResourcePageIndex = 0;

  //Search
  final RxBool searchingFocus = false.obs;
  final RxString searchType = "搜索".obs;

  //blurShow
  final RxBool tempBlurShowFlag = false.obs;

  final RxBool localPlayListExpanded = true.obs;
  final RxBool localDownloadListExpanded = false.obs;

  double currentPageWidth = 0.0;
  double currentPageHeight = 0.0;

  double dragStartPositonX = 0.0;
  double dragStartPositonY = 0.0;

  bool panelActiveStatus = true;
  bool panelActiveAnimated = true;

  String dragingSliderTime = "00:00";
  bool sliderDragingStatus = false;

  int currentDurationSecond = 0;

  Timer? delayHidePanelTimer;

  double toasterMessageOffset = -150; 

  bool isLocalPlayListDeleteMode = false;
  bool isDownloadTaskDeleteMode = false;

  //OverlayEntry? currentOverlayEntry = OverlayEntry(builder: (context) {return const SizedBox.shrink();});
  OverlayEntry? currentOverlayEntry;

  BuildContext? videoPageContext;
  BuildContext? videoControlPanelContext;

  void initModel(){
    initShortCutsKey();
  }

  void disposePage(){

    if(videoPageContext!=null){
      if(videoPageContext!.mounted){

        Navigator.of(videoPageContext!).pop(); 
        print("pop executed:${DateTime.timestamp()}");

        togglePlayerUIStatus(PlayerStatus.indle);

        playerData.disposePlayer();

        updatePanelTitle();
        update(["controlPanel"]);

      }
    }

  }

  void initShortCutsKey(){
    HardwareKeyboard.instance.addHandler(videoShortCutsKey);
  }

  void updateSliderStatus({required bool showStatus,String? sliderTime}){

    if(sliderTime!=null){
      dragingSliderTime = sliderTime;
    }
    
    sliderDragingStatus = showStatus;

    updateSliderDrag();
  }

  bool videoShortCutsKey(KeyEvent event) {

      if(searchingFocus.value){
        return false;
      }

      //playerData.player Active Action
      if(videoLoadedStatus.value){
        //KeyDownEvent
        if (event is KeyDownEvent)  {
          switch(event.logicalKey){

            case LogicalKeyboardKey.arrowUp: {
              //应当显示调节toaster
              playerData.videoVolume = min(20,playerData.videoVolume+1);
              playerData.player.setVolume(playerData.videoVolume*5);
              break;
            }

            case LogicalKeyboardKey.arrowDown: {
              //应当显示调节toaster
              playerData.videoVolume = max(0,playerData.videoVolume-1);
              playerData.player.setVolume(playerData.videoVolume*5);
              break;
            }

            case LogicalKeyboardKey.arrowLeft: {

              currentDurationSecond = max(playerData.player.state.position.inSeconds-5,0);
              dragingSliderTime = convertDuration(currentDurationSecond);
              
              break;
            }

            case LogicalKeyboardKey.arrowRight: {


              currentDurationSecond = min(playerData.player.state.position.inSeconds+5,playerData.player.state.duration.inSeconds);
              dragingSliderTime = convertDuration(currentDurationSecond);

              break;
            }

            case LogicalKeyboardKey.space: {
              playerStatusToggle();
              break;
            }


            default: {
              print(event.logicalKey);
            }

          }

          //事件拦截
          
        }

        else if(event is KeyRepeatEvent){
          //KeyRepeatEvent
          
            switch(event.logicalKey){

              //唯一的差别是 你应该去显示它们的Label

              case LogicalKeyboardKey.arrowUp: {
                
                playerData.videoVolume = min(20,playerData.videoVolume+1);
                playerData.player.setVolume(playerData.videoVolume*5);
                break;
              }

              case LogicalKeyboardKey.arrowDown: {
                playerData.videoVolume = max(0,playerData.videoVolume-1);
                playerData.player.setVolume(playerData.videoVolume*5);
                break;
              }

              case LogicalKeyboardKey.arrowLeft: {

                currentDurationSecond = max(currentDurationSecond-1,0);
                dragingSliderTime = convertDuration(currentDurationSecond);
                updateSliderStatus(showStatus:true,sliderTime:dragingSliderTime);

                break;
              }

              case LogicalKeyboardKey.arrowRight: {

                currentDurationSecond = min(currentDurationSecond+1,playerData.player.state.duration.inSeconds);
                dragingSliderTime = convertDuration(currentDurationSecond);

                updateSliderStatus(showStatus:true,sliderTime:dragingSliderTime);

                break;
              
              }

              //case LogicalKeyboardKey.space: {
              //  playerStatusToggle();
              //  break;
              //} 

              default: {
                print(event.logicalKey);

                return false;
              }
            }
            
            //事件拦截
            return false;

        }

        else{

          //KeyUpEvent
          print("key up trigged:${event.logicalKey}");

          if(event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.arrowRight){
              
            playerData.player.seek(
              Duration(
                seconds: currentDurationSecond
              )
            );
            
            updateSliderStatus(showStatus: false);
          }


          if(event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.arrowDown){

          }

        }
        
      }

      //想法 其余快捷键快速打开物品栏 L -> List

      //playerData.player General Action
      if (event is KeyDownEvent)  {
          switch(event.logicalKey){

            case LogicalKeyboardKey.escape:{

              print("'escape' trigged");
              //disposePage();
              
              playerData.disposePlayer();

              togglePlayerUIStatus(PlayerStatus.indle);
              

            }

            case LogicalKeyboardKey.keyL:{
              print("'List open' trigged");
              toggleDrawVideoSelectPanel();
                         
            }

            
          }

      }

      return false;

  }
  
  void toggleDrawVideoSelectPanel(){
    if(videoControlPanelContext!=null){
      if(videoControlPanelContext!.mounted){
        if(Scaffold.of(videoControlPanelContext!).isEndDrawerOpen){
          print("close it");
          Scaffold.of(videoControlPanelContext!).closeEndDrawer(); 
        }
        
        else{
          Scaffold.of(videoControlPanelContext!).openEndDrawer(); 
        }
      }
    }
  }

  void toggleControlPanelStatus(){
    update(["controlPanel"]);
  }

  void toggleToasterMessage(){
    if(toasterMessageOffset != 0){
      toasterMessageOffset = 0;

      Future.delayed(const Duration(seconds: 3)).then((value){
        toasterMessageOffset = -150;
        update(["toast"]);
      });

      update(["toast"]);

    }

    else{
      toasterMessageOffset = 150;
      update(["toast"]);
    }

  }

  void toggleLocalPlayListMode(){
    isLocalPlayListDeleteMode = !isLocalPlayListDeleteMode;
    isDownloadTaskDeleteMode = false;
    localDeleteList.clear();
    update(["localListMode"]);
  }

  void toggleDownloadTaskMode(){
    isDownloadTaskDeleteMode = !isDownloadTaskDeleteMode;
    isLocalPlayListDeleteMode = false;
    localDeleteList.clear();
    update(["localListMode"]);
  }

  void updateLocalList(){
    update(["localList"]);
  }

  void updateDownloadList(){
    update(["localDownloadList"]);
  }

  void updateOnlineList(){
    update(["onlineList"]);
  }

  void updateOnlineRelatedList(){
    update(["onlineRelatedList"]);
  }

  void updateSliderDrag(){
    update(["sliderDrag"]);
  }

  void hidePanelTimer(){
    print("trigged panel");

    if(!panelActiveStatus) return;

    if(delayHidePanelTimer != null){
        if(delayHidePanelTimer!.isActive) delayHidePanelTimer?.cancel();
    }

    delayHidePanelTimer = Timer(const Duration(seconds: 5),(){ //原本为5s debug测试直接屏蔽这段
      panelActiveStatus = false;
      toggleControlPanelStatus();
      print("Panel was hidden by Timer");
    });
    
  }

  String convertDuration(int totalSecond){
    String resultTime;

    String currentMinutes = (totalSecond/60).floor().toString();
    String currentSeconds = (totalSecond%60).floor().toString();

    resultTime = '${currentMinutes.length>1?currentMinutes:"0$currentMinutes"}:${currentSeconds.length>1?currentSeconds:"0$currentSeconds"}';

    return resultTime;
  }

  String convertPlayedCount(int playCount){

    String resultCount;

    if(playCount<10000){
      resultCount = playCount.toString();
    }

    else{

      String tempCount = playCount.toString();

      if(tempCount.length<9){ //小于百万播放时统一为 XXX.X K 显示
        resultCount = "${tempCount.substring(0,3)}.${tempCount.substring(3,4)}K";
      }

      else{
        resultCount = "${tempCount.substring(0,2)}.${tempCount.substring(2,3)}M";
      }
      
    }

    return resultCount;

  }

  //UI&Data
  void playerStatusToggle() async {
    
    if(videoLoadedStatus.value)  {
      if(playerPlayingStatus.value){
        togglePlayerUIStatus(PlayerStatus.paused);
      }

      else{
        togglePlayerUIStatus(PlayerStatus.playing);
      }

      await playerData.player.playOrPause();

      //print("total Value update:${totalVideoProcess.value}");
      //向Model汇报进度.
    }
  }

  void togglePlayerUIStatus(PlayerStatus playerStatus){
    
    switch(playerStatus){
      case PlayerStatus.indle:{

      playerData.currentPlayingInformation = {
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

      currentPlayingVideoType.value = -1;
      videoLoadedStatus.value = false;

      updatePanelTitle();
      update(["controlPanel"]);
        

      }
        
      case PlayerStatus.completed:{

        //completed时 我觉得还是应该渲染一个BG页面在video上。。

        videoLoadedStatus.value = false;
        playerPlayingStatus.value = false;

        if(currentPlayingVideoType.value == VideoType.localVideo.index){
          tempBlurShowFlag.value = false;

          //依照喜好 定义 操作 Panel或者是 直接播放下一集
          //总之不管怎么样 这些都要设立

        }

        else{
          tempBlurShowFlag.value = true;
        }

        
        
      }
      
      case PlayerStatus.loading:{
        //buffering & loading

        playerPlayingStatus.value = false;
        audioLoadedStatus.value = false;
        //videoBuffingStatus.value = true;
        tempBlurShowFlag.value = false;
      
      }

      case PlayerStatus.playing:{

        playerPlayingStatus.value = true;
        audioLoadedStatus.value = true;
      
        videoLoadedStatus.value = true;
        tempBlurShowFlag.value = false;

      }
        
      case PlayerStatus.paused:{

        playerPlayingStatus.value = false;

        videoLoadedStatus.value = true;

      }
        
    }
    

  }

  void updatePanelTitle(){
    update(["title"]);
  }
}