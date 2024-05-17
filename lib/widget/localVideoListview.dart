

import 'dart:io';
import 'dart:math';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter_player/internal/convert_task_queue_information.dart';
import 'package:flutter_player/internal/enum_define.dart';
import 'package:flutter_player/internal/file_pick.dart';

import 'package:flutter_player/internal/hive.dart';
import 'package:flutter_player/internal/url_request.dart';
import 'package:flutter_player/internal/video_download.dart';
import 'package:flutter_player/model/playerUI_model.dart';

import 'package:flutter_player/model/video_model.dart';
import 'package:get/get.dart';

final videoFliter = RegExp(r'mkv|mp4|flv|webv|m2ts|rmvb$');

class LocalVideoListView extends StatelessWidget {
  const LocalVideoListView({super.key});

  @override
  Widget build(BuildContext context) {

    final playerController = Get.find<VideoModel>();
    final playerControlPanel = Get.find<PlayerUIModel>();

    return DropTarget(
      onDragDone: (data) async {
        for(int currentIndex = 0; currentIndex<data.files.length; currentIndex++){
          var currentFileInformation = data.files.elementAtOrNull(currentIndex);
      
          if(videoFliter.hasMatch(currentFileInformation!.name)){
            print(currentFileInformation.name);
      
            playerController.localPlayList.add(
              {
                "title":currentFileInformation.name,
                "uri":currentFileInformation.path,
              }
            );
      
          }
                                                                                  
        }

        playerControlPanel.updateLocalList();
      
        //但是player里面还有playerList 还没用过 试试用用看
        
      },

      child: 
        Stack(
          children: [
              //这里我要记录的是 localPlayList信息 只要这个发生变动 其余信息也接着刷新就行了
            Column(
              children: [

                //播放列表栏位
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [

                        IconButton(
                          onPressed: (){
                            print("toggle collapse of expaned");
                            playerControlPanel.localPlayListExpanded.value = !playerControlPanel.localPlayListExpanded.value;
                            playerControlPanel.updateLocalList();
                          }, 

                          //默认   展开 Icons.arrow_forward_ios_rounded 
                          icon: Obx((){ 
                            return Icon(
                              playerControlPanel.localPlayListExpanded.value ?
                              Icons.keyboard_arrow_down_rounded :
                              Icons.keyboard_arrow_right_outlined ,
                              size: 20,
                            );
                          }),
                          
                          color: Colors.black,
                          
                        ),

                        const Padding(padding: EdgeInsets.symmetric(horizontal: 12),child:Text("播放列表")),

                        GetBuilder(
                          init: playerControlPanel,
                          id: "localList",
                          builder: (context) {
                            return Text("${playerController.localPlayList.isNotEmpty?playerController.currentPlayingLocalVideoIndex:0}/${playerController.localPlayList.length}");
                          }
                        ),

                        
                      ],
                    ),

                    Row(
                      children: [

                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 0),
                          onPressed: (){
                            print("current play mode: seq");
                          },
                          icon: const Icon(Icons.keyboard_tab,color: Colors.white,)
                        ),

                        GetBuilder(
                          id: "localListMode",
                          init: playerControlPanel,
                          builder: (context) {
                            return IconButton(
                              icon: Icon(
                                playerControlPanel.isLocalPlayListDeleteMode?Icons.close:Icons.remove,
                                color: Colors.black
                              ),
                              onPressed: (){
                                playerControlPanel.toggleLocalPlayListMode();
                              }
                            );
                          }
                        ),

                        

                      ],
                    ),
                    
                  ],
                ),
              
                Expanded(
                  child: DragTarget(
                    builder: (context, candidateData, rejectedData) {
                      return GetBuilder(
                        id: "localList",
                        init: playerControlPanel,
                        builder: (context) {
                          
                          return ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            onReorder:(oldIndex, newIndex) {
                              if(oldIndex < newIndex){
                                newIndex -= 1; //增长时 将值-1
                              }
                          
                              print("$oldIndex => $newIndex");
                          
                              final Map currentVideoInformation = playerController.localPlayList.removeAt(oldIndex);
                              playerController.localPlayList.insert(newIndex, currentVideoInformation);  
                          
                              //有播放时 跟着正在播放的Index走
                              if(playerController.currentPlayingInformation["title"] == playerController.localPlayList[newIndex]["title"]){
                                playerController.currentPlayingLocalVideoIndex = newIndex+1;
                                print("current Playing Index changed:$newIndex,next play will: ${playerController.localPlayList[max(newIndex+1,playerController.localPlayList.length-1)]["title"]}");
                              }
                          
                              //否则按照初始目录从头走
                              else if(playerController.currentPlayingLocalVideoIndex == 1){
                                print("next play will: ${playerController.localPlayList[1]}");
                              }
                          
                            },
                            
                            itemExtent: 60,
                            shrinkWrap:true,
                            itemCount: playerControlPanel.localPlayListExpanded.value?max(playerController.localPlayList.length,1):0,
                            itemBuilder: (_,index){
                          
                              if(playerController.localPlayList.isEmpty){
                                return const Center(
                                  key: ValueKey("initalItem"),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 12),
                                        child: Text("空空如也...",style: TextStyle(fontSize: 16)),
                                      ),
                                      
                                      Text("请透过添加按钮或者拖拽视频以载入本地播放列表")
                                    ],
                                  )
                                );
                              }
                            
                              Map<String,dynamic> currentVideoInformation = playerController.localPlayList[index];
                              //这里计划读取 playerController的内容 然后Obx监听它 以刷新
                              //不过现在先搭个框架吧
                                      
                              return ReorderableDragStartListener( //去除了默认的 drag handle 就需要这个东西用于监听dragStart
                                key: ValueKey(currentVideoInformation["title"]),
                                index: index,
                                child: ListTile(
                                  title: Text(
                                    currentVideoInformation["title"],
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2
                                  ),
                                                      
                                  trailing: playerController.currentPlayingInformation["title"] == currentVideoInformation["title"] ?
                                  const Icon(Icons.abc,color: Colors.white) :
                                  const SizedBox.shrink(),
                                  
                                  //原本是打算直接Obx的 结果Get包对List的数据修改方法不敏感 
                                  //必须得透过notifiedListner方式的GetBuilder才能响应List的更改
                                  //但是数据结构更复杂的Map.addAll 和 更低级的直接覆盖方式更新都能响应Obx 真是奇怪。。
                                  selected : playerController.localDeleteList.contains(currentVideoInformation["title"]),
                                  
                                  onTap: (){
                                    //待封装          
                                    if(!playerControlPanel.isLocalPlayListDeleteMode){
        
                                      Duration? recordDuration = playerController.loadLocalVideo(currentVideoInformation);

                                      playerController.currentPlayingLocalVideoIndex = index+1;
                                      playerControlPanel.currentPlayingVideoType.value = VideoType.localVideo.index;
                                      
                                      if(recordDuration!=null){
                                        playerControlPanel.toggleToasterMessage();
                                        playerController.player.seek(recordDuration);
                                      }
                                
                                    }
                                
                                    else{
                                
                                      if(playerController.localDeleteList.contains(currentVideoInformation["title"])){
                                        playerController.localDeleteList.remove(currentVideoInformation["title"]);
                                      }
                                                        
                                      else{
                                        playerController.localDeleteList.add(currentVideoInformation["title"]);
                                      }
                                
                                    }
                                          
                                    playerControlPanel.updateLocalList();
                                    playerControlPanel.updatePanelTitle();

                                                      
                                    
                                  },
                                                      
                                                      
                                  onLongPress: (){
                                    print("playList long Pressed");
                                    playerControlPanel.toggleLocalPlayListMode();
                                  },
                                                  
                                  hoverColor: const Color.fromARGB(175, 212, 228, 235),
                                  selectedColor: Colors.black,
                                  selectedTileColor: const Color.fromARGB(175, 212, 228, 235),
                                        
                                ),
                                );
                                        
                            }
                          );
                        }
                      );
                    },
                  
                    onWillAcceptWithDetails: (details) {
                      if(details.data is Map<String,String>){
                        return true;
                      }
                      return false;
                    },
                  
                    onAcceptWithDetails: (details) {
                      // onWillAcceptWithDetails -> onAcceptWithDetails
                      print("detail:${details.data}");
                      playerController.localPlayList.add(details.data);
                  
                    },
                  
                  ),
                ),
            
                //下载列表栏位
                Obx((){
                  return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [

                            IconButton(
                              onPressed: (){
                                print("toggle collapse of expaned");
                                playerControlPanel.localDownloadListExpanded.value = !playerControlPanel.localDownloadListExpanded.value;
                                playerControlPanel.updateDownloadList();
                              }, 
                                        
                              //默认   展开 Icons.arrow_forward_ios_rounded 
                              icon: Icon(
                                playerControlPanel.localDownloadListExpanded.value ?
                                Icons.keyboard_arrow_down_rounded :
                                Icons.keyboard_arrow_right_outlined ,
                                color: Colors.black,size: 20,
                              )
                            ),
                                        
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 12),child:Text("下载列表")),
                          ],
                        ),

                        GetBuilder(
                          id: "localListMode",
                          init: playerControlPanel,
                          builder: (context) {
                            return IconButton(
                              icon: Icon(
                                playerControlPanel.isDownloadTaskDeleteMode?Icons.close:Icons.remove,
                                color: Colors.black
                              ),
                              onPressed: (){
                                playerControlPanel.toggleDownloadTaskMode();
                              }
                            );
                          }
                        ),
                                      
                      ],
                    );
                  }),

                  GetBuilder(
                    id: "localDownloadList",
                    init: playerControlPanel,
                    builder: (context) {
                      return Expanded(
                      flex: playerControlPanel.localDownloadListExpanded.value?1:0,
                      child: ListView.builder(
                        itemExtent: 60,
                        shrinkWrap:true,
                        itemCount: playerControlPanel.localDownloadListExpanded.value?max(playerController.localDownloadTaskQueue.length,1):0,
                        itemBuilder: (_,index){
                      
                          if(playerController.localDownloadTaskQueue.isEmpty){
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text("空空如也...",style: TextStyle(fontSize: 16)),
                                  ),
                                  
                                  Text("请透过下载以添加任务队列")
                                ],
                              )
                            );
                          }
                      
                          return LayoutBuilder(
                            builder: (_,constraint) {
                              //可封装
                              MapEntry currentVideoInformation = playerController.localDownloadTaskQueue.entries.elementAt(index);
                      
                              List<String?> convertResult = convertTaskQueueInforamtion(currentVideoInformation);
                      
                              double? rate = currentVideoInformation.value["rate"];
                              
                              String? downloadedSize = convertResult[0];
                              String? size = convertResult[1];
                              String? sizeLabel = convertResult[2];
                              String? speed = convertResult[3];
                              String? speedLabel = convertResult[4];
                              
                              return Draggable(
                                feedback: const Icon(Icons.drafts),
                                data: 
                                  rate == -1.0 ? 
                                  <String,String>{
                                    "title": currentVideoInformation.key,
                                    "uri": "${StoragePath.downloadPath}${Platform.pathSeparator}${currentVideoInformation.key}.mp4",
                                    "audioUri": "${StoragePath.downloadPath}${Platform.pathSeparator}${currentVideoInformation.key}.mp3",
                                  } :
                                  null,
                                onDragStarted:() {
                                  print("dragStrart");
                                },
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Container(
                                        constraints: BoxConstraints.tightFor(width: constraint.maxWidth*2/3),
                                        child: Text(
                                          currentVideoInformation.key,
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1
                                        ),
                                      ),
                                    ],
                                  ),
                                                              
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      LinearProgressIndicator(value: rate == -1.0 ? 1.0 : rate),
                                      Text("$downloadedSize$sizeLabel/$size$sizeLabel ${speed ?? "-"}${speed!=null?speedLabel:""}", style: const TextStyle(fontSize: 12,color: Colors.black)), //speedUpdate,
                                      
                                    ],
                                  
                                  ),
                                                        
                                  //下载列表么 。。 如果是点击过去的话 不应参与正常的播放列表流程 就当是一个简单的open即可
                                  //而让其添加到播放列表的方式 我考虑了下 得使用Drag 只是这样的话本地播放列表就要额外添加两个识别了
                                  //一是来自内部的widget的Drag识别 二是来自文件夹内部的Drag识别。
                                  onTap: (){
                                                              
                                    print("clicked");

                                    //删除模式
                                    if(playerControlPanel.isDownloadTaskDeleteMode){
                                      if(playerController.localDeleteList.contains(currentVideoInformation.key)){
                                        playerController.localDeleteList.remove(currentVideoInformation.key);
                                      }
                                                        
                                      else{
                                        playerController.localDeleteList.add(currentVideoInformation.key);
                                      }

                                      playerControlPanel.updateDownloadList();
                                      print("${playerController.localDeleteList}");

                                    }

                                    else{
                                      //完成模式——添加
                                      if(rate == -1.0){
                                        playerController.localPlayList.add({
                                          "title": currentVideoInformation.key,
                                          "uri": "${StoragePath.downloadPath}${Platform.pathSeparator}${currentVideoInformation.key}.mp4",
                                          "audioUri": "${StoragePath.downloadPath}${Platform.pathSeparator}${currentVideoInformation.key}.mp3",
                                        });

                                        playerControlPanel.updateLocalList();

                                        return;
                                      }

                                      //下载模式——暂停/恢复 并应返回当前的size 以准备记录到Hive里

                                      //怎么鉴定它是 处于 下载无速度 和 暂停状态?
                                      //speed 为 0 为 无速度状态 为null 则视作暂停状态

                                      //活跃状态——暂停
                                      if(speed != null){
                                        currentVideoInformation.value["cancelToken"].cancel("user Manual");
                                      }

                                      //暂停状态——恢复
                                      else{

                                        //为 localDownloadTaskQueue 重新赋予 cancelToken 以及令其恢复下载状态

                                        videoDownload(
                                          currentVideoInformation.key,
                                          MyHive.videoDownloadDataBase.get(currentVideoInformation.key)!.videoUrl,
                                          MyHive.videoDownloadDataBase.get(currentVideoInformation.key)!.fileSize,

                                          MyHive.videoDownloadDataBase.get(currentVideoInformation.key)?.audioUrl,
                                          MyHive.videoDownloadDataBase.get(currentVideoInformation.key)?.rangeStart,
                                        );

                                        //记得合并!!
                                      }


                                      playerControlPanel.updateDownloadList();

                                    }

                                  },

                                  onLongPress: (){
                                    print("downloadList long Pressed");
                                    playerControlPanel.toggleDownloadTaskMode();
                                  },

                                  selected: playerController.localDeleteList.contains(currentVideoInformation.key),
                                                  
                                  hoverColor: const Color.fromARGB(175, 212, 228, 235),
                                  selectedColor: Colors.black,
                                  selectedTileColor: const Color.fromARGB(175, 212, 228, 235),

                                        
                                ),
                              );
                            }
                          );
                                  
                        },

                        
                      ),
                    );
                    }
                  ),

                //占位符
                Expanded(
                  flex: playerController.localPlayList.length > 3 ? 0 : 1,
                  child: const SizedBox.shrink(),
                ),

              ],
            ),
      
            Positioned(
              bottom: 15,
              right: 15,
              height: 60,
              width: 60,
              child: ElevatedButton(
                onPressed: () async {
                  //[待封装]

                  if(playerControlPanel.isLocalPlayListDeleteMode || playerControlPanel.isDownloadTaskDeleteMode){

                    bool? deleteAction = 
                      await showDialog<bool>(
                        context: context, 
                        builder: (_){
                          return Dialog(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                color: const Color.fromARGB(231, 85, 83, 83),
                              ),
                              height: 120,
                              width: 300,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Text("确定删除 ${playerController.localDeleteList.length} 个 项目?",style: const TextStyle(fontSize: 16)),
                                
                                  const Spacer(),
                                
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Wrap(
                                        spacing: 24,
                                        children: [
                                          ElevatedButton(
                                            onPressed: (){
                                              Navigator.of(context).pop(false);
                                            },
                                            child: const Text("no")
                                          ),
                                                                    
                                          ElevatedButton(
                                            onPressed: (){
                                              Navigator.of(context).pop(true);
                                            },
                                          child: const Text("yes")
                                          )
                                        ],
                                      ),
                                    ],
                                  )
                                
                                  
                                
                                  ],
                                ),
                              ),
      
                            ),
                          );    
                        });

                    print("deleteAction:$deleteAction");

                      if(deleteAction!=null&&deleteAction){
                        //Delete Mode
                        if(playerControlPanel.isLocalPlayListDeleteMode){

                          print(playerController.localPlayList);

                          if(playerController.localDeleteList.isNotEmpty){
                            for(String deleteName in playerController.localDeleteList){
                              print("deleteName:$deleteName");
                              
                              for(int localPlayIndex = 0;localPlayIndex<playerController.localPlayList.length;localPlayIndex++){
                                if(playerController.localPlayList[localPlayIndex]["title"] == deleteName){
                                  playerController.localPlayList.removeAt(localPlayIndex);
                                  break;
                                }
                              }
                            }
                          }

                          playerControlPanel.updateLocalList();

                        }

                        else if(playerControlPanel.isDownloadTaskDeleteMode){

                          if(playerController.localDeleteList.isNotEmpty){
                            for(String deleteName in playerController.localDeleteList){
                              print("deleteName:$deleteName");
                              playerController.localDownloadTaskQueue.remove(deleteName);
                            }
                          }

                          playerControlPanel.updateDownloadList();

                        }
                      }

                  }

                  //Append MODE
                  else{
                    
                    //Platfrom.xxx好像只会在运行时判定 而不是在编译时判定。。那咋办呢
                    if(Platform.isWindows){

                      final fileInformation = filePickDialog();

                      if(fileInformation.isNotEmpty){
                        for(var currentFile in fileInformation){
                          playerController.localPlayList.add({
                            "title":currentFile.path.split(Platform.pathSeparator).last,
                            "uri":currentFile.path
                          });
                        }
                      }

                      playerControlPanel.updateLocalList();

                    }

                    else if(Platform.isAndroid){

                      //filePicker 由于 安卓/IOS的限制 会变成 copyFile 要及时删除
                      //删除时机么 自己手动删除播放列表时进行clear() 应该算是个合理的时机
                      //如果这样操作的话 那么本地列表也得作为一个持久的保留数据才可以了
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.video,
                        allowMultiple: true
                      );

                      if(result!=null){

                        print(result);
                        List<File> files = result.paths.map((path) => File(path!)).toList();
                        
                          for(var currentFile in files){
                            playerController.localPlayList.add({
                              "title":currentFile.path.split(Platform.pathSeparator).last,
                              "uri":currentFile.path
                            });
                          }
                        }
                      }
                     
                      playerControlPanel.updateLocalList();

                    }

                  

                }, 

                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(Color.fromRGBO(196, 228, 255, 0.576))
                ),
                child: Transform(
                  transform: Matrix4.translationValues(-6,0,0),
                  child: GetBuilder(
                    id: "localListMode",
                    init: playerControlPanel,
                    builder: (context) {
                      print("localListModeUpdate");
                      return playerControlPanel.isDownloadTaskDeleteMode || playerControlPanel.isLocalPlayListDeleteMode? const Icon(Icons.delete) : const Icon(Icons.add);
                    }
                  ),
                )
                
              )
            )
          ]
          
        ),
      );

    }
}