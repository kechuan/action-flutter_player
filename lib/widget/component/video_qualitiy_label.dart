
import 'package:flutter/material.dart';
import 'package:flutter_player/internal/enum_define.dart';
import 'package:flutter_player/internal/log.dart';
import 'package:flutter_player/internal/url_request.dart';
import 'package:flutter_player/model/player_ui_model.dart';
import 'package:flutter_player/model/user_model.dart';
import 'package:flutter_player/model/video_model.dart';
import 'package:get/get.dart';

import 'package:media_kit/media_kit.dart';

class VideoQualitiyLabel extends StatelessWidget {
  const VideoQualitiyLabel({super.key});

  @override
  Widget build(BuildContext context) {

    final playerController = Get.find<VideoModel>();
    final playerControlPanel = Get.find<PlayerUIModel>();

    //区分 Local/Stream/Video模式下的 设置
    return Center(
      child: StreamBuilder(
        //似乎不会监听播放器被销毁时的回调
        stream: playerController.player.stream.videoParams, 
        builder: (_,snapshot){

          bool isSelectable = true;

          String currentVideoResolution = "";

          VideoParams currentPrams = playerController.player.state.videoParams;

          Log.logprint("codec:${playerController.player.state.tracks.video.last.codec}");

          if(currentPrams.h == null){
            currentVideoResolution = "N/A";
            isSelectable = false;
          }

          else{
            if(playerControlPanel.currentPlayingVideoType.value == VideoType.localVideo.index){
              isSelectable = false;
            }

            currentVideoResolution = "${currentPrams.h.toString()}P";
          }

          Map<String,String> qualifyLabel = {};


          if(playerController.currentPlayingInformation['qualityMap'].isEmpty){

          }

          else{
            qualifyLabel = playerController.currentPlayingInformation['qualityMap'];
          }

          return PopupMenuButton<String>(
            initialValue: "N/A",
            itemBuilder: (context) {
              return List.generate(
                playerController.currentPlayingInformation['qualityMap']?.length ?? 0, 
                (index) => PopupMenuItem<String>(
                  value: qualifyLabel.values.elementAt(index),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(qualifyLabel.keys.elementAt(index))
                    ],),
                ),
              );
            },
            enabled:isSelectable,
            tooltip: isSelectable?null:"",
            color: const Color.fromARGB(255, 232, 244, 214),

            onOpened: () {
              Log.logprint("${playerController.player.state.tracks.video.last.codec}");
            },
                              
            onSelected: (selectedValue){

              Log.logprint("selected:$selectedValue");

              if(playerController.player.state.tracks.video.last.codec != UserModel.configList["encodeSetting"].toString().toLowerCase()){

                Log.logprint("${playerController.player.state.tracks.video.last.codec} => ${UserModel.configList["encodeSetting"].toString().toLowerCase()}");

                if(playerController.player.state.tracks.video.last.codec == "h264" && UserModel.configList["encodeSetting"].toString().toLowerCase() == "avc"){
                  playerController.playerHotSwitch(selectedValue);
                  return;
                }

                playerController.parsingVideo(
                  orignalUrl: "${SuffixHttpString.baseUrl}${PlayerApi.playerUri}?bvid=${playerController.currentPlayingInformation["bvid"]}&cid=${playerController.currentPlayingInformation["cid"]}&high_quality=1&platform=html5&qn=112",
                  dashFlag: true
                ); //Dash Request
                //重新解析
              }

              else{
                Log.logprint("hot selected");
                playerController.playerHotSwitch(selectedValue);
              }

            },

            child: Text(currentVideoResolution,style: TextStyle(color: currentVideoResolution=="本地"?null:Colors.white),),
                              
          );

        }
      )

    );
  }
} 