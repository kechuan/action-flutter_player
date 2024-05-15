
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';

class StoragePath{
  static const String downloadPath = r'.\downloads';
}

class HttpApiClient{
  static final client = Dio();
  static BaseOptions clientOption = Dio().options;

  static Map<String,String> broswerHeader = {
    "referer": 'https://www.bilibili.com',
    "userAgent": 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
    "cookie": "SESSDATA=${ClientCookies.sessData}" //使用cookies之后 连rcmd请求的数据每次返回都会有变化
  };

}

class ClientCookies{
  static final cookieJar = PersistCookieJar(
    storage: FileStorage(
      './downloads/cookies'
    )
  );

  static String sessData = "";

  //static String sessData = "86798f4f%2C1718429370%2C83234%2Ac2CjDV5t1GPdmyTJ9rDrvtqw3zCXqe3kDX7oZFeUFL3DtC38IDybbDw0DbHH9epBTxr_ASVml1WFV5SnRpUTJYcFNBMUdDRlVmNjQ0a0NCVFU2Y2J3Sk5CTGtoR2RkY1hNYTVBN21EcXhQSE5WVklYbHYtUVRzbS1sU3ZLYng4Y2RhSGRUVW5QeHRnIIEC;";

}

class HttpStatusCode{
  static const List<int> httpStatusCode = [
    200,302,304,400,401,403,404,500,502,503
  ];
}

class SuffixHttpString{
  static const baseUrl = "https://api.bilibili.com";

  static const baseLiveUrl = "https://api.live.bilibili.com";
}

class WebApi{
  static const webInterface = "/x/web-interface";

  static const nav = "$webInterface/nav";
  
}

class PlayerApi{
  static const playerInterface = "/x/player";

  static const playerUri = "$playerInterface/wbi/playurl";
  static const backupPlayerUri = "$playerInterface/playurl";
}

class UserStatusApi{
  static const userSpaceInterface = '/x/space';

  static const userInfo = '$userSpaceInterface/myinfo';
}

class VideoStatusApi{
  static const videoInfoInterface = "${WebApi.webInterface}/view";
}

class SearchApi{
  static const searchInterface = "${WebApi.webInterface}/wbi/search/all/v2";

}

class VideoCatalog{
  static const rcmd = "${WebApi.webInterface}/index/top/feed/rcmd";

  static const related = "${WebApi.webInterface}/archive/related";

  

  static const liveRoom = "${SuffixHttpString.baseLiveUrl}/xlive/web-room/v2/index/getRoomPlayInfo";

  static const backupLiveRoom = "${SuffixHttpString.baseLiveUrl}/room/v1/Room/playUrl";

}

class RequestParams{

  static const aid = "aid";
  static const bvid = "bvid";
  static const cid = "cid";

  static const playLists = "ps";
  static const keyword = "keyword";

  static const fnval = "fnval"; //prefer to video qualify
  static const qn = "qn"; //prefer to Live's qualify
}

class RequestRegExp{
  static RegExp videoIDExp = RegExp(r'^(av|bv|AV|BV)');
}









