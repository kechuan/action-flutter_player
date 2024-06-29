// ignore_for_file: constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_player/internal/hive.dart';
import 'package:flutter_player/internal/log.dart';

import 'package:flutter_player/internal/url_request.dart';
import 'package:get/get.dart';

//import 'package:media_kit/media_kit.dart';

enum VideoQuality{
  Local,
  VeryLow,    //6 -> 240
  Low,        //16 -> 360
  Mediumn,    //32 -> 480
  HD,         //64 -> 720
  FHD,        //80 -> 1080
  FHD_P,      // 112/116 -> 1080+
  UHD         // 4K
}

class UserHive{

  static void setUserConfig(String configName,dynamic data) {
    MyHive.userDataBase.put(configName,data); //覆盖写入 而非 append写入
  }

  static void setAllUserConfig(Map<String,String> userData) {
    MyHive.userDataBase.putAll(userData); //覆盖写入 而非 append写入
  }

  static void removeUserConfig(String configName) {
    MyHive.userDataBase.delete(configName);
  }

  static void clearUserData() async {
    await MyHive.userDataBase.clear();
  }

  static Future<String?> getUserConfig(String configName) async {
    return MyHive.userDataBase.get(configName);
    
  }
  
}

class UserModel{ 
  //用于记录当前播放器的信息 其包括 setting
  //bilibili状态 等
  //不应有实例 统一static抛出

  //player.setPlaylistMode(PlaylistMode.none/loop/single)

  static RxMap<String,dynamic> configList = {
    "cookie":"",
    "qualifiySetting":VideoQuality.FHD.name,
    "encodeSetting":"HEVC",
    "playMode":{'local':'none','online':'none'},
    'iconShow':["download","list"], 
    //如果图标很多 可以考虑做一个reorderList来更改图标的 开启/关闭/顺序什么的
    //但现在图标确实不多
  }.obs;

  //也许真正需要.obs只有一个 就是在编辑 以及退出编辑
  //所有的变动都应基于此前提

  static bool isModifiedCookie = false;

  static RxBool editingCookieFlag = false.obs;
  static RxBool editingCookieFlagAnimated = false.obs;
  static RxBool verifingCookie = false.obs;

  static String cookiesState = "";

  static bool isLogined = false; //感觉也不需要监听 直接读取就行了

  //playList 需求 Media格式 可是Hive能提供的是 String 那么。。 转换 或者是 什么
  //还有个问题 既然你都要写播放列表 那最好直接记录
  // {[AnimateTitle]:[Duration]} 既然记录顺序 也能记录 Duration 直接一举两得 
  //static Playlist localPlayList = const Playlist([]);

  static void init() {

    const List<String> requiredConfig = ['cookie','qualifiySetting','encodeSetting'];

    final Map<String,dynamic> defaultValue = {
      'cookie':"",
      'qualifiySetting':VideoQuality.FHD.name,
      'encodeSetting':'HEVC',
      'playMode':{'Local':'none','online':'none'},
      'playList':{},
    };

    for(int configIndex = 0;configIndex<requiredConfig.length;configIndex++){

      Log.logprint("$configIndex/${requiredConfig.length-1}:${requiredConfig[configIndex]}");

      UserHive.getUserConfig(requiredConfig[configIndex]).then((configValue){

        if(configValue != null && configValue.isNotEmpty){
          Log.logprint("config content:$configValue");

          if(requiredConfig[configIndex] == 'cookie'){
            configList.update('cookie', (value) => configValue);

            //风险性 但是便利
            ClientCookies.sessData = configValue;
            Log.logprint("cookies exists. start verify");

            verfiyCookie(configValue);
          }

        }

        else{
          Log.logprint("${requiredConfig[configIndex]} set value");
          UserHive.setUserConfig(requiredConfig[configIndex],defaultValue[requiredConfig[configIndex]]);
        }

      });
    }

    Log.logprint("user config inited");
    return;

  }

  static void verfiyCookie(String sessdata){

    String requestUri = "${SuffixHttpString.baseUrl}${WebApi.nav}";
    
    //https://api.bilibili.com/x/space/myinfo

    Log.logprint("requestUri:$requestUri data: $sessdata");

    verifingCookie.value = true;

    RegExp sessdataHeader = RegExp("SESSDATA=.*?;");

      Dio().get(
        requestUri,
        options: Options(
          headers: {
            "cookie": sessdataHeader.hasMatch(sessdata) ? sessdata : "SESSDATA=$sessdata" 
          },
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        )
      ).then((response){

        Log.logprint("response:$response");

        switch(response.data['code']){
          case -101:{
            Log.logprint("${response.data['message']}");
            cookiesState = "未生效 将使用原有配置";
            
            break;
          }

          case 0:{
            UserHive.setUserConfig('cookie', sessdata);
            
            cookiesState = "已生效";
            Log.logprint("cookie状态已更新");

              ClientCookies.sessData = sessdata;
              HttpApiClient.broswerHeader.update("cookie", (value) => "SESSDATA=$sessdata");

              HttpApiClient.clientOption.headers = HttpApiClient.broswerHeader;
              HttpApiClient.client.options = HttpApiClient.clientOption;

              isLogined = true;
            
            break;
          }

          default:{
            cookiesState = "链接超时";

          }
        }


        verifingCookie.value = false;

      }
    );


  }

}
