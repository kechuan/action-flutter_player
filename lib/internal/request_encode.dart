// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_player/internal/enum_define.dart';
import 'package:flutter_player/internal/log.dart';

import 'package:flutter_player/internal/url_request.dart';
import 'package:flutter_player/model/player_ui_model.dart';
import 'package:flutter_player/model/video_model.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';

String imgKey = "7cd084941338484aae1ad9425b84077c";
String subKey = "4932caff0ff746eab6f01bf08b70ac45";



String parseMixinKey(String imgKey,String subKey){

    String rawWbiKey = "$imgKey$subKey";

    String mixinKey = "";

    List<int> encryTab = [
        46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, 27, 43, 5, 49,
        33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13, 37, 48, 7, 16, 24, 55, 40,
        61, 26, 17, 0, 1, 60, 51, 30, 4, 22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11,
        36, 20, 34, 44, 52
    ];

    for(int currentIndex in encryTab){
        mixinKey+=rawWbiKey[currentIndex];
        if(currentIndex == 13) break;
    }

    Log.logprint("rawWbiKey:$mixinKey");
    return mixinKey;
}

String encodeHTTPRequest(String orignalRequest){

    String finalRequest = "";
    String w_rid = "";

    String currentTimeStamp = (DateTime.now().millisecondsSinceEpoch~/1000).toString();

    String encodeRequest = "$orignalRequest&wts=$currentTimeStamp${parseMixinKey(imgKey,subKey)}";

    w_rid = md5.convert(utf8.encode(encodeRequest)).toString();
    Log.logprint("w_rid:$w_rid");


    finalRequest = "$orignalRequest&w_rid=$w_rid&wts=$currentTimeStamp";

    return finalRequest;

}

void searchRequestResponse(String searchContent){

  final playerController = Get.find<VideoModel>();
  final playerControlPanel = Get.find<PlayerUIModel>();

  switch(playerControlPanel.searchType.value){
    case '搜索':{

      HttpApiClient.client.get(
        SearchApi.searchInterface,
        queryParameters:{
          RequestParams.keyword:searchContent,
        },
      ).then(
        (response){

          if(response.data["code"]==0){

            playerController.onlinePlayList.clear();

            List<dynamic> searchResult = response.data['data']['result'];
            List<dynamic> videoResult = searchResult[searchResult.length-1]['data'];

            for(dynamic currentVideo in videoResult){

              //获取cid。。

              HttpApiClient.client.get(
                VideoStatusApi.videoInfoInterface,
                queryParameters: {
                  RequestParams.bvid:currentVideo["bvid"]
                },

              ).then((response){
                if(response.data["code"]==0){

                  Log.logprint("stat response:${response.data["data"]["cid"]}");

                  if(currentVideo["duration"] is String){

                    List<String> splitDuration = currentVideo["duration"].split(":");

                    for(int i = 0;i<splitDuration.length;i++){
                        splitDuration[i] = splitDuration[i].padLeft(2,'0');
                    }

                    playerController.onlinePlayList.add(
                      {
                        "title":response.data["data"]["title"],
                        "uri":currentVideo["arcurl"], //数值0 根据分P视频变动
                        "pic":response.data["data"]["pic"],
                        "author":response.data["data"]["owner"]["name"],
                        "duration":splitDuration.join(":").toString(),
                        "pubdate":currentVideo["pubdate"],
                        "stat":response.data["data"]["stat"],
                        "bvid":currentVideo["bvid"],
                        "cid":response.data["data"]["cid"],
                        
                      }
                    );

                    playerControlPanel.updateOnlineList();

                  }


                }

              });

            }

            

            

          }

          
          
        }
      );


    }

    case '视频号':{

      if(RequestRegExp.videoIDExp.hasMatch(searchContent)){

        Log.logprint("jump to:$searchContent");

        Map<String,String> params = {};

        if(searchContent.startsWith('av') || searchContent.startsWith('AV')){
          params.addAll({
            RequestParams.aid: searchContent.split('av')[1]
          });
        }

        if(searchContent.startsWith('bv') || searchContent.startsWith('BV')){
          
          params.addAll({
            RequestParams.bvid: searchContent
          });
        }

        HttpApiClient.client.get(
            VideoStatusApi.videoInfoInterface,
            queryParameters: params,

          ).then((response){
            
            if(response.data["code"]==0){

              List<String>? splitDuration;

              Map currentVideo = response.data["data"];

              if(currentVideo["duration"] is String){

                splitDuration = currentVideo["duration"].split(":");

                for(int i = 0;i<splitDuration!.length;i++){
                    splitDuration[i] = splitDuration[i].padLeft(2,'0');
                }

                
              }

              playerController.onlinePlayList.clear();

              playerController.onlinePlayList.add(
                {
                  "title":currentVideo["title"],
                  "uri":"https://www.bilibili.com/video/$searchContent", //数值0 根据分P视频变动
                  "pic":currentVideo["pic"],
                  "author":currentVideo["owner"]["name"],
                  "duration":splitDuration?.join(":").toString() ?? playerControlPanel.convertDuration(currentVideo["duration"]),
                  "pubdate":currentVideo["pubdate"],
                  "stat":currentVideo["stat"],
                  "bvid":currentVideo["bvid"],
                  "cid":currentVideo["cid"],

                }
              );

              playerControlPanel.updateOnlineList();

            }   

             //[待通知]
            else{
              Log.logprint("找不到该视频号:$searchContent,可能已被删除");
            }

        });
        
      }

      else{
        Log.logprint("找不到该视频号:$searchContent,请确认输入格式是否有误");
      }

        
    }

    case 'HLS':{
      liveRoomResponse(orignalRequest:searchContent);
    }

    //算作是Local播放
    case 'URL':{
      playerControlPanel.currentPlayingVideoType.value = VideoType.localVideo.index;
      playerController.loadLocalVideo({"uri":searchContent});

      //但是不为其保留seek 就当是临时视频
      
    }

  }

}

void rcmdRequestResponse([int? playlist]){

  final playerController = Get.find<VideoModel>();
  final playerControlPanel = Get.find<PlayerUIModel>();

  HttpApiClient.client.get(
    VideoCatalog.rcmd,
    queryParameters:{
      RequestParams.playLists:playlist??6,
    },
  ).then(
    (response){
      
      playerController.onlinePlayList.clear();
      
      for(dynamic currentVideo in response.data["data"]["item"]){
        playerController.onlinePlayList.add(
          {
            "title":currentVideo["title"],
            "uri":currentVideo["uri"],
            "pic":currentVideo["pic"],
            "author":currentVideo["owner"]["name"],
            "duration":currentVideo["duration"],
            "pubdate":currentVideo["pubdate"],
            "stat":currentVideo["stat"],
            "bvid":currentVideo["bvid"],
            "cid":currentVideo["cid"],
            //"wts":DateTime.now().millisecondsSinceEpoch~/1000 

          }
        );

      }

      playerControlPanel.updateOnlineList();
    }
  );
  
  
}

void relatedVideoResponse(String? videoID){

  final playerController = Get.find<VideoModel>();
final playerControlPanel = Get.find<PlayerUIModel>();

  if(videoID!=null){

    Log.logprint("videoID:$videoID");

    playerController.onlineRelatedList.clear();

    if(RequestRegExp.videoIDExp.hasMatch(videoID)){

      if(videoID.startsWith('AV')){
        videoID = videoID.toLowerCase();
      }

      if(videoID.startsWith('bv')){
        videoID = videoID.toUpperCase();
      }

      HttpApiClient.client.get(
        VideoCatalog.related,
        queryParameters: {RequestParams.bvid:videoID}
      ).then((response){

        if(response.data["code"]==0){

          List<String>? splitDuration;
         
          for(Map currentVideo in response.data["data"]){

            if(currentVideo["duration"] is String){

              splitDuration = currentVideo["duration"].split(":");

              for(int i = 0;i<splitDuration!.length;i++){
                splitDuration[i] = splitDuration[i].padLeft(2,'0');
              }

            }

            playerController.onlineRelatedList.add({
                "title":currentVideo["title"],
                "uri":"https://www.bilibili.com/video/${currentVideo["bvid"]}",
                "pic":currentVideo["pic"],
                "author":currentVideo["owner"]["name"],
                "duration":splitDuration?.join(":").toString() ?? currentVideo["duration"],
                "pubdate":currentVideo["pubdate"],
                "stat":currentVideo["stat"],
                "bvid":currentVideo["bvid"],
                "cid":currentVideo["cid"],
              });

          }

          playerControlPanel.updateOnlineRelatedList();

        }

      });  

    }

  }


}

void backupliveRoomResponse({required String orignalRequest,int? qn}) async {

  final playerController = Get.find<VideoModel>();
  final playerControlPanel = Get.find<PlayerUIModel>();

  List<dynamic> accept_qualityList = [];

  Map<String,String> videoQualityInforamtion = playerController.currentPlayingInformation['qualityMap'];

  await HttpApiClient.client.get(
        VideoCatalog.backupLiveRoom,
        queryParameters:{
          RequestParams.cid: orignalRequest,
          RequestParams.qn: qn ?? 4,
          
          //avc的编码基本最全 所有画质挡位都有 其余画质挡位可能会有残缺
        },
      ).then(
        (response){

          if(response.data["code"] == 0){

            accept_qualityList = response.data["data"]["quality_description"];

            videoQualityInforamtion.clear();

            playerControlPanel.currentPlayingVideoType.value = VideoType.onlineStream.index;

            playerController.playerVideoLoad(
              video: Media(
                response.data["data"]["durl"][0]["url"],
                extras:{
                  'refer':"www.bilibili.com"
                }
              )
            );

            videoQualityInforamtion.addAll({
             accept_qualityList[0]["desc"] :response.data["data"]["durl"][0]["url"]
            });
            
          }

          else{
            Log.logprint("cid:$orignalRequest,not found!");
          }


          Log.logprint("currentQualify.length :${accept_qualityList.length} currentMap:${playerController.currentPlayingInformation['qualityMap']}");

        }
      );

    //这个是画质挡位 因为0已经添加 所以这里从1开始
    for(int currentQualify = 1; currentQualify < accept_qualityList.length; currentQualify++){

        HttpApiClient.client.get(
        VideoCatalog.liveRoom,
          queryParameters:{
            RequestParams.cid: orignalRequest,
          }
        ).then((response){

          videoQualityInforamtion.addAll({
            accept_qualityList[currentQualify]["desc"]: response.data["data"]["durl"][0]["url"]
          });

        }
      );

    }

}

void liveRoomResponse({required String orignalRequest,int? qn}) async {

  Map<int,String> qn_Map = {
    30000: "杜比",
    20000: "4K",
    10000: "原画",
    400: "蓝光",
    250: "超清",
    150: "高清",
    80: "流畅",
  };  

  final playerController = Get.find<VideoModel>();
  final playerControlPanel = Get.find<PlayerUIModel>();

  Map<String,String> videoQualityInforamtion = playerController.currentPlayingInformation['qualityMap'];

  List<dynamic> accept_qualityList = [];

  bool isAccessSucc = false;

  await HttpApiClient.client.get(
        VideoCatalog.liveRoom,
        queryParameters:{
          RequestParams.cid: orignalRequest,
          RequestParams.qn: qn ?? 10000,
          "room_id": orignalRequest,
          "protocol":1, // [http_stream,http_hls]
          "format":2, //[flv,ts,fmp4]
          "codec":1, //[avc,hevc,av1]

          //avc的编码基本最全 所有画质挡位都有 其余画质挡位可能会有残缺
        },
      ).then(
        (response){

          Log.logprint("response:$response:");

          if(response.data["code"] == 0){

            videoQualityInforamtion.clear();
            playerControlPanel.currentPlayingVideoType.value = VideoType.onlineStream.index;

            if(response.data["data"]["playurl_info"]["playurl"]!=null){

              isAccessSucc = true;

              Map playUrl = response.data["data"]["playurl_info"]["playurl"];
              Map codec_stream = playUrl["stream"][0]["format"][0]["codec"][0];

              accept_qualityList = codec_stream["accept_qn"];

              Log.logprint("3 Part: host > ${codec_stream['url_info'][0]['host']} api > ${codec_stream["base_url"]} params > ${codec_stream["url_info"][0]["extra"]}");

              playerController.playerVideoLoad(
                video: Media(
                  "${codec_stream['url_info'][0]['host']}${codec_stream["base_url"]}${codec_stream["url_info"][0]["extra"]}",
                  extras:{
                    'refer':"www.bilibili.com"
                  }
                )
              );

              videoQualityInforamtion.addAll({
                "原画": "${codec_stream['url_info'][0]['host']}${codec_stream["base_url"]}${codec_stream["url_info"][0]["extra"]}"
              });

            }

            
            
          }

          else{
            Log.logprint("cid:$orignalRequest,not found!");
          }
          

        }
      );

    if(!isAccessSucc){

      Log.logprint("not contain HEVC source.change to AVC source");

      await HttpApiClient.client.get(
        VideoCatalog.liveRoom,
        queryParameters:{
          RequestParams.cid: orignalRequest,
          RequestParams.qn: qn ?? 10000,
          "room_id": orignalRequest,
          "protocol":1, // [http_stream,http_hls]
          "format":2, //[flv,ts,fmp4]
          "codec":0, //[avc,hevc,av1]
        },
      ).then(
        (response){

          Log.logprint("response:$response:");

          if(response.data["code"] == 0){

            videoQualityInforamtion.clear();
            playerControlPanel.currentPlayingVideoType.value = VideoType.onlineStream.index;

            if(response.data["data"]["playurl_info"]["playurl"]!=null){

              isAccessSucc = true;

              Map playUrl = response.data["data"]["playurl_info"]["playurl"];
              Map codec_stream = playUrl["stream"][0]["format"][0]["codec"][0];

              accept_qualityList = codec_stream["accept_qn"];

              Log.logprint("3 Part: host > ${codec_stream['url_info'][0]['host']} api > ${codec_stream["base_url"]} params > ${codec_stream["url_info"][0]["extra"]}");

              playerController.playerVideoLoad(
                video: Media(
                  "${codec_stream['url_info'][0]['host']}${codec_stream["base_url"]}${codec_stream["url_info"][0]["extra"]}",
                  extras:{
                    'refer':"www.bilibili.com"
                  }
                )
              );

              videoQualityInforamtion.addAll({
                "原画": "${codec_stream['url_info'][0]['host']}${codec_stream["base_url"]}${codec_stream["url_info"][0]["extra"]}"
              });

            }
            
          }

          else{
            Log.logprint("cid:$orignalRequest,not found!");
          }

        }
      );


    }



    for(int currentQualify = 1; currentQualify < accept_qualityList.length; currentQualify++){

      await HttpApiClient.client.get(
        VideoCatalog.liveRoom,
          queryParameters:{
            
          "room_id": orignalRequest,
          "protocol":1, // [http_stream,http_hls]
          "format":2, //[flv,ts,fmp4]
          "codec":1, //[avc,hevc,av1]
          RequestParams.qn: accept_qualityList[currentQualify]
          }
        ).then((response){

          Map playUrl = response.data["data"]["playurl_info"]["playurl"];
          Map codec_stream = playUrl["stream"][0]["format"][0]["codec"][0];

          videoQualityInforamtion.addAll({
            qn_Map[accept_qualityList[currentQualify]]! : "${codec_stream['url_info'][0]['host']}${codec_stream["base_url"]}${codec_stream["url_info"][0]["extra"]}"
          });

        }
      );

    }

    Log.logprint("currentQualify.length :${accept_qualityList.length} currentMap:${playerController.currentPlayingInformation['qualityMap']}");

}