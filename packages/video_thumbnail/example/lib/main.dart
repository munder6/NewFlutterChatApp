import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DemoHome(),
    );
  }
}

class ThumbnailRequest {
  final String video;
  final String? thumbnailPath;
  final ImageFormat imageFormat;
  final int maxHeight;
  final int maxWidth;
  final int timeMs;
  final int quality;

  const ThumbnailRequest({
    required this.video,
    this.thumbnailPath,
    this.imageFormat = ImageFormat.JPEG,
    this.maxHeight = 0,
    this.maxWidth = 0,
    this.timeMs = 0,
    this.quality = 75,
  });
}

class ThumbnailResult {
  final Image image;
  final int dataSize;
  final int height;
  final int width;

  const ThumbnailResult({
    required this.image,
    required this.dataSize,
    required this.height,
    required this.width,
  });
}

Future<ThumbnailResult> genThumbnail(ThumbnailRequest r) async {
  Uint8List? bytes;
  final completer = Completer<ThumbnailResult>();

  if (r.thumbnailPath != null) {
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: r.video,
      headers: {
        "USERHEADER1": "user defined header1",
        "USERHEADER2": "user defined header2",
      },
      thumbnailPath: r.thumbnailPath,
      imageFormat: r.imageFormat,
      maxHeight: r.maxHeight,
      maxWidth: r.maxWidth,
      timeMs: r.timeMs,
      quality: r.quality,
    );

    if (thumbnailPath == null) throw Exception("Thumbnail generation failed");

    final file = File(thumbnailPath);
    bytes = await file.readAsBytes();
  } else {
    bytes = await VideoThumbnail.thumbnailData(
      video: r.video,
      headers: {
        "USERHEADER1": "user defined header1",
        "USERHEADER2": "user defined header2",
      },
      imageFormat: r.imageFormat,
      maxHeight: r.maxHeight,
      maxWidth: r.maxWidth,
      timeMs: r.timeMs,
      quality: r.quality,
    );
  }

  final imageDataSize = bytes!.length;
  final image = Image.memory(bytes);

  image.image.resolve(ImageConfiguration()).addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(ThumbnailResult(
        image: image,
        dataSize: imageDataSize,
        height: info.image.height,
        width: info.image.width,
      ));
    }),
  );

  return completer.future;
}

class GenThumbnailImage extends StatefulWidget {
  final ThumbnailRequest thumbnailRequest;

  const GenThumbnailImage({Key? key, required this.thumbnailRequest}) : super(key: key);

  @override
  State<GenThumbnailImage> createState() => _GenThumbnailImageState();
}

class _GenThumbnailImageState extends State<GenThumbnailImage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThumbnailResult>(
      future: genThumbnail(widget.thumbnailRequest),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final result = snapshot.data!;
          return Column(
            children: [
              Text("Size: ${result.dataSize}, Width: ${result.width}, Height: ${result.height}"),
              Divider(),
              result.image,
            ],
          );
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else {
          return Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text("Generating thumbnail..."),
            ],
          );
        }
      },
    );
  }
}

class DemoHome extends StatefulWidget {
  @override
  _DemoHomeState createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  final _videoController = TextEditingController(
    text: "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
  );
  final _focusNode = FocusNode();

  ImageFormat _format = ImageFormat.JPEG;
  int _quality = 75;
  int _height = 0;
  int _width = 0;
  int _timeMs = 0;

  GenThumbnailImage? _previewWidget;
  late String _tempDir;

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((d) => _tempDir = d.path);
  }

  Widget _buildSlider(String label, int value, void Function(int) onChanged, int max) {
    return Column(
      children: [
        Slider(
          value: value.toDouble(),
          onChanged: (v) => setState(() => onChanged(v.toInt())),
          max: max.toDouble(),
          divisions: max,
          label: "$value",
        ),
        Text("$label: $value"),
      ],
    );
  }

  void _generateThumbnail({required bool asFile}) {
    final request = ThumbnailRequest(
      video: _videoController.text,
      thumbnailPath: asFile ? _tempDir : null,
      imageFormat: _format,
      maxHeight: _height,
      maxWidth: _width,
      timeMs: _timeMs,
      quality: _quality,
    );
    setState(() {
      _previewWidget = GenThumbnailImage(thumbnailRequest: request);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Thumbnail Example"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: _videoController,
              focusNode: _focusNode,
              decoration: InputDecoration(labelText: "Video URL", border: OutlineInputBorder()),
            ),
            _buildSlider("Max Height", _height, (v) => _height = v, 256),
            _buildSlider("Max Width", _width, (v) => _width = v, 256),
            _buildSlider("Time (ms)", _timeMs, (v) => _timeMs = v, 10000),
            _buildSlider("Quality", _quality, (v) => _quality = v, 100),
            Row(
              children: [
                Radio<ImageFormat>(
                  value: ImageFormat.JPEG,
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v!),
                ),
                Text("JPEG"),
                Radio<ImageFormat>(
                  value: ImageFormat.PNG,
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v!),
                ),
                Text("PNG"),
                Radio<ImageFormat>(
                  value: ImageFormat.WEBP,
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v!),
                ),
                Text("WEBP"),
              ],
            ),
            SizedBox(height: 10),
            if (_previewWidget != null) Expanded(child: _previewWidget!),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _generateThumbnail(asFile: false),
            child: Text("Data", style: TextStyle(fontSize: 10)),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () => _generateThumbnail(asFile: true),
            child: Text("File", style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
