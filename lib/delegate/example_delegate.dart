import 'package:flutter/widgets.dart';

//class ItemData {
//  final String groupName;
//  final List<String> users;

//  ItemData({required this.groupName, this.users = const []});

//  static List<ItemData> get testData => [
//        ItemData(groupName: '幻将术士', users: ['梦小梦', '梦千']),
//        ItemData(
//            groupName: '幻将剑客', users: ['捷特', '龙少', '莫向阳', '何解连', '浪封', '梦飞烟']),
//        ItemData(groupName: '幻将弓者', users: ['巫缨', '巫妻孋', '摄王', '裔王', '梦童']),
//        ItemData(
//            groupName: '其他', users: List.generate(20, (index) => '小兵$index')),
//      ];
//}

class ExampleDelegate extends SliverPersistentHeaderDelegate {
  const ExampleDelegate(this.title);

  final String title;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
        alignment: Alignment.centerLeft,
        color: const Color(0xffF6F6F6),
        padding: const EdgeInsets.only(left: 20),
        height: 40,
        child: Text(title));
  }

  @override
  double get maxExtent => minExtent;

  @override
  double get minExtent => 40;

  @override
  bool shouldRebuild(covariant ExampleDelegate oldDelegate) => title!=oldDelegate.title;
}
