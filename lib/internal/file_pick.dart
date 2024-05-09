import 'dart:io';

import 'package:filepicker_windows/filepicker_windows.dart';

List<File> filePickDialog([Map<String,String>? filterSpecification,String? title]){
   final pickedFiles = OpenFilePicker()
      ..filterSpecification = filterSpecification ?? {
        'Video Files': '*.mkv;*.mp4;*.flv;*.webv;*.m2ts;*.rmvb',
        'All Files': '*.*'
      }
      ..title = title ?? 'select Video(s)';
      
  final filesInformation = pickedFiles.getFiles();
      
  return filesInformation;

}