import 'package:flutter/material.dart';
import 'package:flutter_player/internal/enum_define.dart';
import 'package:flutter_player/model/playerUI_model.dart';
import 'package:flutter_player/model/video_model.dart';
import 'package:get/get.dart';
import 'dart:math';


const SliderThemeData bufferSliderData = SliderThemeData(
  trackHeight: 2,
  thumbColor: Colors.transparent,
  thumbShape: RoundSliderOverlayShape(overlayRadius: 6),
  overlayShape: RoundSliderOverlayShape(overlayRadius: 3),
  overlayColor: Colors.transparent,
  
  activeTrackColor: Color.fromARGB(218, 182, 164, 164),
  inactiveTrackColor: Color.fromARGB(255, 78, 76, 76),
);

const SliderThemeData durationSliderData = SliderThemeData(
  trackHeight: 2,
  thumbShape: RoundSliderOverlayShape(overlayRadius: 6),
  overlayShape: RoundSliderOverlayShape(overlayRadius: 3),
  inactiveTrackColor: Colors.transparent, //表层色彩不提供 交由底层进行色彩展示

  activeTrackColor: Color.fromARGB(233, 249, 244, 200),
  thumbColor: Colors.white,

);

class ProgressSlider extends StatelessWidget {
  const ProgressSlider({
    super.key,
    required this.videoType,
    required this.currentPosition,
    });

  final int videoType;
  final int currentPosition;

  @override
  Widget build(BuildContext context) {

    final playerController = Get.find<VideoModel>();
    final playerControlPanel = Get.find<PlayerUIModel>();
    
    //final playerController.player = playerController.playerController.player;

    int videoTotalDuration = playerController.playerController.player.state.duration.inSeconds;

    return Stack(
      alignment :Alignment.center,
      children: [
        
        //里层 缓冲条(播放本地内容时不应显示 且应让表层进度条的inactive颜色恢复正常)
        //表层 进度条
    
        videoType == VideoType.localVideo.index ?
        const SizedBox.shrink() :
        SliderTheme(
          data: bufferSliderData,                            
          child:Slider(
            allowedInteraction: SliderInteraction.tapOnly,
            value: !playerControlPanel.videoLoadedStatus.value ?
            0.0 :
            min(1.0,((playerController.playerController.player.state.buffer.inSeconds+1)/playerController.playerController.player.state.duration.inSeconds)), //遇到60/61时无法判断
            
            
            onChanged: (value){},
          ),
    
        ),
    
        SliderTheme(
          data: videoType == VideoType.localVideo.index ?
          durationSliderData.copyWith(inactiveTrackColor: const Color.fromARGB(255, 78, 76, 76)) :
          durationSliderData ,
                                              
          child:
            Obx(
              (){
                return Slider(
                allowedInteraction: playerControlPanel.videoLoadedStatus.value ? null : SliderInteraction.tapOnly,
              
                value: 
                  playerController.playerinitalFlag.value 
                  
                  ?

                    videoType == VideoType.onlineStream.index ? 
                    1.0 : 
                    (videoTotalDuration != 0 ? min(1.0,currentPosition/videoTotalDuration) : 0) 
                  :

                  0.0,
                      
                onChangeEnd:
                 (value) async {
                  if(videoType == VideoType.onlineStream.index) return;
                  if(!playerControlPanel.videoLoadedStatus.value) return;
              
                  print("release rate:$value, ${playerControlPanel.convertDuration((value*videoTotalDuration).toInt())}/${playerControlPanel.convertDuration(videoTotalDuration)} ");
                  
                  playerControlPanel.sliderDragingStatus = false;
              
                  playerControlPanel.updateSliderDrag();
                  
                  //playerController.videoBuffingStatus.value = true;
                                                
                  await playerController.player.seek(
                    Duration(seconds: (value*videoTotalDuration).toInt()),
                  ).then((_){
                    //playerController.videoBuffingStatus.value = false;
                    
                  });
                    
                },
                                                
                onChanged: (dragingVideoRate){
                  if(videoType == VideoType.onlineStream.index) return;
                 
                  if(playerControlPanel.videoLoadedStatus.value){
                    playerControlPanel.dragingSliderTime = playerControlPanel.convertDuration((dragingVideoRate*videoTotalDuration).toInt());
                    playerControlPanel.sliderDragingStatus = true;
              
                    playerControlPanel.updateSliderDrag();
              
                  }  
              
                },
              
                overlayColor: const MaterialStatePropertyAll(Colors.white)
                                                
              );
              }
            
            ),
        )
    
      ],
    );
        
  }
}