List<String?> convertTaskQueueInforamtion(MapEntry currentVideoInformation){

    List<String?> result = List<String?>.filled(5, null);

    double? rate = currentVideoInformation.value["rate"];
    double? speed = currentVideoInformation.value["speed"];
    double? size = currentVideoInformation.value["size"];

    String? downloadedSize;
    String sizeLabel = "MB";
    String speedLabel = "B/s";

    if(size!=null && rate!=null){
      if(rate == -1) rate = 1;
      downloadedSize = (size * rate).toStringAsFixed(2);

      if(size > 1024){
        sizeLabel == "GB";
      }

      else if(size < 1/1024 && size > 1/1024/1024){
        sizeLabel = "KB";
      }

    }

    if(speed!=null){
      if(speed < 1 && speed > 1/1024){
        speedLabel = "KB/s";
        speed*=1024;
      }

      else if(speed > 1 && speed < 1024){
        speedLabel = "MB/s";
      }

      else{
        speedLabel = "B/s";
        speed = speed*1024*1024;
      }

    }

    result[0] = downloadedSize;
    result[1] = size?.toStringAsFixed(2);
    result[2] = sizeLabel;
    result[3] = speed?.toStringAsFixed(2);
    result[4] = speedLabel;

    return result;


}