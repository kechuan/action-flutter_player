// ignore_for_file: library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//import 'package:flutter_player/catalog/middleWare/videoPageMiddleware.dart';
import 'package:flutter_player/catalog/videoPage.dart';

import 'package:flutter_player/internal/hive.dart';
import 'package:flutter_player/model/playerUI_model.dart';
import 'package:flutter_player/model/video_model.dart';

import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

import './catalog/initLoadingPage.dart';

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

    runApp(const MyApp());

  }

  else{

    var storagePermission = await Permission.manageExternalStorage.request();

    if(storagePermission.isGranted){
      print("external permission given.");
      await MyHive.init();

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
        )
      );

      SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft]
      ).then((value) => {
        print("apply Android landscape."),
        
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
    //print("your device size/ratio:${MediaQuery.sizeOf(context)},${MediaQuery.of(context).devicePixelRatio}");
    //Get.snackbar("size:","${MediaQuery.sizeOf(context)}");
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
}
