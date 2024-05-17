

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_player/internal/enum_define.dart';
import 'package:flutter_player/model/playerUI_model.dart';
import 'package:flutter_player/model/video_model.dart';
import 'package:flutter_player/widget/UnVisibleResponse.dart';
import 'package:get/get.dart';

class VideoGestureDector extends StatelessWidget {
  const VideoGestureDector({super.key,this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final playerData = Get.find<VideoModel>();
    final PlayerUIModel playerControlPanel = Get.find<PlayerUIModel>();

    int verticalStep = 3; //3滑动offset 计数1次
    //int horizionStep = MediaQuery.sizeOf(context).width~/40; //横向调整 步进应拉长
    int horizionStep = MediaQuery.sizeOf(context).width~/40; //横向调整 步进应拉长

    int initalDuration = 0;
    double offsetHeight = 0;

    return GestureDetector(

      onLongPress: (){
        print("long press test"); //预计用作视频加速 rate 调整
      },

      onLongPressEnd: (longPressDetail){
        print("long press end test width:${MediaQuery.sizeOf(context).width} height:${MediaQuery.sizeOf(context).height}"); //预计用作视频加速 rate 调整
      },

      onVerticalDragStart: (dragStartDetails){
        playerControlPanel.dragStartPositonX = dragStartDetails.localPosition.dx;
        playerControlPanel.dragStartPositonY = dragStartDetails.localPosition.dy;
        offsetHeight = dragStartDetails.localPosition.dy;

        playerControlPanel.currentPageWidth = MediaQuery.sizeOf(context).width;
        playerControlPanel.currentPageHeight = MediaQuery.sizeOf(context).height;


        print("start Pos(${playerControlPanel.dragStartPositonX},${playerControlPanel.dragStartPositonY})"); //(0,0 => 左上角)

        playerControlPanel.gestureDragingStatus.value = true;

      },

      onHorizontalDragStart: (dragStartDetails) {
        playerControlPanel.dragStartPositonX = dragStartDetails.localPosition.dx;
        playerControlPanel.dragStartPositonY = dragStartDetails.localPosition.dy;

        print("start Pos(${playerControlPanel.dragStartPositonX},${playerControlPanel.dragStartPositonY})"); //(0,0 => 左上角)

        print("videoLoadedStatus:${playerControlPanel.videoLoadedStatus.value}, Type:${playerControlPanel.currentPlayingVideoType.value} ");

        initalDuration = playerData.player.state.position.inSeconds;

      },

      onHorizontalDragUpdate: 

      //indle 闲置时禁用(debug结束开启)

        (dragHorizonUpdateDetails){

          if(!playerControlPanel.videoLoadedStatus.value) return;
          if(playerControlPanel.currentPlayingVideoType.value == VideoType.onlineStream.index) return;

          //取值范围: ALL
          //步进 20
          if(dragHorizonUpdateDetails.localPosition.dx % (dragHorizonUpdateDetails.localPosition.dx/horizionStep) == 0){

            double residual = dragHorizonUpdateDetails.localPosition.dx - playerControlPanel.dragStartPositonX;

            //每超过1级 以1182为例  最低调整为 1
            int modifiyDurationTime = ((residual/horizionStep/50)*100).toInt();
            int combine = playerData.player.state.position.inSeconds + modifiyDurationTime;
            int limitedDurationTime = min(playerData.player.state.duration.inSeconds, max(0, combine));

            initalDuration = limitedDurationTime;

            //playerData.updateStatus(playerControlPanel.convertDuration(initalDuration),true);

            playerControlPanel.updateSliderStatus(true,playerControlPanel.convertDuration(initalDuration));

            print("residual:$residual playerData.durationTime:${playerData.player.state.duration.inSeconds},current:$limitedDurationTime");

          } 
        
      },

      onHorizontalDragEnd:
      
      (details){

        if(!playerControlPanel.videoLoadedStatus.value) return;
        if(playerControlPanel.currentPlayingVideoType.value == VideoType.onlineStream.index) return;

        //playerControlPanel.sliderDragingStatus.value = false;
        playerData.player.seek(Duration(seconds: initalDuration));

        playerControlPanel.updateSliderStatus(false);
      },

      onVerticalDragUpdate: (dragVerticalUpdateDetails) async {

        if(playerControlPanel.dragStartPositonX < MediaQuery.sizeOf(context).width / 3 && dragVerticalUpdateDetails.localPosition.dx < MediaQuery.sizeOf(context).width /3){

          if(dragVerticalUpdateDetails.localPosition.dy % (dragVerticalUpdateDetails.localPosition.dy/verticalStep) == 0){ // screenHeight / ? => 13 segments judge

            double residual = dragVerticalUpdateDetails.localPosition.dy - offsetHeight;
            int modifiyAmp = (-residual~/verticalStep);
            double limitedVolume = min(100, max(0, playerData.videoVolume + modifiyAmp));

            playerData.videoVolume = limitedVolume;

            await playerData.player.setVolume(limitedVolume.toDouble());

            //print("local: ${dragVerticalUpdateDetails.localPosition.dy}, offset:${offsetHeight}, residual:$residual ,modify:$modifiyAmp");

            offsetHeight = dragVerticalUpdateDetails.localPosition.dy;


          }

        }

        //不在两者范围的 直接取消
        return;

      },

      onVerticalDragEnd: (details) {

        print("state Volume ${playerData.player.state.volume}");
        //playerData.videoVolume = (playerData.player.state.volume/5).truncate();
        print("playerData.videoVolume ${playerData.videoVolume}");

        playerControlPanel.gestureDragingStatus.value = false;

      },

      child: Center(
        child: UnVisibleResponse(
          onTap: (){

            playerControlPanel.panelActiveStatus = !playerControlPanel.panelActiveStatus;
            
            if(playerControlPanel.panelActiveAnimated == false){
              playerControlPanel.panelActiveAnimated = true;
            }

            playerControlPanel.toggleControlPanelStatus();
            playerControlPanel.hidePanelTimer();

            print("panelStatus: status:${playerControlPanel.panelActiveStatus}, animated:${playerControlPanel.panelActiveAnimated}");

          },
          
          child: child,
        )
      )
    );
    
  }
}