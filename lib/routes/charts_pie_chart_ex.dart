import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;

import 'widgets_dropdown_button_ex.dart';

/// Data class to visualize.
class _CostsData {
  final String category;
  final int cost;

  const _CostsData(this.category, this.cost);
}

class PieChartExample extends StatefulWidget {
  const PieChartExample({super.key});

  @override
  _PieChartExampleState createState() => _PieChartExampleState();
}

class _PieChartExampleState extends State<PieChartExample> {
  // Chart configs.
  bool _animate = true;
  bool _defaultInteractions = true;
  double _arcRatio = 0.8;
  charts.ArcLabelPosition _arcLabelPosition = charts.ArcLabelPosition.auto;
  charts.BehaviorPosition _titlePosition = charts.BehaviorPosition.bottom;
  charts.BehaviorPosition _legendPosition = charts.BehaviorPosition.bottom;

  // Data to render.
  final List<_CostsData> _data = [
    const _CostsData('housing', 1000),
    const _CostsData('food', 500),
    const _CostsData('health', 200),
    const _CostsData('trasport', 100),
  ];

  @override
  Widget build(BuildContext context) {
    final _colorPalettes =
        charts.MaterialPalette.getOrderedPalettes(this._data.length);
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        SizedBox(
          height: 300,
          // MUST specify the type T, see https://github.com/google/charts/issues/668#issuecomment-943556524.
          child: charts.PieChart<String>(
            // Pie chart can only render one series.
            /*seriesList=*/ [
              charts.Series<_CostsData, String>(
                id: 'Sales-1',
                colorFn: (_, idx) => _colorPalettes[idx!].shadeDefault,
                domainFn: (_CostsData sales, _) => sales.category,
                measureFn: (_CostsData sales, _) => sales.cost,
                data: this._data,
                // Set a label accessor to control the text of the arc label.
                labelAccessorFn: (_CostsData row, _) =>
                    '${row.category}: ${row.cost}',
              ),
            ],
            animate: this._animate,
            defaultRenderer: charts.ArcRendererConfig(
              arcRatio: this._arcRatio,
              arcRendererDecorators: [
                charts.ArcLabelDecorator(labelPosition: this._arcLabelPosition)
              ],
            ),
            behaviors: [
              // Add title.
              charts.ChartTitle(
                'Dummy costs breakup',
                behaviorPosition: this._titlePosition,
              ),
              // Add legend. ("Datum" means the "X-axis" of each data point.)
              charts.DatumLegend(
                position: this._legendPosition,
                desiredMaxRows: 2,
              ),
            ],
          ),
        ),
        const Divider(),
        ..._controlWidgets(),
      ],
    );
  }

  /// Widgets to control the chart appearance and behavior.
  List<Widget> _controlWidgets() => <Widget>[
        SwitchListTile(
          title: const Text('animate'),
          onChanged: (bool val) => setState(() => this._animate = val),
          value: this._animate,
        ),
        SwitchListTile(
          title: const Text('defaultInteractions'),
          onChanged: (bool val) =>
              setState(() => this._defaultInteractions = val),
          value: this._defaultInteractions,
        ),
        const ListTile(title: Text('Arc width ratio w.r.t. radius:')),
        Slider(
          divisions: 10,
          onChanged: (double val) => setState(() => this._arcRatio = val),
          value: this._arcRatio,
          label: '${this._arcRatio}',
        ),
        MyValuePickerTile(
          val: this._arcLabelPosition,
          values: charts.ArcLabelPosition.values,
          title: 'arcLabelPosition:',
          onChanged: (charts.ArcLabelPosition newVal) {
            setState(() => this._arcLabelPosition = newVal);
          },
        ),
        MyValuePickerTile(
          val: this._titlePosition,
          values: charts.BehaviorPosition.values,
          title: 'titlePosition:',
          onChanged: (charts.BehaviorPosition newVal) {
            setState(() => this._titlePosition = newVal);
          },
        ),
        MyValuePickerTile(
          val: this._legendPosition,
          values: charts.BehaviorPosition.values,
          title: 'legendPosition:',
          onChanged: (charts.BehaviorPosition newVal) {
            setState(() => this._legendPosition = newVal);
          },
        ),
      ];
}
