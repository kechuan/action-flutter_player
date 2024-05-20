import 'package:flutter/material.dart';


class ShowTextFieldOverlay extends StatelessWidget {

  late OverlayEntry _overlayEntry;
  final TextEditingController cookieEditingController;
  
  final TextEditingController overlayController = TextEditingController();

  ShowTextFieldOverlay({super.key,required this.cookieEditingController});

  void showOverlay(BuildContext context) {
    
    OverlayState overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TextField(
                  controller: overlayController,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: '临时输入框'),
                ),

                const SizedBox(height: 8.0),

                ElevatedButton(
                  onPressed: () {
                     cookieEditingController.text = overlayController.text;
                    _overlayEntry.remove();
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlayState.insert(_overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: cookieEditingController,
              readOnly: true,
              onTap: () => showOverlay(context),
              decoration: const InputDecoration(hintText: '点击输入'),
            ),
          ],
        ),
      ),
    );
  }
}
