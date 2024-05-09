import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/model/playerUI_model.dart';
import 'package:get/get.dart';

class RelatedVideoListItem extends StatelessWidget {
  const RelatedVideoListItem({super.key,required this.relatedVideoInformation});

  final Map<String,dynamic> relatedVideoInformation;

  @override
  Widget build(BuildContext context) {
    
    final playerControlPanel = Get.find<PlayerUIModel>();

    return ListTile(
      title: 
      
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color:Colors.grey, 
          ),
        //既然要获取相关内容 那么就必然需要一块地方来先获取XXX
        // 感觉 可以用FutureBuilder 先获取文字 缺省显示默认Logo 然后再展示图片
              
          child: Stack(
            children: [

              

              CachedNetworkImage(
                imageUrl: relatedVideoInformation["pic"],
                imageBuilder: (_,imageProvider){
                  return Container(
                    width: 260,
                    height: 150,
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

                  print("${progress.downloaded}/${progress.totalSize}");

                  //if(progress.downloaded != progress.totalSize){
                    return Container(
                      width: 260,
                      height: 150,

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
          
              //Image.network(
                    
              //  relatedVideoInformation["pic"],
              //  //[待修改]
              //  //等到widget inspector正常之后查看这个原因
              //  width: 260,
              //  height: 150,
              
              //  loadingBuilder:(context, child, loadingProgress){
          
              //    if(loadingProgress?.cumulativeBytesLoaded == loadingProgress?.expectedTotalBytes){
              //        return ClipRRect(
              //          borderRadius:BorderRadius.circular(16),
              //          child: SizedBox(child: child),
              //        );
              //    }
          
              //    print("loading: $loadingProgress");
              
              //    return Container(
              //      width: 250,
              //      height: 150,
              //      decoration: BoxDecoration(
              //        borderRadius: BorderRadius.circular(16),
              //        color: Colors.grey,
              //      ),
                    
              //      child: const Center(
              //        child: Text("loading..."),
              //      ),
              //    );
          
              //  },
              
              //  fit: BoxFit.cover,
                
              //),
        
              SizedBox(
                width: 260,
                height: 100, //half
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin:Alignment.topCenter,
                      end:Alignment.bottomCenter,
                      colors:[Color.fromARGB(255, 35, 35, 35),Colors.transparent]
                    ),
                          
                  ),
                ),
              ),
        
              Positioned(
                child: Container(
                  constraints: const BoxConstraints( //必须加约束 不然Text无法overflow
                    maxWidth: 250
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text( 
                      relatedVideoInformation["title"],
                      style: const TextStyle(fontSize: 16,color: Colors.white,overflow:TextOverflow.ellipsis),maxLines: 2,),
                  ),
                )
                
              ),
              
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(3)
                  ),
                  //等待重建
                  child: Text( 
          
                    relatedVideoInformation["duration"] is String ?
                    relatedVideoInformation["duration"] :
                    playerControlPanel.convertDuration(relatedVideoInformation["duration"]),
          
                    style: const TextStyle(fontSize: 14))
                )
              ),
          
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(3)
                  ),
                  //等待重建
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow_rounded,size:14),
          
                      Text(
                        playerControlPanel.convertPlayedCount(relatedVideoInformation["stat"]["view"]),
                        style: const TextStyle(fontSize: 14)
                      ),
          
                    ],
                  )
                )
              )
                                            
            ],
          ),
              ),

    );
                     
  }
}