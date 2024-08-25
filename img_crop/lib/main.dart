import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:yeter/cropp.dart'; // Import your custom crop widget
import 'package:custom_image_crop/custom_image_crop.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GifToFrames(),
    );
  }
}

class GifToFrames extends StatefulWidget {
  @override
  _GifToFramesState createState() => _GifToFramesState();
}

class _GifToFramesState extends State<GifToFrames> {
  late CustomImageCropController controller2;
  Uint8List? _gifBytes;
  List<Uint8List> _frames = [];
  int _frameDuration = 10; // Default frame duration in milliseconds
  List<Uint8List> _croppedFrames = [];

  @override
  void initState() {
    super.initState();
    controller2 = CustomImageCropController();
  }

  Future<void> _pickImageAndConvertToGif(Uint8List imageBytes) async {
    // Convert image to GIF (replace this with your conversion logic)
    await Future.delayed(Duration(seconds: 2)); // Simulate conversion
    final Uint8List gifBytes = imageBytes;
    setState(() {
      _gifBytes = gifBytes;
      _frames = [gifBytes];
    });
  }

  Future<void> _pickGifAndConvertToFrames() async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final img.Image? gifImage = img.decodeGif(bytes);
      if (gifImage != null) {
        setState(() {
          _gifBytes = bytes;
          _frames = gifImage.frames
              .map((frame) => Uint8List.fromList(img.encodeJpg(frame)!))
              .toList();
        });
      } else {
        await _pickImageAndConvertToGif(bytes);
      }
    }
  }

  Future<Uint8List> _generateGif(List<Uint8List> frames) async {
    if (frames.isNotEmpty) {
      final img.GifEncoder encoder = img.GifEncoder();
      for (var frame in frames) {
        if (frame.isNotEmpty) {
          encoder.addFrame(img.decodeImage(frame)!, duration: _frameDuration);
        }
      }
      return encoder.finish()!;
    }
    return Uint8List(0);
  }

  void _onCrop(List<Uint8List> croppedImages) {
    setState(() {
      _croppedFrames = croppedImages;
      _generateAndShowGif(); // Automatically generate GIF after cropping
    });
  }

  Future<void> _generateAndShowGif() async {
    List<Uint8List> framesToGenerate =
        _croppedFrames.isNotEmpty ? _croppedFrames : _frames;
    final gifBytes = await _generateGif(framesToGenerate);
    setState(() {
      _gifBytes = gifBytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GIF to Frames'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickGifAndConvertToFrames,
              child: Text('Pick GIF or Image and Convert to Frames'),
            ),
            _frames.isNotEmpty
                ? ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) =>
                            CustomCropExampleWidget(
                          image2: _frames,
                          controller: controller2,
                          onCrop: _onCrop,
                        ),
                      ));
                    },
                    child: Text('Crop Frames'),
                  )
                : SizedBox(), // Disable the button if frames are not loaded
            SizedBox(height: 20), // Add some spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Frame Delay:'),
                SizedBox(width: 8),
                Slider(
                  value: _frameDuration.toDouble(),
                  min: 5,
                  max: 50,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      _frameDuration = value.toInt();
                    });
                  },
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _generateAndShowGif,
              child: Text('Generate GIF'),
            ),
            if (_gifBytes != null)
              Image.memory(_gifBytes!, gaplessPlayback: true),
          ],
        ),
      ),
    );
  }
}
