
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/enum_index.dart';
import 'package:flutter_player/internal/request_encode.dart';
import 'package:flutter_player/model/playerUI_model.dart';
import 'package:flutter_player/model/video_model.dart';
import 'package:flutter_player/widget/UnVisibleResponse.dart';
import 'package:flutter_player/widget/localVideoListview.dart';
import 'package:flutter_player/widget/onlineVideoListview.dart';
import 'package:get/get.dart';


const List<String> nameList = ["本地","推荐"];

final ValueNotifier<double> currentIndexNotifier = ValueNotifier<double>(0.0);

class DrawVideoSelectPanel extends StatelessWidget {
  const DrawVideoSelectPanel({super.key});

  @override
  Widget build(BuildContext context) {

    final playerController = Get.find<VideoModel>();
    final playerControlPanel = Get.find<PlayerUIModel>();

    final PageController videoResourceController = PageController(
      initialPage: playerControlPanel.recordVideoResourcePageIndex
    );    
    
    return UnVisibleResponse(
      child: Drawer(
      width: MediaQuery.sizeOf(context).width*1/3 < 400 ? 400 : MediaQuery.sizeOf(context).width*1/3,
      backgroundColor: const Color.fromARGB(231, 85, 83, 83),

      //WillPopScope is JIT way handle popEvent.
      //but PopScope is AOT way handle popEvent.
      //PopScope can't achieve JIT Way to handle Pop Attempt Event and do some Injection. but WillPopScope's onWillPop can.
      //should const canPop false and popScope handle it manually.
      //onPopScope handle completed Pop Event use. : Pop.then(()=>onPopScope())
    
      child: PopScope(
        canPop : false,
        onPopInvoked:(didPop) {
          print("did Pop:$didPop");

          if(MediaQuery.viewInsetsOf(context).bottom > 0 || playerControlPanel.currentOverlayEntry == null){
            print("did close Action");
            Scaffold.of(context).closeEndDrawer();
          }

          if(playerControlPanel.currentOverlayEntry!=null){
            print("did Pop remove");
            playerControlPanel.currentOverlayEntry!.remove();
            playerControlPanel.currentOverlayEntry = null;
            return;
          }

        },
        child: Scaffold(
        
          resizeToAvoidBottomInset:false,
        
          backgroundColor: Colors.transparent, 
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leadingWidth: 0.0,
            leading: const SizedBox.shrink(),
        
            title: Column(
              children: [
                Row(
                    children: [
        
                      ...List.generate(nameList.length,(index){
                        return Expanded(
                          child: Container(
                            constraints: const BoxConstraints.tightFor(height: 32),
                            child: TextButton(
                              
                              onPressed: (){
                                print("switch to ${nameList[index]} page");
                                
                                videoResourceController.animateToPage(index,duration: const Duration(milliseconds: 300),curve: Curves.easeIn);
                                currentIndexNotifier.value = index.toDouble();
                                
                                playerControlPanel.recordVideoResourcePageIndex = index;
        
                                print("width:${(context.findRenderObject() as RenderBox).size.width}");
                                
                              }, 
                              //child: Text(nameList[index],style: const TextStyle(color: Color.fromARGB(255, 22, 27, 33),fontSize: 14))
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(nameList[index],style: const TextStyle(color: Color.fromARGB(255, 22, 27, 33),fontSize: 14)),
        
                                  GetBuilder(
                                    id: "localDownloadList",
                                    init: playerControlPanel,
                                    builder:(controller) {
        
                                      bool taskQueueEmpty = playerController.localDownloadTaskQueue.isEmpty;
        
                                      int activeTaskLength = 0;
        
                                      if(!taskQueueEmpty){
                                        for(Map currentTask in playerController.localDownloadTaskQueue.values){
                                          if(currentTask["rate"] != -1.0){
                                            activeTaskLength+=1;
                                          }
                                        }
                                      }
        
                                      if(nameList[index] != "本地" || taskQueueEmpty || activeTaskLength == 0) return const SizedBox.shrink();
        
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Container(
                                          height: 20,
                                          width: 20,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            color: const Color.fromARGB(149, 219, 250, 222)
                                          ),
                                          child: Center(child: Text("$activeTaskLength")),
                                        ),
                                      );
                                      
                                    },
                                    
                                  )
        
                                ],
                              )
                            ),
                          ),
                        );
                        
                        
        
                      })
        
                    ],
                ),
        
                ValueListenableBuilder(
                  valueListenable: currentIndexNotifier,
                  builder: (_,double currentIndex,__){
        
                    return Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          
                          //原本的padding数值应该是all(12) 但好像有其他因素导致变成了10
                          transform: Matrix4.translationValues(
                            currentIndex*(MediaQuery.sizeOf(context).width*1/3 < 400 ? 180 : MediaQuery.sizeOf(context).width*2/13),
                            0.0,
                            0.0
                          ), // 移动效果 透过矩阵提供xyz坐标以实现
                          alignment: Alignment.centerLeft,
                          height: 2,
                          width: MediaQuery.sizeOf(context).width*1/3 < 400 ? 180 : MediaQuery.sizeOf(context).width*2/13,
                          //width: MediaQuery.sizeOf(context).width > 300 ? MediaQuery.sizeOf(context).width*2/13 : 150,
                          color: Colors.grey,
                        
                        )
                      ],
                    );
                  },
                ),
        
              ],
            )
            
          ),
        
          body: 
            NotificationListener(
            //横向滚动监听
              onNotification: (ScrollUpdateNotification notification) {
                //print("${notification.metrics.axis}");
                final double offset = notification.metrics.pixels;
                if(notification.metrics.axis == Axis.horizontal){
                  currentIndexNotifier.value = max(offset/400,-0.12);
                }
                
                return false;
              },
              child: Theme(
                data: ThemeData(
                  scrollbarTheme: ScrollbarThemeData(
                    trackVisibility: MaterialStateProperty.all(false),
                    thumbVisibility: MaterialStateProperty.all(false)
                  )),
                child: EasyRefresh( //easyRefresh 兼顾刷新 与 滑动手势
                //callRefreshOverOffset:5,
                //spring: const SpringDescription(mass: 5,stiffness: 300,damping: 0.25),
        
                controller: EasyRefreshController(),
                header: const MaterialHeader(
                  triggerOffset :50, // 因为逻辑像素的原因 横屏刷新下 这个Offset的要求也苛刻多了
                ),
                triggerAxis:Axis.vertical,
                onRefresh: (){
        
                  if(videoResourceController.page!.toInt() == VideoResource.local.index){
                    print("local refresh");
                  }
        
                  if(videoResourceController.page!.toInt() == VideoResource.online.index){
                    print("rcmd refresh");
        
        
                    try{
                      rcmdRequestResponse();
                      
                    }
        
                    on DioException catch(error){
                      print(error);
                      //根据错误的不同 应弹出不同的。。toaster?
                    }
                  }
        
                },
                child: Obx((){
        
                  bool searchingFocus = playerControlPanel.searchingFocus.value;
        
                  print("searchFocus:$searchingFocus");
        
                  return PageView(
                    physics: searchingFocus?const NeverScrollableScrollPhysics():null,
                    controller: videoResourceController,
                    
                    children: const [
                      LocalVideoListView(),
                      OnlineVideoListview()
                    ],
                  );
                })
                
                
              )
              
            )
        
          ),  
        ),
      )
    ),
    );

     
  }
}