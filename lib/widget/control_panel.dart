
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_player/internal/enum_define.dart';
import 'package:flutter_player/internal/hive.dart';
import 'package:flutter_player/internal/log.dart';
import 'package:flutter_player/internal/video_download.dart';
import 'package:flutter_player/model/player_ui_model.dart';

import 'package:get/get.dart';

import 'package:flutter_player/widget/unvisible_response.dart';
import 'package:flutter_player/widget/component/progress_slider.dart';
import 'package:flutter_player/widget/component/video_qualitiy_label.dart';
import 'package:flutter_player/widget/setting_panel.dart';
import 'package:flutter_player/model/video_model.dart';


class VideoControlPanel extends StatelessWidget {
  const VideoControlPanel({super.key});

  @override
  Widget build(BuildContext context) {

    final playerController = Get.find<VideoModel>();
    final playerControlPanel = Get.find<PlayerUIModel>();

    playerControlPanel.videoControlPanelContext = context;


    return UnVisibleResponse(
      onTap: (){

        //透明度变化 并 等待onEnd完成 animated的变化
        //此时: status: true, animated: true => status: false ..=> animated: false
        playerControlPanel.panelActiveStatus = !playerControlPanel.panelActiveStatus;
        playerControlPanel.toggleControlPanelStatus();

        Log.logprint("panelStatus: status:${playerControlPanel.panelActiveStatus}, animated:${playerControlPanel.panelActiveAnimated}");

      },
      
      child: Scaffold(
        resizeToAvoidBottomInset:false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(

          backgroundColor: Colors.transparent,
          leading: const SizedBox.shrink(),
          leadingWidth: 0.0,
          title: Row(
            children: [
              IconButton(
                onPressed: (){

                  playerController.disposePlayer();
                  playerControlPanel.togglePlayerUIStatus(PlayerStatus.indle);



                }, 
                icon: const Icon(Icons.arrow_back_ios_new_rounded,color: Colors.white)
              ),

              const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
              
              Flexible(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
                  //child: Obx((){
                  //  return Text(
                  //    playerController.currentPlayingInformation["title"]??"",
                  //    style: const TextStyle(color: Colors.white,fontSize: 18),
                  //    maxLines:1,
                  //    overflow: TextOverflow.ellipsis,
                  //  );
                  //})

                  child: GetBuilder(
                    init: playerControlPanel,
                    id: "title",
                    builder: (context) {
                      return Text(
                        playerController.currentPlayingInformation["title"]??"",
                        style: const TextStyle(color: Colors.white,fontSize: 18),
                        maxLines:1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                  )
                  
                ),
              ),
              
            ],
          ),
          
          actions: [

            Obx((){
              return Visibility(
                visible: playerControlPanel.currentPlayingVideoType.value == VideoType.onlineVideo.index ? true : false,
                child: IconButton(

                  //弹出 下载画质选择窗
                  onPressed: () async => showDownloadDialog(),
                  
                  icon: const Icon(Icons.download,size: 26,color: Colors.white)
                ),
              );
            }),

            const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),

            IconButton(
              onPressed: (){
                Log.logprint("trigged endDrawer open");
                playerControlPanel.toggleDrawVideoSelectPanel();
              },
              icon: const Icon(Icons.more_vert_outlined,size: 26,color: Colors.white)
            ),
          ],
            
          //背景色 推荐渐变
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin:Alignment.topCenter,
                end:Alignment.bottomCenter,
                colors:[Color.fromARGB(195, 182, 197, 215),Colors.transparent]
              )
            ),
          ),
        ),
        
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          
          children: [
            
            Expanded(
              child: Center(
                child: 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Spacer(),

                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [     
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 12)),
                              
                          IconButton(
                            onPressed: (){
                              Log.logprint('Panel is locked!');
                            }, 
                            icon: const Icon(Icons.lock_open,color: Colors.white)
                          ),
                                  
                        ],
                      ),
                    ),

                    Expanded(
                      flex: 1,
                        child: 
                          GetBuilder(
                            id:"toast",
                            init: playerControlPanel,
                            builder: (_){
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.linearToEaseOut,
                                transform: Matrix4.translationValues(playerControlPanel.toasterMessageOffset, 0, 0),
                                width: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Row(
                                    children: [
                                      Text(
                                        "已跳转至 ${
                                          playerControlPanel.convertDuration(
                                            (
                                              MyHive.videoRecordDataBase.get(
                                                playerController.currentPlayingInformation["title"],defaultValue: Duration.zero
                                              ) as Duration
                                            ).inSeconds
                                          )
                                          }",
                                        style: const TextStyle(color: Colors.white)
                                      ),
                                      
                                      IconButton(
                                        onPressed: (){
                                          MyHive.videoRecordDataBase.delete(playerController.currentPlayingInformation["title"]);
                                          playerController.player.seek(Duration.zero);
                                        },
                                        icon: const Icon(Icons.refresh)
                                      )
                                    ],
                                  ),
                                )
                              );

                            }
                          )
                      
                    )
                  ],
                ),
              )
                
            ),
              
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin:Alignment.bottomCenter,
                  end:Alignment.topCenter,
                  colors:[Color.fromARGB(98, 182, 197, 215),Colors.transparent]
                )
              ),
              child:
                Theme(
                  data: ThemeData(
                    iconButtonTheme:  IconButtonThemeData(
                    style: ButtonStyle(
                      iconColor: const MaterialStatePropertyAll(Colors.white),
                      iconSize: MaterialStatePropertyAll(max(24, min(36,MediaQuery.sizeOf(context).width/46)))),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(MediaQuery.of(context).padding.bottom + 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                              
                        Obx(() {
                          return IconButton(
                            onPressed: () async {
                              if(playerControlPanel.videoLoadedStatus.value){
                                playerControlPanel.playerStatusToggle();
                              }
                  
                              else{
                                Log.logprint("video was not loaded");
                              }
                  
                              Log.logprint("playing: ${playerControlPanel.playerPlayingStatus.value}, inited: ${playerController.playerinitalFlag}");
                                  
                            }, 
                            icon: playerControlPanel.videoLoadedStatus.value ?
                            playerControlPanel.playerPlayingStatus.value?const Icon(Icons.pause,size: 33,color: Colors.white):const Icon(Icons.play_arrow,size: 33,color: Colors.white) :
                            const Icon(Icons.play_arrow,size: 33,color: Color.fromARGB(102, 158, 158, 158))
                          );
                        },),
            
                        //这里计划是  00:00 o—————— endTime         
                        GetBuilder(
                          id: "video",
                          init: playerController,
                          builder: (context) {
                            return Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18,vertical: 12),
                                child: StreamBuilder(
                                  stream: playerController.player.stream.position, //我猜 这个 也是 旧实例
                                      
                                  builder: (_,snapshot){
                                      
                                    int currentVideoPosition = playerController.player.state.position.inSeconds;
                                                    
                                    return Row(
                                      
                                      children: [
                                
                                        SizedBox(
                                          width: 50,
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: 
                                            
                                              playerControlPanel.currentPlayingVideoType.value != VideoType.onlineStream.index ?
                                              
                                              Obx((){
                                                bool isPlayerInited = playerController.playerinitalFlag.value;
                                                return Text(
                                                  isPlayerInited ?
                                                  playerControlPanel.convertDuration(currentVideoPosition) :
                                                  "00:00" ,
                                                  style: const TextStyle(color: Colors.white)
                                                );
                                              }) :
                            
                                              const Text(
                                                "Live",
                                                style: TextStyle(color: Colors.white,fontSize: 14),
                                              ),
                                          ),
                                        ),
                                      
                                        Flexible(
                                          child: ProgressSlider(videoType: playerControlPanel.currentPlayingVideoType.value,currentPosition:currentVideoPosition)
                                        ),
                                
                                        SizedBox(
                                          width: 50,
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: playerControlPanel.currentPlayingVideoType.value != VideoType.onlineStream.index ?
                                              Obx((){
                                                bool isPlayerInited = playerController.playerinitalFlag.value;
                                                return Text(
                                                  isPlayerInited ?
                                                  playerControlPanel.convertDuration(playerController.player.state.duration.inSeconds) :
                                                  "00:00" ,
                                                  style: const TextStyle(color: Colors.white),
                                                );
                                              }
                                                //child: Text(
                                                //  playerControlPanel.convertDuration(playerController.player.state.duration.inSeconds),
                                                //  style: const TextStyle(color: Colors.white),
                                                //),
                                              ) :
                                              const SizedBox.shrink()
                                          ),
                                        ),
                                      
                                      ]
                                        
                                    );
                                    
                                  }
                                  
                                ),
                              ),
                            );
                          }
                        ),
            
                        //功能按钮聚集地
                        Wrap(
                          direction: Axis.horizontal,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          children: [
                        
                            IconButton(
                              padding: const EdgeInsets.all(0),
                              onPressed: (){

                                Get.dialog(
                                  
                                  Dialog(
                                    insetPadding: EdgeInsets.only(
                                      bottom: MediaQuery.viewInsetsOf(context).bottom
                                    ),
                                    child: 
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(26),
                                          color: const Color.fromARGB(231, 85, 83, 83),
                                        ),
                                        height: 400,
                                        width: 400,
                                        child: const SettingPanel(),
                                      ),

                                  ),

                                  transitionCurve: Curves.ease,
                                  transitionDuration: const Duration(milliseconds: 300)

                                );

                              }, 
                              icon: const Icon(Icons.settings)
                            ),
                        
                            //Volume
                            StreamBuilder(
                              stream: playerController.player.stream.volume,
                              builder: (_,snapshot){
                                return IconButton(
                                  onPressed: (){
                                    Log.logprint("current volume status: ${playerController.player.state.volume}");
                        
                                      if(playerController.isMuted){
                                        playerController.player.setVolume(playerController.videoVolume.toDouble());
                                        playerController.isMuted = false;
                                      }
                        
                                      else{
                                        playerController.player.setVolume(0);
                                        playerController.isMuted = true;
                                      }
                                    
                                  }, 
                                  
                                  icon:Icon(
                                    playerController.player.state.volume == 0.0 ?
                                      Icons.volume_mute :
                                    playerController.player.state.volume < 50 ?
                                    Icons.volume_down :
                                    Icons.volume_up
                                  )
                                  
                                );
                              }
                            ),
                            
                            //QualitiyLabel 
                            SizedBox(
                              height: 30,
                              width: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color:const Color.fromARGB(208, 198, 211, 178), width:1),
                                  borderRadius: BorderRadius.circular(16),
                                  color: const Color.fromARGB(160, 201, 199, 174)
                                ),
                        
                                child: const VideoQualitiyLabel(),
                                
                              ),
                            )
                        
                          ],
                        )
                                        
                      ],
                    ),
              
                  )   
                ),
            )
              
          ],
        )
        
        
      )
    
    );

    
      
  }
}


