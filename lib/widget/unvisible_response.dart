import 'package:flutter/material.dart';

class UnVisibleResponse extends StatelessWidget {
  const UnVisibleResponse({super.key,this.onTap,this.child});

  final void Function()? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap??(){;}, //Active onTap Action: it don't anything but block the hitTest to the downfloor
      hoverColor: Colors.transparent,     // 悬浮时圆点
      highlightColor: Colors.transparent, // 点击时的圆点
      splashColor: Colors.transparent,    // 扩散水圈

      child: child,
    );

  }
}