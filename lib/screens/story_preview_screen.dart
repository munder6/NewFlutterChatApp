import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../controller/story_controller.dart';

class StoryEditorScreen extends StatefulWidget {
  final File imageFile;

  StoryEditorScreen({required this.imageFile});

  @override
  _StoryEditorScreenState createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> with WidgetsBindingObserver {
  final StoryController storyController = Get.find();
  final box = GetStorage();
  final GlobalKey _canvasKey = GlobalKey();

  List<_EditableTextData> texts = [];
  int? selectedTextIndex;
  bool keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newKeyboardVisible = bottomInset > 0.0;
    if (keyboardVisible != newKeyboardVisible) {
      setState(() {
        keyboardVisible = newKeyboardVisible;
        if (!keyboardVisible) selectedTextIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = box.read('user_id');

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (!keyboardVisible && selectedTextIndex == null) {
            setState(() {
              texts.add(_EditableTextData(text: '', position: Offset(100, 300)));
              selectedTextIndex = texts.length - 1;
            });
          }
        },
        child: Stack(
          children: [
            RepaintBoundary(
              key: _canvasKey,
              child: Stack(
                children: [
                  Image.file(
                    widget.imageFile,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  ...texts.asMap().entries.map((entry) {
                    int index = entry.key;
                    _EditableTextData item = entry.value;

                    return Positioned(
                      left: item.position.dx,
                      top: item.position.dy,
                      child: GestureDetector(
                        onTap: () => setState(() => selectedTextIndex = index),
                        onPanUpdate: (details) {
                          setState(() {
                            texts[index] = texts[index].copyWith(
                              position: item.position + details.delta,
                            );
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.bgColor,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 40),
                            child: IntrinsicWidth(
                              child: TextField(
                                autofocus: index == selectedTextIndex,
                                onChanged: (val) => setState(() {
                                  texts[index] = texts[index].copyWith(text: val);
                                }),
                                onTap: () => setState(() => selectedTextIndex = index),
                                style: TextStyle(
                                  color: item.textColor,
                                  fontSize: item.fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: "اكتب هنا...",
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            if (selectedTextIndex != null)
              Positioned(
                bottom: 100,
                left: 10,
                right: 10,
                child: Column(
                  children: [
                    Slider(
                      value: texts[selectedTextIndex!].fontSize,
                      min: 12,
                      max: 72,
                      activeColor: Colors.white,
                      onChanged: (val) => setState(() {
                        texts[selectedTextIndex!] =
                            texts[selectedTextIndex!].copyWith(fontSize: val);
                      }),
                    ),

                    // 🔹 اختيار لون النص
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.color_lens, color: Colors.white),
                        SizedBox(width: 8),
                        ..._colors.map((c) => GestureDetector(
                          onTap: () => setState(() {
                            texts[selectedTextIndex!] =
                                texts[selectedTextIndex!].copyWith(textColor: c);
                          }),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c,
                              border: Border.all(color: Colors.white),
                            ),
                          ),
                        )),
                      ],
                    ),

                    SizedBox(height: 10),

                    // 🔹 اختيار لون الخلفية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.format_color_fill, color: Colors.white),
                        SizedBox(width: 8),

                        // مربع بدون خلفية
                        GestureDetector(
                          onTap: () => setState(() {
                            texts[selectedTextIndex!] =
                                texts[selectedTextIndex!].copyWith(bgColor: Colors.transparent);
                          }),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              color: Colors.white,
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                            child: Center(
                              child: Icon(Icons.close, size: 16, color: Colors.red),
                            ),
                          ),
                        ),

                        ..._colors.map((c) => GestureDetector(
                          onTap: () => setState(() {
                            texts[selectedTextIndex!] =
                                texts[selectedTextIndex!].copyWith(bgColor: c);
                          }),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              color: c,
                              border: Border.all(color: Colors.white),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),

            // 🔹 زر النشر
            Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.send_rounded, color: Colors.white, size: 28),
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      await Future.delayed(Duration(milliseconds: 300));

                      final file = await _renderToImage();
                      await storyController.uploadStory(
                        userId: userId,
                        file: XFile(file.path),
                        isVideo: false,
                      );
                      Get.back();
                    },
                  ),
                ],
              ),
            ),
            Obx(() {
              if (storyController.isUploading.value) {
                return Positioned.fill(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: CupertinoActivityIndicator(radius: 16),
                          ),
                          SizedBox(height: 20,),
                          Text("Uploading Your Story ...", style: TextStyle(fontSize: 12),)
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return SizedBox.shrink();
              }
            }),
          ],

        ),
      ),
    );
  }

  Future<File> _renderToImage() async {
    RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 2.5);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final newPath = '${dir.path}/story_${DateTime.now().millisecondsSinceEpoch}.png';
    final newImage = File(newPath)..writeAsBytesSync(pngBytes);
    return newImage;
  }

  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.teal,
  ];
}

class _EditableTextData {
  final String text;
  final Offset position;
  final double fontSize;
  final Color textColor;
  final Color bgColor;

  _EditableTextData({
    required this.text,
    required this.position,
    this.fontSize = 36,
    this.textColor = Colors.white,
    this.bgColor = Colors.black,
  });

  _EditableTextData copyWith({
    String? text,
    Offset? position,
    double? fontSize,
    Color? textColor,
    Color? bgColor,
  }) {
    return _EditableTextData(
      text: text ?? this.text,
      position: position ?? this.position,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      bgColor: bgColor ?? this.bgColor,
    );
  }
}
