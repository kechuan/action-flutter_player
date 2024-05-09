
import 'package:get/get.dart';

class VideoPageMiddleWare extends GetMiddleware{
  @override
  GetPageBuilder? onPageBuildStart(GetPageBuilder? page)  {

    print("video Model loaded");

    return onPageBuildStart(page);
  }


}