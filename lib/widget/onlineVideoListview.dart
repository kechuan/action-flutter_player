
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_player/internal/enum_define.dart';
import 'package:flutter_player/internal/hive.dart';
import 'package:flutter_player/internal/request_encode.dart';
import 'package:flutter_player/internal/show_textfield_overlay.dart';
import 'package:flutter_player/model/playerUI_model.dart';
import 'package:flutter_player/model/video_model.dart';
import 'package:flutter_player/widget/UnVisibleResponse.dart';
import 'package:flutter_player/widget/component/online_listItem.dart';
import 'package:get/get.dart';

class OnlineVideoListview extends StatelessWidget {
  const OnlineVideoListview({super.key});

  @override
  Widget build(BuildContext context) {

    final playerController = Get.find<VideoModel>();
    final playerControlPanel = Get.find<PlayerUIModel>();

    final searchFieldController = TextEditingController();
    final FocusScopeNode searchFieldFocus = FocusScopeNode();

    //if(Platform.isAndroid){
    //  searchFieldFocus.addListener(() {
    //    print("searchFieldFocus trigged");
    //    print("text:${searchFieldController.value.text}");
    //    if(searchFieldController.value.text.isNotEmpty && !searchFieldFocus.hasFocus){
    //      print("Overlay search");
    //      searchRequestResponse(searchFieldController.value.text);
    //    }
    //  });
    //}

      return Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LayoutBuilder(
              builder: (_,consraint){
            
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(width: 1,color: const Color.fromARGB(149, 78, 123, 151)),
                    borderRadius: BorderRadius.circular(24)
                  ),
                  child: Row(
            
                    crossAxisAlignment: CrossAxisAlignment.center,
            
                    children: [
            
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 48,
                          maxWidth: 80
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
            
                        child: Obx((){
                                              
                          List<String> nameList = ["搜索","AV/BV","HLS","URL"];
                          List<String> valueList = ["搜索","视频号","HLS","URL"];
                                              
                          List<Icon> iconList = const [
                            Icon(Icons.search),
                            Icon(Icons.numbers),
                            Icon(Icons.tap_and_play),
                            Icon(Icons.link)
                          ];
                                                                 
                          return PopupMenuButton<String>(
                            initialValue: playerControlPanel.searchType.value,
                            itemBuilder: (context) {
                                              
                              return List.generate(
                                nameList.length, 
                                (index) =>  PopupMenuItem(
                                  value: valueList[index],
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      iconList[index],
                                      Text(nameList[index])
                                    ],),
                                ),
                              );
                            },
                                              
                            onSelected: (selectedValue){
                              playerControlPanel.searchType.value = selectedValue;
                              print("selected:$selectedValue");
                              
                            },
                                              
                            child: SizedBox(
                              height: 48,
                              child: Row(
                                
                                children: [
                              
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: iconList[valueList.indexOf(playerControlPanel.searchType.value)],
                                    ),
                                  ),
                              
                                  const Icon(Icons.arrow_drop_down)
                              
                                ],
                              ),
                            ),
                                              
                          );
                                                         
                        }),
                      ),
            
                      SizedBox(
                        width: consraint.maxWidth*3/5,
                        height: 48,
                        child: SingleChildScrollView(
                          physics: playerControlPanel.searchingFocus.value?const NeverScrollableScrollPhysics():null,
                          //physics: const AlwaysScrollableScrollPhysics(),
                          //滚动 是光标选择的关键 我要怎么受限这个滚动效果只停留在内层 不在外层?
                          
                          //使用内部的TextField时 不应响应外部的拖拽 FocusNode内容
                          child: 
                            TextField(
                              decoration: const InputDecoration(border: InputBorder.none),
                              focusNode: searchFieldFocus,
                              controller: searchFieldController,
                                                
                              onTapAlwaysCalled: true,
                              onTap: () {

                                if(Platform.isAndroid){
                                  
                                  TextFieldOverlay(
                                    searchType:true,
                                    name: playerControlPanel.searchType.value,
                                    context: context,
                                    outerTextEditingController: searchFieldController,
                                    outerFocusNode: searchFieldFocus,
                                  );


                                }

                                else{
                                  playerControlPanel.searchingFocus.value = true;
                                }
                                


                              },
                                                
                              onChanged: (value) {
                                playerControlPanel.searchingFocus.value = true;
                              },

                              
                              
                              onEditingComplete: () {
                                print("editing completed trigged");
                                playerControlPanel.searchingFocus.value = false;
            
                                print("searchContent:${searchFieldController.value.text}");
                                searchRequestResponse(searchFieldController.value.text);
            
                              },
                              
                              onTapOutside: (pointerDownEvent){
                                playerControlPanel.searchingFocus.value = false;
                              },
                              
                              maxLines: 1,
               
                            )
       
                        ),
                      )
                      
                    ]
            
                  )
            
                );
              }
            ),
          ),

          GetBuilder(
            id: "onlineList",
            init: playerControlPanel,
            builder: (controller) {
              print("playerController.onlinePlayList.length:${playerController.onlinePlayList.length}");
              
              return Expanded(
                child: 
                  ListView.builder(
                    itemExtent: 110,
                    shrinkWrap:true,
                    itemCount: max(1,playerController.onlinePlayList.length),
                    itemBuilder: (_,index){

                      if(playerController.onlinePlayList.isEmpty){
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text("空空如也...",style: TextStyle(fontSize: 16)),
                              ),
                              
                              Text("请上滑以载入在线推荐资源")
                            ],
                          )
                        );
                      }
                      
                      Map<String,dynamic> currentVideoInformation = playerController.onlinePlayList[index];
                  
                      //这里计划读取 playerController的内容 然后Obx监听它 以刷新
                      //不过现在先搭个框架吧
                      return UnVisibleResponse(
                      
                        onTap: () async {
                          
                          print("try parsing ${currentVideoInformation["title"]},bvid:${currentVideoInformation["bvid"]},cid:${currentVideoInformation["cid"]}}");
                          //print("it hited, uri: ${currentVideoInformation["uri"]}");
                          //此时可以在player中间显示loading... 

                          if(playerControlPanel.currentPlayingVideoType.value == VideoType.localVideo.index){
                            await MyHive.videoRecordDataBase.put(playerController.currentPlayingInformation["title"], playerController.player.state.position); 
                            //保留本地视频进度
                          }
 
                          playerController.loadOnlineVideo(currentVideoInformation);

                          playerControlPanel.currentPlayingVideoType.value = VideoType.onlineVideo.index;

                          playerControlPanel.updateOnlineList();
                          playerControlPanel.updatePanelTitle();
                  
                        },
                  
                        child: OnlineVideoListItem(rcmdVideoInformation:currentVideoInformation)
                      );
                  }
                ),
                );
            },
          )
        ],
      );
        
    
    
    
  }
}