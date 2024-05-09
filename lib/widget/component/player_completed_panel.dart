


import 'dart:math';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

import 'package:flutter_player/internal/enum_define.dart';
import 'package:flutter_player/internal/request_encode.dart';
import 'package:flutter_player/internal/url_request.dart';
import 'package:flutter_player/model/playerUI_model.dart';

import 'package:flutter_player/model/video_model.dart';
import 'package:flutter_player/widget/UnVisibleResponse.dart';
import 'package:flutter_player/widget/component/related_listitem.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';

class PlayerCompletedPanel extends StatelessWidget {
  const PlayerCompletedPanel({super.key});

  @override
  Widget build(BuildContext context) {
    
    final VideoModel playerController = Get.find<VideoModel>();
    final PlayerUIModel playerControlPanel = Get.find<PlayerUIModel>();

    relatedVideoResponse(playerController.currentPlayingInformation["bvid"]);

    print("TimeStamp: ${DateTime.now().millisecondsSinceEpoch} completedPanel build");


    return UnVisibleResponse(
      onTap: (){
        playerControlPanel.toggleControlPanelStatus();
      },
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          
          children: [
                              
            Obx((){
              return Row( //attention constraint!
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 600
                    ),
                    child: Text(
                      playerController.currentPlayingInformation["title"],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Color.fromARGB(255, 173, 196, 128)
                      ),
                    ),
                  ),
                              
                  UnVisibleResponse(
                    
                    onTap: (){

                      //print("replay it video:${playerController.currentPlayingInformation["videoUrl"]},audio:${playerController.currentPlayingInformation["audioUrl"]}");

                      playerController.playerVideoLoad(
                        Media(
                          playerController.currentPlayingInformation["videoUrl"],
                          httpHeaders:HttpApiClient.broswerHeader
                        ),
                        playerController.currentPlayingInformation["audioUrl"]
                      );

                      
                    },
                    child: const Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                              
                      spacing: 12,
                              
                      children:  [
                              
                        Text(
                          "Replay",
                          style: TextStyle(
                            fontSize:18,
                            color: Colors.white
                          )
                        ),
                              
                        Icon(Icons.replay,color: Colors.white)
                        
                      ],
                    ),
                  )
                              
                ],
              );
            }),
                              
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 12),

             
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  const Text("相关视频",
                  style: TextStyle(
                    fontSize:18,
                    color: Colors.black
                  ),),

                  Text(
                    "UP: ${playerController.currentPlayingInformation["author"]}",
                    style: const TextStyle(
                      fontSize:18,
                      color: Colors.black
                    ),
                  ),

                ],
              ),
            ),
                              
            const Spacer(),
                              
            Expanded(
              flex: 3,
              child: 
                EasyRefresh( //这里应该预先返回Future 的 initalData 然后再逐步替换回普通的data
                  child: GetBuilder(
                    init: playerControlPanel,
                    id: "onlineRelatedList",
                    builder: (_){
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        
                        itemCount: max(1,playerController.onlineRelatedList.length),
                        itemExtent: 300,
                        itemBuilder: (_,index){

                          if(playerController.onlineRelatedList.isEmpty){
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text("相关列表 空空如也?",style: TextStyle(fontSize: 16)),
                            );
                          }

                          Map<String,dynamic> currentRelatedVideoInformation = playerController.onlineRelatedList[index]; 
                        //这里么 至少你也得先把基础信息写上去再来吧
                                
                          return UnVisibleResponse(
                        onTap: (){
                          print("click $index:$currentRelatedVideoInformation");

                          //[待封装]

                          //playerControlPanel.togglePlayerUIStatus(PlayerStatus.loading);
                          playerControlPanel.togglePlayerUIStatus(PlayerStatus.loading);

                          playerController.currentPlayingInformation["title"] = currentRelatedVideoInformation["title"];
                          playerController.currentPlayingInformation["author"] = currentRelatedVideoInformation["author"];
                          playerController.currentPlayingInformation["bvid"] = currentRelatedVideoInformation["bvid"];


                          playerController.parsingVideo("${SuffixHttpString.baseUrl}${PlayerApi.playerUri}?bvid=${currentRelatedVideoInformation["bvid"]}&cid=${currentRelatedVideoInformation["cid"]}&high_quality=1&platform=html5&qn=112",true); //Dash Request

                        },
                        
                        child: RelatedVideoListItem(relatedVideoInformation:currentRelatedVideoInformation)

                      );
                    }
                  );
                
                  })
                    
                )  
            ),

            const Spacer(),
                              
                              
          ],
        ),
    );

  }
}