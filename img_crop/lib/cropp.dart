import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:custom_image_crop/custom_image_crop.dart';

List<Uint8List> imageFrames = [];

class CustomCropExampleWidget extends StatefulWidget {
  final List<Uint8List> image2;
  final CustomImageCropController controller;
  final CropCallback onCrop;

  const CustomCropExampleWidget({
    required this.image2,
    required this.controller,
    required this.onCrop,
    Key? key,
  }) : super(key: key);

  @override
  _CustomCropExampleWidgetState createState() =>
      _CustomCropExampleWidgetState();
}

class _CustomCropExampleWidgetState extends State<CustomCropExampleWidget> {
  late CustomImageCropController controller;
  CustomCropShape _currentShape = CustomCropShape.Circle;
  CustomImageFit _imageFit = CustomImageFit.fillCropSpace;
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  double _width = 16;
  double _height = 9;
  double _radius = 4;

  late MemoryImage _imagePath = MemoryImage(widget.image2[0]);

  @override
  void initState() {
    super.initState();
    controller = CustomImageCropController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _changeCropShape(CustomCropShape newShape) {
    setState(() {
      _currentShape = newShape;
    });
  }

  void _changeImageFit(CustomImageFit imageFit) {
    setState(() {
      _imageFit = imageFit;
    });
  }

  void _updateRatio() {
    setState(() {
      if (_widthController.text.isNotEmpty) {
        _width = double.tryParse(_widthController.text) ?? 16;
      }
      if (_heightController.text.isNotEmpty) {
        _height = double.tryParse(_heightController.text) ?? 9;
      }
      if (_radiusController.text.isNotEmpty) {
        _radius = double.tryParse(_radiusController.text) ?? 4;
      }
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Image'),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomImageCrop(
              cropController: controller,
              image: _imagePath,
              shape: _currentShape,
              ratio: _currentShape == CustomCropShape.Ratio
                  ? Ratio(width: _width, height: _height)
                  : null,
              canRotate: true,
              canMove: true,
              canScale: true,
              borderRadius:
                  _currentShape == CustomCropShape.Ratio ? _radius : 0,
              imageFit: _imageFit,
              pathPaint: Paint()
                ..color = Colors.red
                ..strokeWidth = 4.0
                ..style = PaintingStyle.stroke
                ..strokeJoin = StrokeJoin.round,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.reset,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () =>
                    controller.addTransition(CropImageData(scale: 1.33)),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () =>
                    controller.addTransition(CropImageData(scale: 0.75)),
              ),
              IconButton(
                icon: const Icon(Icons.rotate_left),
                onPressed: () =>
                    controller.addTransition(CropImageData(angle: -pi / 4)),
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right),
                onPressed: () =>
                    controller.addTransition(CropImageData(angle: pi / 4)),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.crop_original),
                onSelected: _changeCropShape,
                itemBuilder: (BuildContext context) {
                  return CustomCropShape.values.map(
                    (shape) {
                      return PopupMenuItem(
                        value: shape,
                        child: getShapeIcon(shape),
                      );
                    },
                  ).toList();
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.crop,
                  color: Colors.green,
                ),
                onPressed: () async {
                  // Crop işlemi başladığında indicatorı göster
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Cropping...'),
                          ],
                        ),
                      );
                    },
                  );

                  imageFrames.clear();
                  for (var a = 0; a < widget.image2.length; a++) {
                    setState(() {
                      _imagePath = MemoryImage(widget.image2[a]);
                    });
                    final image1 = await controller.onCropImage();
                    imageFrames.add(image1!.bytes);

                    final image2 = await controller.onCropImage();
                    setState(() {
                      _imagePath = MemoryImage(widget.image2[0]);
                    });
                  }

                  // Crop işlemi tamamlandığında indicatorı kaldır
                  Navigator.pop(context);

                  // Ana ekrana geri dön
                  widget.onCrop(imageFrames);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          if (_currentShape == CustomCropShape.Ratio) ...[
            SizedBox(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Width'),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Height'),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: TextField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Radius'),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  ElevatedButton(
                    onPressed: _updateRatio,
                    child: const Text('Update Ratio'),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom),
          ElevatedButton(
            onPressed: () {},
            child: Text('Swap Images'),
          ),
        ],
      ),
    );
  }

  Widget getShapeIcon(CustomCropShape shape) {
    switch (shape) {
      case CustomCropShape.Circle:
        return const Icon(Icons.circle_outlined);
      case CustomCropShape.Square:
        return const Icon(Icons.square_outlined);
      case CustomCropShape.Ratio:
        return const Icon(Icons.crop_16_9_outlined);
    }
  }
}

typedef CropCallback = void Function(List<Uint8List>);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom crop example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: CustomCropExampleWidget(
          image2: [], // Provide your image list here
          controller: CustomImageCropController(),
          onCrop: (List<Uint8List> imageFrames) {
            // Handle cropped images here
            // For example, you can store them, display them, or perform any other action
          },
        ),
      ),
    );
  }
}
