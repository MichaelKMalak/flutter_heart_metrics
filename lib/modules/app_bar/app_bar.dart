import 'package:flutter/material.dart';

import 'image_with_top_shadow.dart';

class AppBarSliver extends StatelessWidget {
  final String text;
  final String imagePath;
  final bool centerTitle;

  const AppBarSliver({
    Key key,
    @required this.text,
    @required this.imagePath,
    this.centerTitle = false,
  })  : assert(text != null),
        assert(imagePath != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      expandedHeight: 200.0,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ImageWithTopShadowWidget(imagePath),
      ),
    );
  }
}