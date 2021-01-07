import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'time_series_chart.dart';

class DurationSlidingSegmentedControl extends StatelessWidget {
  final HorizontalAxisDuration selectedValue;
  final void Function(HorizontalAxisDuration) onSelectedValueChanged;

  const DurationSlidingSegmentedControl(
      {Key key,
      @required this.selectedValue,
      @required this.onSelectedValueChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: CupertinoSegmentedControl(
        children: getListOfTextWidgets(context),
        groupValue: selectedValue,
        onValueChanged: onSelectedValueChanged,
        selectedColor: Colors.indigo.shade100,
        pressedColor: Colors.indigo.shade400,
        borderColor: Colors.indigo,
      ),
    );
  }

  Map<HorizontalAxisDuration, Widget> getListOfTextWidgets(
      BuildContext context) {
    final result = <HorizontalAxisDuration, Widget>{
      HorizontalAxisDuration.year: const TabWidget('Year'),
      HorizontalAxisDuration.threeMonths: const TabWidget('3 Months'),
      HorizontalAxisDuration.month: const TabWidget('Month'),
      HorizontalAxisDuration.week: const TabWidget('Week'),
    };
    return result;
  }
}

class TabWidget extends StatelessWidget {
  final String text;

  const TabWidget(this.text, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.indigo,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}
