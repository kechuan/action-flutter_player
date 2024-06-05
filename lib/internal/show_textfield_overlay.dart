
import 'package:flutter/material.dart';
import 'package:flutter_player/internal/log.dart';
import 'package:flutter_player/internal/request_encode.dart';
import 'package:flutter_player/model/player_ui_model.dart';
import 'package:get/get.dart';

class TextFieldOverlay{

  TextFieldOverlay({
    required this.context,
    this.searchType,
    this.name,
    this.outerTextEditingController,
    this.outerFocusNode
  }){
    showTextFieldOverlay(context);
  }

  final BuildContext context;

  final bool? searchType;
  final String? name;
  final TextEditingController? outerTextEditingController;

  final FocusScopeNode? outerFocusNode;
  final FocusScopeNode overlayFocus = FocusScopeNode();

  final TextEditingController overlayController = TextEditingController();

  void showTextFieldOverlay(BuildContext context){

    final playerControlPanel = Get.find<PlayerUIModel>();

    Log.logprint("overlay build");


    OverlayState overlayState = Overlay.of(context);

      playerControlPanel.currentOverlayEntry = OverlayEntry(
        
        builder: (context){
          Log.logprint("Media systemGestureInsets:${MediaQuery.systemGestureInsetsOf(context).right}");

          if(outerTextEditingController !=null && outerFocusNode != null){

            outerFocusNode!.addListener(() {
              if(!outerFocusNode!.hasFocus){
                Log.logprint("outerFocusNode unfocus trigged");
                overlayFocus.requestFocus();
              }
            });

            outerFocusNode!.unfocus();
          }

          return Stack(
            children:
            [
              Positioned(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
                
                right:MediaQuery.systemGestureInsetsOf(context).right,
                height: 62,
                width: MediaQuery.sizeOf(context).width - MediaQuery.systemGestureInsetsOf(context).right,
                child: Material(
                  child: Row(
                  children: [
          
                    ConstrainedBox(
                      constraints: const BoxConstraints.tightFor(width: 60),
                      child: Center(child: Text("${name??"name"}:")),
                    ),
                    
                    Expanded(
                      child: TextField(
                        focusNode: overlayFocus,
                        controller: overlayController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Enter text',
                        ), 
                      ),
                    ),
                                                                            
                    TextButton(
                      onPressed: (){
                        playerControlPanel.currentOverlayEntry!.remove();
                        overlayFocus.unfocus();
          
                        if(outerFocusNode != null){
                          outerFocusNode!.unfocus();
                          
                        }
                        
                      }, 
                      child: const Text("取消")
                      
                    ),
                                                                            
                    TextButton(
                      onPressed: (){
          
                        if(outerTextEditingController!=null){
                          outerTextEditingController!.value = overlayController.value;
                        }
          
                        overlayFocus.unfocus();
                        playerControlPanel.currentOverlayEntry!.remove();
          
                        if(outerFocusNode != null){
                          
                          Log.logprint("outerFocusNode remove");
          
                          if(searchType!=null && searchType == true){
                            searchRequestResponse(overlayController.value.text);
                          }
                          
                          outerFocusNode!.unfocus();
          
                        }
                      }, 
                      child: const Text("确定")
                      
                    ),
          
                  ],
                ),
                ),
              ),
          
            ]
            
          );
        });

    overlayState.insert((playerControlPanel.currentOverlayEntry) as OverlayEntry);

  }


}
