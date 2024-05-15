
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/model/user_model.dart';
import 'package:flutter_player/model/video_model.dart';
import 'package:get/get.dart';

class DownloadQualifySelectPanel extends StatelessWidget {
  const DownloadQualifySelectPanel({super.key});

  //面板里面 应显示: 画质/Size(画饼:如果是多P视频 你还得那什么 所以应该显示listview)

  //格式 [name] Size
  @override
  Widget build(BuildContext context) {

    final playerData = Get.find<VideoModel>();

    final RxInt selectedQualifyItem = 0.obs;
    //final RxList selectedVideoItem = [].obs;

    final RxMap selectedVideoItems = {}.obs;
    // {name:QualifyIndex}

    Map<String,String> qualityMap = playerData.currentPlayingInformation["qualityMap"];

    selectedVideoItems.clear();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //画质挡位(可滑动/点击)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text("画质选择 ${UserModel.isLogined?"":"(游客模式)"}",style: const TextStyle(fontSize: 16,fontWeight:FontWeight.bold)),
            
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: ScrollbarTheme(
                      data: const ScrollbarThemeData(
                        trackVisibility: MaterialStatePropertyAll(false),
                        thumbVisibility: MaterialStatePropertyAll(false),
                        thumbColor: MaterialStatePropertyAll(Colors.transparent),
                        trackColor: MaterialStatePropertyAll(Colors.transparent)
                      ),
                      child: EasyRefresh(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ...List.generate(
                              playerData.currentPlayingInformation["qualityMap"].length,
                              (index){
                                return Obx(
                                  (){
                                    return DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: 
                                            selectedQualifyItem.value == index ? 
                                            const BorderSide(width: 2) : 
                                            BorderSide.none
                                        )
                                      ),
                                      child: TextButton(
                                        
                                        onPressed: (){
                                          //print("size Length:${playerData.currentPlayingInformation["size"].length}");
                                          //print(qualityMap.values.elementAt(index));
                                          selectedQualifyItem.value = index;
                                        },
                                        child: Text(qualityMap.keys.elementAt(index),style:  TextStyle(color: playerData.currentPlayingInformation["size"][index] != null ? Colors.white : Colors.grey),)
                                      ),
                                    );
                                  }
                                );
                              }
                            )
                                    
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("视频列表:",style: TextStyle(fontSize: 16)),
          ),

          SizedBox(
            height: 180,
            child: ListView.builder(
              itemCount: 1,
              itemExtent: 60,
              itemBuilder: (_,videoIndex){
                return Obx(
                  (){
                    //[待修改] 不好的逻辑 因为多P的视频逻辑就肯定不会是这样
                    String? videoTitle = playerData.currentPlayingInformation["title"];
                    double? videoSize = playerData.currentPlayingInformation["size"][selectedQualifyItem.value];

                    //TODO 修改select的 高亮颜色形状 以及默认的 selectvideoIndex 还有记得修改整个Theme里的默认的主题色(Text文字)
                    return Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),

                          border: videoSize!=null ?
                            Border.all(width: 1,color: selectedVideoItems.keys.contains(videoTitle) ? Colors.pink.shade100 : Colors.black ) :
                            Border.all(width: 1,color: Colors.grey)
                          ),
                        child: ListTile(
                          enabled : videoSize!= null ? true : false,
                          title: Text(videoTitle??"",maxLines: 1,overflow: TextOverflow.ellipsis),
                          trailing: Text("${videoSize?.toStringAsFixed(2)}MB",style: const TextStyle(fontSize: 13,color: Colors.black),),
                          onTap: (){
                            //print("start to download");

                            if(playerData.currentPlayingInformation["size"][selectedQualifyItem.value]!=null){

                              if(selectedVideoItems.keys.contains(videoTitle)){
                                selectedVideoItems.remove(videoTitle);
                              }
                              else{
                                selectedVideoItems.addAll({videoTitle:selectedQualifyItem});
                              }

                              return;

                            }

                            print("wrong. not add");

                            
                              
                          },
                        ),
                      ),
                    );
                  }
                  
                );
              },
              
            ),
          ),
          
          const Spacer(),

          const Divider(),

          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            
                Obx((){
                  return Text("已选择数量: ${selectedVideoItems.length}/1");
                }),
            
                Wrap(
                spacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                      }, 
                      child: const Text("取消",style: TextStyle(color: Colors.black))
                    ),
                
                    Obx(
                      (){

                        double? videoSize;

                        if((playerData.currentPlayingInformation["size"] as List).isNotEmpty){
                          videoSize = playerData.currentPlayingInformation["size"][selectedQualifyItem.value];
                        }

                        else{
                           videoSize = null;
                        }
                        
                        return ElevatedButton(
                          onPressed: (){

                            if(selectedVideoItems.isNotEmpty){
                              Navigator.of(context).pop(
                                selectedVideoItems
                              ); //pop vaflue here.
                            }
   
                          },
                          child:  Text("确定",style: TextStyle(color: videoSize!=null ? Colors.black : Colors.grey),)
                        );
            
                      }
                      
                    )
                  ],
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }
}