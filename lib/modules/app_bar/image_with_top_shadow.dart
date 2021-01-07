import 'package:flutter/material.dart';

class ImageWithTopShadowWidget extends StatelessWidget {
  final String imagePath;

  const ImageWithTopShadowWidget(this.imagePath, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imagePath,
          fit: BoxFit.fitHeight,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Colors.black87, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}
