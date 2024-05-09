// ignore_for_file: library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_player/catalog/middleWare/videoPageMiddleware.dart';
import 'package:flutter_player/catalog/videoPage.dart';

import 'package:flutter_player/internal/hive.dart';
import 'package:flutter_player/model/playerUI_model.dart';
import 'package:flutter_player/model/video_model.dart';

import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import './catalog/initLoadingPage.dart';

void main() async{
	
	WidgetsFlutterBinding.ensureInitialized();
	// Must add this line.
	
  MediaKit.ensureInitialized();

  if(Platform.isWindows){

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 600),
      minimumSize: Size(900, 650),
      //center: true,
      //backgroundColor: Colors.transparent,
      skipTaskbar: false,
      //titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: true,

    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

  }

  await MyHive.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
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
