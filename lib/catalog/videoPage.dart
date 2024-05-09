// ignore_for_file: camel_case_types
//import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
//import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_player/model/playerUI_model.dart';
import 'package:flutter_player/model/user_model.dart';
import 'package:flutter_player/model/video_model.dart'; 

import 'package:flutter_player/widget/component/player_completed_panel.dart';
import 'package:flutter_player/widget/controlPanel.dart';
import 'package:flutter_player/widget/drawVideoSelectPanel.dart';
import 'package:flutter_player/widget/videoGestureDecetor.dart';

import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

  

class VideoPage extends StatelessWidget {
  
  const VideoPage({super.key});

  @override
  Widget build(BuildContext context) {

    print("videoPage build");

    final VideoModel playerData = Get.find<VideoModel>();
    final PlayerUIModel playerControlPanel = Get.find<PlayerUIModel>();

    

    print("videoPage -> VideoModel hashCode:${playerData.hashCode}");

    //UserModel.init();
    //playerData.initPlayer(); //否则只重写player
    //playerData.playerCompletedStatusListen();

    playerControlPanel.videoPageContext = context;

    return Scaffold(

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0), //小技巧 将appBar压缩近乎为0
        child: AppBar(backgroundColor: Colors.transparent,actions: null,),
      ),  

      body: VideoGestureDector(
        child: LayoutBuilder(
            builder: (_,constraint) {

              return Stack(
                alignment: AlignmentDirectional.center,
              
                children: [

                  //视频显示
                  GetBuilder(
                    id:"video",
                    init: playerData,
                    builder:(_){
                      return Video(
                        controller: playerData.playerController,
                        controls: NoVideoControls,
                      );
                    }
                  ),
              
                  //模糊遮罩
                  Obx((){
                    return Visibility(
                      maintainState: playerControlPanel.tempBlurShowFlag.value,
                      visible: playerControlPanel.tempBlurShowFlag.value,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 6,
                          sigmaY: 6,
                        ),
              
                        //[待修改]
                        child: const SizedBox.expand(), //存放Img的地方
                      ),
                    );
                  }),
              
                  //中间状态提示(音量/进度条 等)
                  
                  Center(
                    child: Stack(
                      children: [
                          //Loading信息 无论是载入本地/在线视频 亦或者是缓冲 
                          //进阶: 显示缓冲百分比(但是目前这个情况 如果音频问题不修复 这个loading就有点搞笑了...)
                          //而且。。 在我不断seek的过程中 我留意到bufferLength几乎是恒定不变的 可我播放器的bufferSize显然不足以支撑整个视频的长度
              
                          //但是无论怎么样 都绝对会触发buffering的条件 那我要怎么界定 seek时的 buffer碎片段 是能支撑得住我能流畅播放5s?
                          //毕竟buffer的工作机制肯定是以当前的 position为基础开始加载的 
                          //如果我seek到 未被buffer的部分则绝对不可能触发loading 而只能是buffering
              
                          //可是官方提供的信息也就只有buffer-duration这一个信息...难顶

                          StreamBuilder(
                            stream: playerData.player.stream.buffering, 
                            builder:(_, snapshot) {
                              return Visibility(
                              //visible:playerData.videoBuffingStatus.value,

                              //maintainState:playerData.videoBuffingStatus.value, //maintain 的设立与否 大概是display: none 与 opacity(1) 上的区别吧
                              visible:playerData.player.state.buffering,
                              maintainState:playerData.player.state.buffering, //maintain 的设立与否 大概是display: none 与 opacity(1) 上的区别吧
                              child: Container(
                                
                                width: constraint.maxWidth * 1/11,
                                height: constraint.maxHeight * 1/11,

                                color:const Color.fromARGB(164, 47, 45, 45),
                                child: const Center(
                                  child: Text(
                                    "Loading...",
                                    style: TextStyle(color: Colors.white),
                                  ),
              
                                  //如果是加载 则显示Loading... 如果是缓冲 则额外显示百分比 Loading... ??%
                                  //child: StreamBuilder<Duration>(
                                  //  stream: playerData.player.stream.buffer,
                                  //  builder: (context, snapshot) {
              
                                  //    //print("${
                                  //    //  playerData.player.state.buffer.inSeconds - playerData.player.state.position.inSeconds
                                  //    //}");
              
              
                                  //    return Text(
                                  //      "Loading...",
                                  //      style: TextStyle(color: Colors.white),
                                  //    );
                                  //  }
                                  //),
              
                                )
                              ),
                            );
                          
                            },
                          ),
              
                          GetBuilder(
                            id: "sliderDrag",
                            init: playerControlPanel,
                            builder: (_){
                              return Visibility(
                                visible:playerControlPanel.sliderDragingStatus,
                                maintainState:playerControlPanel.sliderDragingStatus, //maintain 的设立与否 大概是display: none 与 opacity(1) 上的区别吧
                                child: Container(

                                  width: constraint.maxWidth * 1/11,
                                  height: constraint.maxHeight * 1/11,
                                  color:const Color.fromARGB(164, 47, 45, 45),
                                  child: Center(
                                    child: Text(
                                      "${playerControlPanel.dragingSliderTime}/${playerControlPanel.convertDuration(playerData.player.state.duration.inSeconds)}",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  )
                                ),
                              );
                            }
                          ),
              
                          //系统信息窗口(音量/亮度) //优先级应最大
                          Obx((){
                            return Visibility(
                              visible:playerControlPanel.gestureDragingStatus.value,
                              maintainState:playerControlPanel.gestureDragingStatus.value, //maintain 的设立与否 大概是display: none 与 opacity(1) 上的区别吧
                              child: StreamBuilder(
                                stream: playerData.player.stream.volume,
                                builder: (_,snapshot){
                                  return Container(
                                    width: constraint.maxWidth * 1/11,
                                    height: constraint.maxHeight * 1/11,
                                    color:const Color.fromARGB(164, 47, 45, 45),
                                    child: Center(
                                      child: Text(
                                        "volume: ${playerData.player.state.volume}",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    )
                                  );
                                },
                              )
                            );
                          }),
                        
                        ],
                      ),
                    ),
              
                  //播放器控制组件
                  GetBuilder(
                    id: "controlPanel",
                    init: playerControlPanel,
                    builder: (controller) {
                      return Visibility(
                        maintainState: true,
                        maintainAnimation: true, //如需要动画 则必须恒定为true
              
                        visible: playerControlPanel.panelActiveAnimated,
                        //maintainInteractivity: playerControlPanel.panelActiveAnimated,
              
                        child: AnimatedOpacity(
                          opacity: playerControlPanel.panelActiveStatus? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300), //计时完毕时触发 state禁止
                          onEnd:() {

                            if(!playerControlPanel.panelActiveStatus){
                              print("onEnd Close trigged");
                              playerControlPanel.panelActiveAnimated = false;
                            }

                            else{
                              print("onEnd Open trigged");
                              playerControlPanel.panelActiveAnimated = true;
                            }

                            playerControlPanel.toggleControlPanelStatus(); //二次update 响应visible 刷新交互状态

                          },
                          child: const VideoControlPanel(),
                          
                          
                        )
                      );
                    }
                    
                  ),
              
                  //播放完毕的控件遮罩显示
                  Positioned(
                    width: constraint.maxWidth * 2/3,
                    height: constraint.maxHeight * 2/3,
                    child: Obx((){
                      return Visibility(
                        maintainState: playerControlPanel.tempBlurShowFlag.value,
                        visible: playerControlPanel.tempBlurShowFlag.value,
                        child: const PlayerCompletedPanel()
                      );
                    })
                  )
              
                ],
              );
            }
        ),
        
    
      ),
      
      endDrawer: const DrawVideoSelectPanel(),

    );

    
  }

  
}


