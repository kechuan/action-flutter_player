

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_player/model/playerUI_model.dart';

import 'package:flutter_player/model/video_model.dart';
import 'package:get/get.dart';

import 'package:cached_network_image/cached_network_image.dart';

class OnlineVideoListItem extends StatelessWidget {
  const OnlineVideoListItem({super.key,required this.rcmdVideoInformation});

  final Map<String,dynamic> rcmdVideoInformation;


  @override
  Widget build(BuildContext context) {

    final playerController = Get.find<VideoModel>();
    final playerControlPanel = Get.find<PlayerUIModel>();

    return ListTile(
      title: Column(
        children: [
          Row(
            
            children: [

              const Padding(padding: EdgeInsets.only(left:12)),

              SizedBox(
                width: 150,
                height: 80,
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [

                    CachedNetworkImage(
                      imageUrl: rcmdVideoInformation["pic"],
                      imageBuilder: (_,imageProvider){
                        return Container(
                          width: 150,
                          height: 80,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(16)
                          ),
                        );
                      },
                      progressIndicatorBuilder: (context, url, progress) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey,
                          ),
                          child: const Center(
                            child: Text("loading..."),
                          ),
                        );
                      },
                    ),

                    Positioned(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          borderRadius: BorderRadius.circular(3)
                        ),
                        child: Text(
                          rcmdVideoInformation["duration"] is String ?
                          rcmdVideoInformation["duration"] :
                          playerControlPanel.convertDuration(rcmdVideoInformation["duration"]),

                          style: const TextStyle(fontSize: 13),)
                      )
                    )
                
                  ],
                )
              ),

              Expanded(
                child: Row(
                  children: [
                    Wrap(
                      direction: Axis.vertical,
                      spacing: 12,
                      children: [
                    
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: min(400,MediaQuery.sizeOf(context).width/7),
                                  maxHeight: 80,
                                ),
                                child: Text(
                                  rcmdVideoInformation["title"],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16),
                                )
                                
                              ),

                              rcmdVideoInformation["title"] == playerController.currentPlayingInformation["title"] ?
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.ring_volume,color: Colors.white),
                              ) :
                              const SizedBox.shrink()
                              
                            ],
                          )
                        
                        ),
                        
                        Theme(
                          data: ThemeData(
                            iconTheme:const IconThemeData(
                              color: Color.fromARGB(103, 248, 187, 208)
                            )
                          ),
                          child: SizedBox(
                            width: 180,
                            height: 24,
                           
                            child: Wrap(
                              spacing: 3,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              
                              children: [
                            
                                const Icon(Icons.upload),
                                ConstrainedBox(
                                  //给Text组件一个明确的约束 这样才会触发overflow机制
                                  constraints: const BoxConstraints.tightFor(width: 55),
                                  child: Text(
                                    rcmdVideoInformation["author"],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                                  
                                const Icon(Icons.play_arrow_rounded),
                                Text(
                                  playerControlPanel.convertPlayedCount(rcmdVideoInformation["stat"]["view"]),
                                  style: const TextStyle(fontSize: 12)
                                ),
                            
                                PopupMenuButton(
                                  itemBuilder: (context) {
                                    return List.generate(
                                      3, 
                                      (index) =>  PopupMenuItem(
                                        value: index,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            
                                            Text("$index")
                                          ],),
                                      ),
                                    );
                                  },
                            
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints.tight(const Size(24,24)),
                                    child: const Icon(Icons.more_vert),
                                  ),
                            
                                  onSelected: (index){
                                    print(index);
                                  },
                                  
                            
                                )
                            
                            
                              ],
                            ),
                          )
                    
                        ),
                        
                      ],
                    ),

                    
                  ],
                )
              )
            ],
          ),
      
          const Divider(thickness: 1),
        ],
      ),

      contentPadding: const EdgeInsets.all(0),

      

    );
  }
}