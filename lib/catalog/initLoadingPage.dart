import 'package:flutter/material.dart';
import 'package:flutter_player/model/user_model.dart';
import 'package:get/get.dart';

class FutureWaitingPage extends StatelessWidget {
  const FutureWaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return FutureBuilder(
      future: Future(() async {
        UserModel.init();
        await Future.delayed(const Duration(seconds: 2));
      }).then((value){
        Future.delayed(const Duration(seconds: 1)).then((_) => Get.offNamed('video')); //由 二层Future 执行路由返回
      }),
     
      builder: (_,snapshot){

        switch(snapshot.connectionState){
          case ConnectionState.waiting: {
            print("waiting:${snapshot.data}");

            return const Scaffold(
              body: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    CircularProgressIndicator(),
                    Text("init Model...")
                  ],
                )
              ),
            );

          }

          case ConnectionState.done:{
            print("done:${snapshot.data}");

            return const Scaffold(
              body: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    Icon(Icons.done),
                    Text("done. forward Next Page")
                  ],
                )
              ),
            );
            
          }

          default: return const Text("initaling.."); 
            
        }
        
      }
    );
  
    

  }

}