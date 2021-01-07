import 'dart:async';
import 'dart:math' as math;

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class TimeSeriesChart extends StatefulWidget {
  final List<Map<DateTime, double>> data;

  final int verticalAxisMultiples;
  final DataPointsReductionMode dataPointsReductionMode;
  final HorizontalAxisDuration horizontalAxisDuration;
  final bool shouldSortDataRecentFirst;
  final Function(Map<DateTime, double>) onSelectDataPoint;

  final List<Map<DateTime, double>> data2;

  ///in case data2 != null
  final Function(List<Map<DateTime, double>>) onSelectMultiDataPoint;
  final List<String> chartNames;

  final String verticalAxisDisplayedUnit;
  final Function(DateTime) onShouldLoadMoreData;
  final int numberOfSlidesBeforeLastDataPointToTriggerLoadMoreData;

  const TimeSeriesChart(
      {Key key,
        @required this.data,
        @required this.horizontalAxisDuration,
        this.data2,
        this.chartNames,
        this.verticalAxisDisplayedUnit,
        this.verticalAxisMultiples,
        this.onSelectDataPoint,
        this.shouldSortDataRecentFirst = false,
        this.dataPointsReductionMode = DataPointsReductionMode.average,
        this.onShouldLoadMoreData,
        this.onSelectMultiDataPoint,
        this.numberOfSlidesBeforeLastDataPointToTriggerLoadMoreData = 1})
      : super(key: key);

  @override
  _TimeSeriesChartState createState() => _TimeSeriesChartState();
}

class _TimeSeriesChartState extends State<TimeSeriesChart> {
  String get verticalAxisDisplayedUnit => widget.verticalAxisDisplayedUnit;
  HorizontalAxisDuration get viewPortDomainAxisDuration =>
      widget.horizontalAxisDuration;
  int get multiple => widget.verticalAxisMultiples;

  bool get hasChartNames =>
      widget.chartNames != null && widget.chartNames.length > 1;

  List<charts.Series<Map<DateTime, double>, DateTime>> seriesList;

  List<Map<DateTime, double>> get data => seriesList.first.data;
  List<Map<DateTime, double>> get data2 =>
      widget.data2 == null ? null : seriesList.last.data;

  DateTime get lastDataPointDateTime => data.last.keys.first;

  DateTime startHorizontalAxisDateTime;
  DateTime endHorizontalAxisDateTime;

  DateTime startHorizontalAxisOfNextSlideDateTime;

  int backSwipeNum = 0;
  bool _isSwipingEnabled = true;

  Timer _swipingTimer;

  @override
  void initState() {
    preProcessInputData();
    selectLastDataPointOnViewLoad();
    super.initState();
  }

  @override
  void didUpdateWidget(TimeSeriesChart oldWidget) {
    bool _shouldSelectLastPoint = false;

    if (oldWidget.horizontalAxisDuration != widget.horizontalAxisDuration) {
      preProcessInputData();
      backSwipeNum = 0;
      _shouldSelectLastPoint = true;
    } else if (oldWidget.data.length != widget.data.length) {
      preProcessInputData();
      _shouldSelectLastPoint = true;
    }

    if (_shouldSelectLastPoint) selectLastDataPointOnViewLoad();

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final _concatenatedDataList = data2 != null ? data + data2 : data;
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: charts.TimeSeriesChart(
        seriesList,
        animate: false,
        behaviors: buildBehaviors(),
        primaryMeasureAxis: data.isEmpty
            ? null
            : buildVerticalAxis(multiple, _concatenatedDataList),
        dateTimeFactory: const charts.LocalDateTimeFactory(),
        domainAxis:
        buildHorizontalAxis(backSwipeNum, viewPortDomainAxisDuration),
        selectionModels: _listenToSelectionChanges(),
      ),
    );
  }

  @override
  void dispose() {
    _swipingTimer?.cancel();
    super.dispose();
  }

  /// ------------- Handel user events ------------- ///
  List<charts.SelectionModelConfig<DateTime>> _listenToSelectionChanges() {
    return [
      charts.SelectionModelConfig(
        changedListener: (charts.SelectionModel<dynamic> model) {
          if (model.hasDatumSelection &&
              widget.onSelectMultiDataPoint != null) {
            final selectedPoints = model.selectedDatum
                .map((e) => e.datum as Map<DateTime, double>)
                .toList();
            widget.onSelectMultiDataPoint(selectedPoints);
          } else if (model.hasDatumSelection &&
              data2 == null &&
              widget.onSelectDataPoint != null) {
            final selectedPoint =
            model.selectedDatum.single.datum as Map<DateTime, double>;
            widget.onSelectDataPoint(selectedPoint);
          }
        },
      ),
    ];
  }

  void enableSwipingAfter({@required int seconds}) {
    _swipingTimer = Timer(Duration(seconds: seconds),
            () => setState(() => _isSwipingEnabled = true));
  }

  void selectLastDataPointOnViewLoad() {
    if (widget.onSelectMultiDataPoint != null && widget.data2 != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onSelectMultiDataPoint([data.first, data2.first]);
      });
    } else if (widget.onSelectDataPoint != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onSelectDataPoint(data.first);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final isSwipingRight = details.delta.dx > 2;
    final isSwipingLeft = details.delta.dx < -2;
    if (_isSwipingEnabled &&
        isSwipingRight &&
        lastDataPointDateTime.isBefore(startHorizontalAxisDateTime)) {
      setState(() {
        backSwipeNum++;
        _isSwipingEnabled = false;
      });
      enableSwipingAfter(seconds: 1);
    } else if (_isSwipingEnabled && isSwipingLeft && backSwipeNum > 0) {
      setState(() {
        backSwipeNum--;
        _isSwipingEnabled = false;
      });
      enableSwipingAfter(seconds: 1);
    }
  }

  List<charts.ChartBehavior> buildBehaviors() {
    return [
      charts.LinePointHighlighter(
        showHorizontalFollowLine:
        charts.LinePointHighlighterFollowLineType.nearest,
        showVerticalFollowLine:
        charts.LinePointHighlighterFollowLineType.nearest,
        drawFollowLinesAcrossChart: true,
      ),
      if (data2 != null && hasChartNames) charts.SeriesLegend(),
    ];
  }

  List<charts.Series<Map<DateTime, double>, DateTime>> _getSeriesList(
      List<Map<DateTime, double>> data,
      {List<Map<DateTime, double>> data2}) {
    return data2 == null
        ? [
      charts.Series<Map<DateTime, double>, DateTime>(
        id: 'first_chart',
        colorFn: (_, __) => charts.MaterialPalette.indigo.shadeDefault,
        domainFn: (Map<DateTime, double> measurement, _) =>
        measurement.keys.first,
        measureFn: (Map<DateTime, double> measurement, _) =>
        measurement.values.first,
        data: data,
      ),
    ]
        : [
      charts.Series<Map<DateTime, double>, DateTime>(
        id: widget.chartNames.first,
        colorFn: (_, __) => charts.MaterialPalette.indigo.shadeDefault,
        domainFn: (Map<DateTime, double> measurement, _) =>
        measurement.keys.first,
        measureFn: (Map<DateTime, double> measurement, _) =>
        measurement.values.first,
        data: data,
      ),
      charts.Series<Map<DateTime, double>, DateTime>(
        id: widget.chartNames.last,
        colorFn: (_, __) =>
        charts.MaterialPalette.deepOrange.shadeDefault,
        domainFn: (Map<DateTime, double> measurement, _) =>
        measurement.keys.first,
        measureFn: (Map<DateTime, double> measurement, _) =>
        measurement.values.first,
        data: data2,
      ),
    ];
  }

  /// ------------- Manipulate Data ------------- ///
  void preProcessInputData() {
    List<Map<DateTime, double>> _data = widget.data;
    List<Map<DateTime, double>> _data2 = widget.data2;

    if (widget.shouldSortDataRecentFirst) {
      _data.sort((a, b) => b.keys.first.compareTo(a.keys.first));
      if (_data2 != null) {
        _data2.sort((a, b) => b.keys.first.compareTo(a.keys.first));
      }
    }

    if (widget.dataPointsReductionMode !=
        DataPointsReductionMode.showAllPoints) {
      final _shouldCalculateAverage =
          widget.dataPointsReductionMode == DataPointsReductionMode.average;

      final _shouldReduceByMonth =
          widget.horizontalAxisDuration == HorizontalAxisDuration.year;

      final _shouldReduceByTenDays =
          widget.horizontalAxisDuration == HorizontalAxisDuration.threeMonths;

      _data = reduceMultipleDataPoints(_data,
          shouldCalculateAverage: _shouldCalculateAverage,
          reduceByMonth: _shouldReduceByMonth,
          reduceByTenDays: _shouldReduceByTenDays);

      if (_data2 != null) {
        _data2 = reduceMultipleDataPoints(_data2,
            shouldCalculateAverage: _shouldCalculateAverage,
            reduceByMonth: _shouldReduceByMonth,
            reduceByTenDays: _shouldReduceByTenDays);
      }
    }
    seriesList = _getSeriesList(_data, data2: _data2);
  }

  List<Map<DateTime, double>> reduceMultipleDataPoints(
      List<Map<DateTime, double>> inputList,
      {@required bool shouldCalculateAverage,
        bool reduceByMonth = false,
        bool reduceByTenDays = false}) {
    final outputList = <Map<DateTime, double>>[];
    final outputMap = <DateTime, double>{};

    for (final element in inputList) {
      DateTime key;
      if (reduceByMonth) {
        key = element.keys.first.toMonthOnly;
      } else if (reduceByTenDays) {
        key = element.keys.first.toTensDayOnly;
      } else {
        key = element.keys.first.toDateOnly;
      }
      if (outputMap.containsKey(key)) {
        outputMap[key] += element.values.first;
        if (shouldCalculateAverage) outputMap[key] /= 2;
      } else {
        outputMap[key] = element.values.first;
      }
    }
    outputMap.forEach((key, value) => outputList.add({key: value}));
    return outputList;
  }

  /// ------------- Draw Horizontal Axis ------------- ///
  charts.DateTimeAxisSpec buildHorizontalAxis(
      int backSwipeNum, HorizontalAxisDuration viewPortDomainAxisDuration) {
    if (viewPortDomainAxisDuration == HorizontalAxisDuration.year) {
      return buildYearlyHorizontalAxis(backSwipeNum);
    } else if (viewPortDomainAxisDuration ==
        HorizontalAxisDuration.threeMonths) {
      return buildTriMonthlyHorizontalAxis(backSwipeNum);
    } else if (viewPortDomainAxisDuration == HorizontalAxisDuration.month) {
      return buildMonthlyHorizontalAxis(backSwipeNum);
    }
    return buildWeeklyHorizontalAxis(backSwipeNum);
  }

  charts.DateTimeAxisSpec buildWeeklyHorizontalAxis(int backSwipeNum) {
    const int numOfHorizontalTicks = 7;
    return charts.DateTimeAxisSpec(
      viewport: getHorizontalViewPort(numOfHorizontalTicks, backSwipeNum),
      tickFormatterSpec: const charts.AutoDateTimeTickFormatterSpec(
        day: charts.TimeFormatterSpec(format: 'E', transitionFormat: 'E'),
      ),
      tickProviderSpec: const charts.DayTickProviderSpec(increments: [1]),
      renderSpec: getHorizontalAxisRenderSpec(),
    );
  }

  charts.DateTimeAxisSpec buildMonthlyHorizontalAxis(int backSwipeNum) {
    const int numOfHorizontalTicks = 30;
    return charts.DateTimeAxisSpec(
      viewport: getHorizontalViewPort(numOfHorizontalTicks, backSwipeNum),
      tickFormatterSpec: const charts.AutoDateTimeTickFormatterSpec(
        day: charts.TimeFormatterSpec(format: 'd', transitionFormat: 'd'),
      ),
      tickProviderSpec: const charts.DayTickProviderSpec(increments: [2]),
      renderSpec: getHorizontalAxisRenderSpec(),
    );
  }

  charts.DateTimeAxisSpec buildTriMonthlyHorizontalAxis(int backSwipeNum) {
    const int numOfHorizontalTicks = 3 * 30;
    return charts.DateTimeAxisSpec(
      viewport: getHorizontalViewPort(numOfHorizontalTicks, backSwipeNum),
      tickFormatterSpec: const charts.AutoDateTimeTickFormatterSpec(
        day: charts.TimeFormatterSpec(format: 'Md', transitionFormat: 'Md'),
        month: charts.TimeFormatterSpec(format: 'Md', transitionFormat: 'Md'),
      ),
      tickProviderSpec: const charts.DayTickProviderSpec(increments: [10]),
      renderSpec: getHorizontalAxisRenderSpec(),
    );
  }

  charts.DateTimeAxisSpec buildYearlyHorizontalAxis(int backSwipeNum) {
    const int numOfHorizontalTicks = 12 * 30;
    return charts.DateTimeAxisSpec(
      viewport: getHorizontalViewPort(numOfHorizontalTicks, backSwipeNum),
      tickFormatterSpec: const charts.AutoDateTimeTickFormatterSpec(
        month: charts.TimeFormatterSpec(format: 'MMM', transitionFormat: 'MMM'),
      ),
      renderSpec: getHorizontalAxisRenderSpec(),
    );
  }

  charts.RenderSpec<DateTime> getHorizontalAxisRenderSpec() {
    return charts.GridlineRendererSpec(
        labelStyle: charts.TextStyleSpec(
            fontSize: 10,
            color: backSwipeNum.isEven
                ? charts.MaterialPalette.black
                : charts.MaterialPalette.gray.shadeDefault),
        lineStyle: const charts.LineStyleSpec(
            thickness: 0, color: charts.MaterialPalette.transparent),
        axisLineStyle: charts.LineStyleSpec(
            thickness: 2, color: charts.MaterialPalette.gray.shadeDefault),
        minimumPaddingBetweenLabelsPx: 2,
        labelJustification: charts.TickLabelJustification.inside,
        labelOffsetFromAxisPx: 24);
  }

  charts.DateTimeExtents getHorizontalViewPort(
      int numOfHorizontalTicks, int backSwipeNum) {
    updateStartHorizontalAxis(numOfHorizontalTicks, backSwipeNum);
    updateEndHorizontalAxis(numOfHorizontalTicks, backSwipeNum);

    if (widget.onShouldLoadMoreData != null) {
      checkIfNextViewPortContainsLastDataPoint(
          numOfHorizontalTicks, backSwipeNum);
    }

    return charts.DateTimeExtents(
      start: startHorizontalAxisDateTime,
      end: endHorizontalAxisDateTime,
    );
  }

  void updateStartHorizontalAxis(int numOfHorizontalTicks, int backSwipeNum) {
    startHorizontalAxisDateTime = DateTime.now().subtract(Duration(
        days: numOfHorizontalTicks + numOfHorizontalTicks * backSwipeNum));
  }

  void updateEndHorizontalAxis(int numOfHorizontalTicks, int backSwipeNum) {
    endHorizontalAxisDateTime = DateTime.now()
        .subtract(Duration(days: numOfHorizontalTicks * backSwipeNum));
  }

  void checkIfNextViewPortContainsLastDataPoint(
      int numOfHorizontalTicks, int backSwipeNum) {
    final int nextSlide = backSwipeNum +
        widget.numberOfSlidesBeforeLastDataPointToTriggerLoadMoreData;

    final DateTime calculatedStartOfHorizontalAxisOfNextSlide = DateTime.now()
        .subtract(Duration(
        days: numOfHorizontalTicks + numOfHorizontalTicks * nextSlide))
        .toDateTimeWithHourOnly;

    startHorizontalAxisOfNextSlideDateTime ??= startHorizontalAxisDateTime;

    if (widget.onShouldLoadMoreData != null &&
        calculatedStartOfHorizontalAxisOfNextSlide
            .isBefore(lastDataPointDateTime) &&
        !startHorizontalAxisOfNextSlideDateTime
            .isAtSameMomentAs(calculatedStartOfHorizontalAxisOfNextSlide)) {
      widget.onShouldLoadMoreData(calculatedStartOfHorizontalAxisOfNextSlide);
      startHorizontalAxisOfNextSlideDateTime =
          calculatedStartOfHorizontalAxisOfNextSlide;
    }
  }

  /// ------------- Draw Vertical Axis ------------- ///
  charts.NumericAxisSpec buildVerticalAxis(
      int multiple, List<Map<DateTime, double>> data) {
    if (multiple != null) {
      return buildVerticalAxisWithCalculatedTicks(multiple, data);
    }
    return buildVerticalAxisWithVariableTickNumber(data);
  }

  charts.NumericAxisSpec buildVerticalAxisWithCalculatedTicks(
      int multiple, List<Map<DateTime, double>> data) {
    final double maxMeasurementInList =
    data.map((e) => e.values.first).reduce(math.max);
    final double minMeasurementInList =
    data.map((e) => e.values.first).reduce(math.min);
    final int roundedUpperBound = roundUp(maxMeasurementInList, multiple);
    final int roundedLowerBound = roundDown(minMeasurementInList, multiple);
    final int desiredTickCount = calculateVerticalTickCount(
        roundedUpperBound, roundedLowerBound, multiple);

    return charts.NumericAxisSpec(
      viewport: charts.NumericExtents(roundedLowerBound, roundedUpperBound),
      tickProviderSpec: charts.BasicNumericTickProviderSpec(
        zeroBound: false,
        dataIsInWholeNumbers: false,
        desiredTickCount: desiredTickCount,
      ),
      renderSpec: getVerticalAxisRenderSpec(),
      tickFormatterSpec: charts.BasicNumericTickFormatterSpec((num measure) {
        if (verticalAxisDisplayedUnit != null) {
          return '${measure.toStringAsFixed(0)} $verticalAxisDisplayedUnit';
        } else {
          return measure.toStringAsFixed(0);
        }
      }),
    );
  }

  charts.NumericAxisSpec buildVerticalAxisWithVariableTickNumber(
      List<Map<DateTime, double>> data) {
    final double maxMeasurementInList =
    data.map((e) => e.values.first).reduce(math.max);
    final double minMeasurementInList =
    data.map((e) => e.values.first).reduce(math.min);

    return charts.NumericAxisSpec(
      viewport:
      charts.NumericExtents(minMeasurementInList, maxMeasurementInList),
      tickProviderSpec: const charts.BasicNumericTickProviderSpec(
        zeroBound: false,
        dataIsInWholeNumbers: false,
      ),
      renderSpec: getVerticalAxisRenderSpec(),
    );
  }

  charts.RenderSpec<num> getVerticalAxisRenderSpec() {
    return charts.GridlineRendererSpec(
      labelStyle: charts.TextStyleSpec(
          fontSize: 10, color: charts.MaterialPalette.gray.shade800),
      lineStyle: charts.LineStyleSpec(
          thickness: 1, color: charts.MaterialPalette.gray.shade200),
      minimumPaddingBetweenLabelsPx: 2,
      labelJustification: charts.TickLabelJustification.inside,
      labelOffsetFromAxisPx: 24,
    );
  }

  int roundUp(double num, int multiple) =>
      (num + multiple - num.remainder(multiple)).truncate();

  int roundDown(double num, int multiple) =>
      (num - num.remainder(multiple)).truncate();

  int calculateVerticalTickCount(
      int upperBound, int lowerBound, int multiple) =>
      (upperBound - lowerBound) ~/ multiple + 1;
}

enum DataPointsReductionMode { sum, average, showAllPoints }
enum HorizontalAxisDuration { week, month, threeMonths, year }

extension on DateTime {
  DateTime get toDateTimeWithHourOnly => DateTime(year, month, day, hour);
  DateTime get toDateOnly => DateTime(year, month, day);
  DateTime get toMonthOnly => DateTime(year, month);
  DateTime get toTensDayOnly {
    int _calcDay;
    if (day <= 7) {
      _calcDay = 7;
    } else if (day <= 14) {
      _calcDay = 14;
    } else if (day <= 21) {
      _calcDay = 21;
    } else {
      _calcDay = 28;
    }
    return DateTime(year, month, _calcDay);
  }
}