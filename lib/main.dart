
import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//import 'package:flutter_player/catalog/middleWare/videoPageMiddleware.dart';
import 'package:flutter_player/catalog/video_page.dart';

import 'package:flutter_player/internal/hive.dart';
import 'package:flutter_player/internal/log.dart';
import 'package:flutter_player/model/player_ui_model.dart';
import 'package:flutter_player/model/video_model.dart';

import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flutter_player/catalog/init_loading_page.dart';

void main() async{
	
	WidgetsFlutterBinding.ensureInitialized();
	// Must add this line.
  MediaKit.ensureInitialized();


  if(Platform.isWindows){

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 650),
      minimumSize: Size(900, 650),
      skipTaskbar: false,
      windowButtonVisibility: true,

    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    await MyHive.init(); 

    //这个Init 实际上就包含了 下载目录指定/HiveBox初始化 在里面
    //做不到像其他人项目那样 将单独某个服务 分割为 GetService

    //但是有一点 我好像能分离 就是下载的整个生命周期行为 我可以把它抽离开
    //比如:Download这个事件里
    //我可以 直接独立一个Service 恢复任务/继续任务/updateQueue等等这种

    //但是我这里设计的项目里 下载事件非常耦合UI的更新 具体体现在onProgressRecived回调里
    //我估摸着就算我把它分离开 我也少不了像这样

    //我了解的其他做法 则是划分了 Download_View(控件控制Download_comic)/
    //Download_comic(Download_Comic控制Download_View 的 UI更新)/
    //以及Download_Box(Download_Comic状态变更后控制Box)

    //老实说 这样处理 非常非常的麻烦。甚至比我这样的粗糙模型都要麻烦的多
    //在我看来这样自然是解耦了 但这就好像在用4.00-5.00x倍的精力去 收获1.00x(甚至不明白这到底是否有1.00x?)的效果
    //但你说要是我也把我的下载事件进行解耦 我做的肯定只会比它更差 精力损耗也只会比它更高

    //唉 还是去用简单封装的解耦吧



    runApp(const MyApp());

  }

  else{

    var storagePermission = await Permission.manageExternalStorage.request();

    if(storagePermission.isGranted){
      Log.logprint("external permission given.");
      await MyHive.init();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ));

      SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft,DeviceOrientation.landscapeRight]
      ).then((value) => {
        Log.logprint("apply Android landscape."),
        
        runApp(const MyApp())
      });
    }

    else{
      Get.snackbar("", "请授予存储权限用于保存下载目录");
      Permission.manageExternalStorage.request();


    }

  }

}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context,orientation) {
        Log.logprint("当前的屏幕方向:$orientation");
        return GetMaterialApp(
            theme: ThemeData(
              scrollbarTheme: const ScrollbarThemeData(
                thumbColor: MaterialStatePropertyAll(Color.fromRGBO(208, 224, 140, 0.506)),
                thickness: MaterialStatePropertyAll(4),
              )
            ),
            initialRoute: "/initLoading",
        
            getPages: [
              GetPage(name: '/initLoading', page: () => const FutureWaitingPage()),
        
              GetPage(
                name: '/video', 
                page: () => const VideoPage(),
                transition: Transition.downToUp,
                transitionDuration: const Duration(milliseconds: 500),
        
                binding: BindingsBuilder((){
                  Get.put<VideoModel>(VideoModel());
                  Get.put<PlayerUIModel>(PlayerUIModel());
                }),
        
                //middlewares: [
                //  VideoPageMiddleWare()
                //]
        
              ),
            
            ],
        
            defaultTransition: Transition.zoom,
            transitionDuration: const Duration(milliseconds: 500),
        
            builder:(context, child) {
              return Container(
                child: child
              );
            }
        );
      }
    );
		 
  }
}
