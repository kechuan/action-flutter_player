

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_player/internal/log.dart';
import 'package:flutter_player/internal/show_textfield_overlay.dart';
import 'package:flutter_player/model/player_ui_model.dart';
import 'package:flutter_player/model/user_model.dart';

import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';

class SettingPanel extends StatelessWidget {
  const SettingPanel({super.key});

  void settingPanelInit(){
    UserModel.editingCookieFlag = false.obs;
    UserModel.editingCookieFlagAnimated = false.obs;
  }

  @override
  Widget build(BuildContext context) {

    final cookieEditingController = TextEditingController();
    final FocusScopeNode cookiesFocusNode = FocusScopeNode();
    final playerControlPanel = Get.find<PlayerUIModel>();

    settingPanelInit();

    return FutureBuilder(
      future: Future.wait(
        [
          UserHive.getUserConfig("cookie").then((value){
            //Log.logprint("cookie:$value");
            UserModel.configList["cookie"] = value;
            cookieEditingController.text = value??'null';
          }),

          UserHive.getUserConfig("qualifiySetting").then((value){
            //Log.logprint("qualifiySetting:$value");
            UserModel.configList["qualifiySetting"] = value;
          }),

          UserHive.getUserConfig("encodeSetting").then((value){
            //Log.logprint("encodeSetting:$value");
            UserModel.configList["encodeSetting"] = value;
          }),

        ]
      ),
      
      //这里的Future是指所有配置都拉取完毕的Future 真正意义上的Future.wait那种 需要结合Hive使用
      builder: (_,snapshot){
    
        //Widget currentState = const SizedBox.shrink();
    
        switch(snapshot.connectionState){
          
          case ConnectionState.waiting: {
            return const Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  CircularProgressIndicator(color: Colors.black),
                  Text("waiting the response...")
                ],
              )
            );
          }
    
          case ConnectionState.done:{
            
          /* PopScope Fail Case */
            //Get.back();
            //Navigator.of(context).pop();
            //Get.back(closeOverlays: true);
            //Navigator.pop(Get.overlayContext!, true);

            return WillPopScope(
              
              onWillPop:() async {

                if(MediaQuery.viewInsetsOf(context).bottom>0 || playerControlPanel.currentOverlayEntry == null){
                  return true;
                }

                if(playerControlPanel.currentOverlayEntry!=null){
                  Log.logprint("did Pop remove");
                  playerControlPanel.currentOverlayEntry!.remove();
                  playerControlPanel.currentOverlayEntry = null;
                }

                return false;

              },
              child: 
              
              Column(
              
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              
                  const Padding(
                    padding:  EdgeInsets.all(12.0),
                    child: Text('Prefer Setting',textScaler: TextScaler.linear(1.4),style: TextStyle(color: Color.fromARGB(158, 43, 3, 186)),),
                  ),
              
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (_,index){
                        if(index==0||index == UserModel.configList.length-1){
                          return const Divider(thickness: 1,color: Color.fromARGB(255, 39, 37, 37),);
                        }
              
                        return const SizedBox.shrink();
                        
                      },
                      itemCount: UserModel.configList.length+1, //Debug Button
                      itemBuilder: (_,index){
              
                        Map<String,dynamic> configList = UserModel.configList;
              
                        return ListTile(
                          title: 
                            index == UserModel.configList.length ?
                            //Debug
                            const Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              direction : Axis.horizontal,
                              children: [
                                
                                /* Debug */
                                //ElevatedButton(
                                //  onPressed: (){
                            
                                //    UserHive.getUserConfig('qualifiySetting').then((value){
                                //      Log.logprint("qualifiySetting:$value");
                                //    });
                            
                                //    UserHive.getUserConfig('encodeSetting').then((value){
                                //      Log.logprint("encodeSetting:$value");
                                //    });
                            
                                //    UserHive.getUserConfig('playMode').then((value){
                                //      Log.logprint("playMode:$value");
                                //    });
                                //  }, 
                                //  child: const Text("User Get")
                                //),
                                            
                                //ElevatedButton(
                                //  onPressed: (){
              
                                //    Duration? test = (MyHive.videoRecordDataBase.get("anime1") as VideoDurationRecord?)?.videoPosition;
              
                                //    Log.logprint("$test");
                                //  }, 
                                //  child: const Text("video Duration Get")
                                //),
              
                                //ElevatedButton(
                                //  onPressed: (){
                                //    VideoDurationRecord anime1 = VideoDurationRecord();
              
                                //    anime1.videoPosition = const Duration(seconds: 15);                                  
                                //    MyHive.videoRecordDataBase.put("anime1", anime1);
                                //  }, 
                                //  child: const Text("video Duration write")
                                //),
              
                                //ElevatedButton(
                                //  onPressed: (){
                                //    MyHive.videoRecordDataBase.clear();
                                //  }, 
                                //  child: const Text("Video Duration Clear")
                                //),
              
                                //ElevatedButton(
                                //  onPressed: (){
                                //    MyHive.videoDownloadDataBase.clear();
                                //  }, 
                                //  child: const Text("Video Download Clear")
                                //),
              
                                //ElevatedButton(
                                //  onPressed: (){
                                //    playerControlPanel.toggleToasterMessage();
                            
                                //  }, 
                                //  child: const Text("Toast")
                                //),
              
              
                              ],
                            ) :
                  
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${configList.keys.elementAt(index)}:"),
                                    Builder(
                                      builder: (_){
              
                                        switch(configList.keys.elementAt(index)){
                                          case 'cookie':{
                                  
                                            return Obx((){
                                              return 
                                              
                                              Row(
                                                children: [
                                                  
                                                  Obx((){
                                                    //诱骗Obx 以节省obs资源
                                                    //bool obxUpdate = UserModel.editingCookieFlag.value;
                                                     return Row(
                                                       children: [
              
                                                          !UserModel.isModifiedCookie ?
                                                          const SizedBox.shrink() :
                                                            UserModel.verifingCookie.value ?
                                                            const Text("等待中...") : //这里应该是Pending 与 result
                                                             Text(UserModel.cookiesState,style: const TextStyle(color: Color.fromARGB(255, 30, 0, 255)),),
                                                          
                                                          Visibility(
                                                            //visible: !UserModel.isLogined ? UserModel.verifingCookie.value : UserModel.isLogined,
                                                            visible: UserModel.verifingCookie.value,
                                                            maintainState: UserModel.verifingCookie.value,
                                                            child:  Padding(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                                              child: UserModel.isLogined ?
                                                              const Icon(Icons.done) :
                                                              const CircularProgressIndicator(
                                                                color: Colors.grey,
                                                                strokeWidth:2
                                                              ),
                                                            )
                                                          ),
                                                       ],
                                                     );
                                                  }),
                                              
                                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 12)),
                                              
                                                  Row(
                                                    children: [
              
                                                      //close
                                                      Obx((){
                                                        return Visibility(
                                                          visible: UserModel.editingCookieFlag.value,
                                                          maintainState: UserModel.editingCookieFlag.value,
                                                          child: IconButton(
                                                            onPressed: (){
              
                                                              UserModel.editingCookieFlag.value = !UserModel.editingCookieFlag.value;
                                                              if(UserModel.editingCookieFlagAnimated.value == false) UserModel.editingCookieFlagAnimated.value = true;
                                                              
                                                            }, 
                                                            icon: const Icon(Icons.close) 
                                                            
                                                                                                      
                                                          ),
                                                        );
                                                      }),
              
                                                      IconButton(
                                                        onPressed: (){
                                                          //弹出 TextInput(简单) 或者 
                                                          //往下扩展空间
                                                          //不过那样的话。。是不是得用AnimatedList了呢。。
                                                                      
                                                          if(UserModel.editingCookieFlag.value){
              
                                                            if(cookieEditingController.value.text != UserModel.configList["cookie"]){
                                                              UserModel.isModifiedCookie = true;
                                                              UserModel.verfiyCookie(cookieEditingController.value.text);
                                                              // succ => write down Hive, fail => don't change.
                                                            }
              
                                                          }
                                                                                                  
                                                          UserModel.editingCookieFlag.value = !UserModel.editingCookieFlag.value;
                                                          if(UserModel.editingCookieFlagAnimated.value == false) UserModel.editingCookieFlagAnimated.value = true;
                                                                                                  
                                                                                                  
                                                        }, 
                                                        icon: UserModel.editingCookieFlag.value ?
                                                        const Icon(Icons.done) :
                                                        const Icon(Icons.edit_document) 
                                                        //状态切换 edit/submit
                                                                                                  
                                                      ),
                                                    
                                                    ],
                                                  )
                                                ],
                                              );
                                            });
              
                                          }
                                  
                                          case 'qualifiySetting':{
                                            if(configList['qualifiySetting'] != null){
                                              return Obx((){
                                                return SizedBox( //DropdownButton:isExpanded 来填充 这个sizedBox 给的宽度 相当于紧约束
                                                  width: 80,
                                                  child: DropdownButton<String>(
                                  
                                                    menuMaxHeight:160,
                                  
                                                    items: List.generate(
                                                      VideoQuality.values.length-1, (index) => DropdownMenuItem<String>(value: VideoQuality.values.elementAt(index+1).name,alignment :Alignment.center,child :Text(VideoQuality.values.elementAt(index+1).name))
                                                    ),
                                
                                                    onChanged: (value){
                                                      Log.logprint("select:$value");
                                                      UserModel.configList['qualifiySetting'] = value;
                                                    },
                                                
                                                    value: UserModel.configList['qualifiySetting'],
                                                    isExpanded :true,
                                                    alignment:Alignment.center, //用于调整value的位置
                                                
                                                    icon: const SizedBox.shrink(),
                                                      
                                                  ),
                                                );
                                              
                                              });
                                              
                                            }
                                  
                                            return const Text("null");
                                  
                                          }
              
                                          case 'encodeSetting':{
                                  
                                            if(configList['qualifiySetting'] != null){
                                              return Obx((){
                                                return SizedBox( //expanded填充
                                                  width: 80,
                                                  child: DropdownButton<String>(
                                                      
                                                      items: const [
                                                        DropdownMenuItem(value: 'AVC',alignment :Alignment.center,child :Text('AVC')),
                                                        DropdownMenuItem(value: 'HEVC',alignment :Alignment.center,child :Text('HEVC')),
                                                        DropdownMenuItem(value: 'AV1',alignment :Alignment.center,child :Text('AV1')),
                                                      ], 
                                                      onChanged: (value){
                                                        Log.logprint("select:$value");
                                                  
                                                        //应该这样 Model 优先变动 然后当你真正的 离开了settingPanel的时候 再去使用setConfig来保存
                                                  
                                                        UserModel.configList['encodeSetting'] = value;
                                                        UserHive.setUserConfig("encodeSetting", value);
                                                        
                                                      },
                                                  
                                                      value: UserModel.configList['encodeSetting'],
                                                      isExpanded :true,
                                                      alignment:Alignment.center, //用于调整value的位置
                                                  
                                                      icon: const SizedBox.shrink(),
                                                      
                                                    ),
                                                );
                                                
                                              });
                                              
                                            }
                                  
                                            return const Text("null");
                                  
                                          }
                                  
                                          case 'playMode':{
              
              
                                            if(configList['playMode']!=null){
              
                                              return Obx((){
                                                return Wrap(
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  spacing: 12,
                                                  children: [
              
                                                    const Text("Local:"),
              
              
                                                    SizedBox( //DropdownButton:isExpanded 来填充 这个sizedBox 给的宽度 相当于紧约束
                                                      width: 80,
                                                      child: DropdownButton<String>(
                                                                                    
                                                        menuMaxHeight:160,
                                                                                    
                                                        items: List.generate(
                                                          PlaylistMode.values.length, (index) => DropdownMenuItem<String>(value: PlaylistMode.values.elementAt(index).name,alignment :Alignment.center,child :Text(PlaylistMode.values.elementAt(index).name))
                                                        ),
                                                                                  
                                                        onChanged: (value){
                                                          Log.logprint("select:$value");
                                                          configList['playMode']['local'] = value;
                                                        },
                                                                                                        
                                                        value: configList['playMode']['local'],
                                                        isExpanded :true,
                                                        alignment:Alignment.center, //用于调整value的位置
                                                                                                        
                                                        icon: const SizedBox.shrink(),
                                                          
                                                      ),
                                                    ),
              
              
                                                    const Text("online:"),
              
                                                    SizedBox( //DropdownButton:isExpanded 来填充 这个sizedBox 给的宽度 相当于紧约束
                                                      width: 80,
                                                      child: DropdownButton<String>(
                                                                                    
                                                        menuMaxHeight:160,
                                                                                    
                                                        items: List.generate(
                                                          PlaylistMode.values.length, (index) => DropdownMenuItem<String>(value: PlaylistMode.values.elementAt(index).name,alignment :Alignment.center,child :Text(PlaylistMode.values.elementAt(index).name))
                                                        ),
                                                                                  
                                                        onChanged: (value){
                                                          Log.logprint("select:$value");
                                                          configList['playMode']['online'] = value;
                                                        },
                                                                                                        
                                                        value: configList['playMode']['online'],
                                                        isExpanded :true,
                                                        alignment:Alignment.center, //用于调整value的位置
                                                                                                        
                                                        icon: const SizedBox.shrink(),
                                                          
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              
                                              });
                                              
                                            }
                                          }
                                        }
                                  
                                        return const SizedBox.shrink();
                                  
                                      }
                                    )
                                    
                                  ],
                                ),
                  
                                Obx((){
                  
                                  if(UserModel.configList.keys.elementAt(index) == 'cookie'){
                                      return Visibility(
                                        
                                        maintainState: true, 
                                        maintainAnimation: true,
              
                                        visible: UserModel.editingCookieFlagAnimated.value,
                                        
                                        child: AnimatedOpacity(
                                          opacity: UserModel.editingCookieFlag.value? 1.0 : 0.0,
                                          duration: const Duration(milliseconds: 300),
                                          
                                          child: SizedBox(
                                            height: 100,
                                              child: TextField( 
                                                focusNode: cookiesFocusNode,
                                                controller: cookieEditingController,
                                                //expands true: 其width属性则已经变成松约束去准备填充 
                                                //但是height属性却依旧需要手动给 可能是Column的原因?
                                                minLines: null,
                                                maxLines: null,
                                              
                                                expands: true,
              
                                                onTap: () {
                                                  if(Platform.isAndroid){
                                                    TextFieldOverlay(
                                                      name: "cookies",
                                                      context: context,
                                                      outerTextEditingController: cookieEditingController,
                                                      outerFocusNode: cookiesFocusNode
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
              
                                            onEnd: () {
                
                                              if(UserModel.editingCookieFlag.value == false){
                                                if(cookieEditingController.value.text != UserModel.configList["cookie"]){
                                                  cookieEditingController.text = UserModel.configList["cookie"];
                                                }
                                                UserModel.editingCookieFlagAnimated.value = false;
                                              }
              
                                            },
              
                                        )
                                      );
                                  }
                  
                                  return const SizedBox.shrink();
                  
                                })  
                  
                              ],
                            ),
                  
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  
                        );
                  
                      }
                    )
                  ),
              
              
                ],
              ),
            );
            
          }
    
          default: return const Text("initaling.."); 
            
        }
        
    
      },
    );
  }
}