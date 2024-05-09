

import 'package:flutter/material.dart';



class HeaderDelegate extends SliverPersistentHeaderDelegate {
  HeaderDelegate({required this.onBuild});

  //final String data;
  //final Widget? onBuild;

  final Function(
    BuildContext context,
    double shrinkOffset, //用于输出向下滑动经过该group有多少pixel 直至超出group范围
    bool overlapsContent, //超出范围的状态量
  ) onBuild;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    
    //throw UnimplementedError();
    print("shrinkOffset:$shrinkOffset");

    return onBuild(context,shrinkOffset,overlapsContent);
    
  }

  @override
  double get maxExtent => 30;

  @override
  double get minExtent => 0;

  @override
  bool shouldRebuild(covariant HeaderDelegate oldDelegate) {

    return maxExtent != oldDelegate.maxExtent ||
      maxExtent != oldDelegate.maxExtent ||
      onBuild != oldDelegate.onBuild;
  
  }


  

 
  
}
