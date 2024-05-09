import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FutureWaitingPage extends StatelessWidget {
  const FutureWaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return FutureBuilder(
      future: 
      Future.delayed(const Duration(seconds: 3)).then(
        (_){
          print("hot reload: ${Get.currentRoute}");
          Future.delayed(const Duration(seconds: 1)).then((_) => Get.offNamed('video')); //由 二层Future 执行路由返回
        } 
      ), //一层Future执行完会回应done状态
      
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
                    Text("waiting the response...")
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
