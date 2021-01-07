import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../shared/sliding_segmented_control.dart';
import '../../shared/time_series_chart.dart';
import 'point_widget.dart';

class ChartWidget extends StatefulWidget {
  const ChartWidget({Key key}) : super(key: key);

  @override
  _ChartWidgetState createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  final selectedPointNotifier = ValueNotifier<Map<DateTime, double>>(null);
  HorizontalAxisDuration selectedDurationNotifier = HorizontalAxisDuration.week;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DurationSlidingSegmentedControl(
            selectedValue: selectedDurationNotifier,
            onSelectedValueChanged: (newSelectedPeriod) {
              setState(() => selectedDurationNotifier = newSelectedPeriod);
            }),
        const SizedBox(height: 50),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: TimeSeriesChart(
            horizontalAxisDuration: selectedDurationNotifier,
            data: getMockData(),
            onSelectDataPoint: (point) => selectedPointNotifier.value = point,
          ),
        ),
        const SizedBox(height: 50),
        ValueListenableBuilder(
            valueListenable: selectedPointNotifier,
            builder: (_, Map<DateTime, double> selectedPoint, __) =>
                PointWidget(selectedPoint)),
        const SizedBox(height: 50),
      ],
    );
  }
}
