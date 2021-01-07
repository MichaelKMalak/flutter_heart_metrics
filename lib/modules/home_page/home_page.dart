import 'package:flutter/material.dart';

import '../app_bar/app_bar.dart';
import 'chart_widget.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CustomScrollView(
        slivers: [
          AppBarSliver(
            text: 'Heart Metrics',
            imagePath:
                'https://d35fo82fjcw0y8.cloudfront.net/2018/10/02135705/Google-HEART-Framework-e1551339702737.png',
            centerTitle: true,
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            sliver: SliverToBoxAdapter(
              child: ChartWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
