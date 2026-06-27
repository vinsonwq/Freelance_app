import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/project.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _selectedYear = DateTime.now().year;
  double _yearTotal = 0;
  int _yearCount = 0;
  double _yearReceived = 0;
  double _yearUnreceived = 0;
  double _receivedPercent = 0;
  List<double> _monthlyIncome = List.filled(12, 0);
  Map<String, double> _typeDistribution = {};
  Map<String, double> _clientDistribution = {};
  bool _showBarChart = true;
  bool _showTypePie = true;
  bool _showClientPie = true;
  int _touchedBarIndex = -1;
  int _touchedTypeIndex = -1;
  int _touchedClientIndex = -1;

  final _colors = [
    const Color(0xFF1677FF),
    const Color(0xFF17A96E),
    const Color(0xFFFF8C00),
    const Color(0xFFE84A3F),
    const Color(0xFF9B59B6),
    const Color(0xFF1ABC9C),
    const Color(0xFF3498DB),
    const Color(0xFFE67E22),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showBarChart = prefs.getBool('show_bar_chart') ?? true;
      _showTypePie = prefs.getBool('show_type_pie') ?? true;
      _showClientPie = prefs.getBool('show_client_pie') ?? true;
    });
  }

  Future<void> _toggleChart(String key, bool value) async {
    setState(() {
      switch (key) {
        case 'show_bar_chart':
          _showBarChart = value;
          break;
        case 'show_type_pie':
          _showTypePie = value;
          break;
        case 'show_client_pie':
          _showClientPie = value;
          break;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _loadData() async {
    final projects =
        await DatabaseHelper.instance.getProjectsByYear(_selectedYear);
    double total = 0;
    double received = 0;
    final monthly = List<double>.filled(12, 0);
    final typeMap = <String, double>{};
    final clientMap = <String, double>{};

    for (final p in projects) {
      total += p.totalAmount;
      received += p.receivedAmount;
      for (final d in p.scheduleDates) {
        if (d.startsWith('$_selectedYear-')) {
          final month = int.parse(d.substring(5, 7)) - 1;
          monthly[month] += p.totalAmount;
        }
      }
      typeMap[p.projectType ?? '未分类'] =
          (typeMap[p.projectType ?? '未分类'] ?? 0) + p.totalAmount;
      clientMap[p.clientName ?? '未指定'] =
          (clientMap[p.clientName ?? '未指定'] ?? 0) + p.totalAmount;
    }

    setState(() {
      _yearTotal = total;
      _yearCount = projects.length;
      _yearReceived = received;
      _yearUnreceived = total - received;
      _receivedPercent = total > 0 ? (received / total * 100) : 0;
      _monthlyIncome = monthly;
      _typeDistribution = typeMap;
      _clientDistribution = clientMap;
    });
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('选择年份',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 80,
                  itemBuilder: (_, i) {
                    final year = 2024 + i;
                    final isSelected = year == _selectedYear;
                    return ListTile(
                      title: Center(
                        child: Text(
                          '$year年',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF1677FF)
                                : const Color(0xFF333333),
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedYear = year);
                        _loadData();
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('统计分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF555555)),
            onPressed: () => _showChartSettings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            _buildYearSelector(),
            const SizedBox(height: 10),
            _buildMetricCards(),
            const SizedBox(height: 10),
            _buildProgressCard(),
            const SizedBox(height: 10),
            if (_showBarChart) _buildBarChart(),
            if (_showBarChart) const SizedBox(height: 10),
            if (_showTypePie)
              _buildDonutChart('项目类型分布', _typeDistribution, _touchedTypeIndex,
                  (i) => setState(() => _touchedTypeIndex = i)),
            if (_showTypePie) const SizedBox(height: 10),
            if (_showClientPie)
              _buildDonutChart(
                  '客户金额占比',
                  _clientDistribution,
                  _touchedClientIndex,
                  (i) => setState(() => _touchedClientIndex = i)),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFFE8EAED), blurRadius: 3, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('年度统计',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333))),
          GestureDetector(
            onTap: _showYearPicker,
            child: Row(
              children: [
                Text(
                  '$_selectedYear',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1677FF)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down,
                    size: 14, color: Color(0xFF1677FF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFFE8EAED), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              _metricItem('年度总收入', '¥${_yearTotal.toStringAsFixed(0)}',
                  Icons.trending_up, const Color(0xFF1677FF)),
              const SizedBox(width: 16),
              _metricItem(
                  '总项目数', '$_yearCount', Icons.layers, const Color(0xFF17A96E)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricItem('已收款', '¥${_yearReceived.toStringAsFixed(0)}',
                  Icons.check_circle_outline, const Color(0xFF17A96E)),
              const SizedBox(width: 16),
              _metricItem('未收款', '¥${_yearUnreceived.toStringAsFixed(0)}',
                  Icons.pending_outlined, const Color(0xFFFF8C00)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF999999))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFFE8EAED), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _receivedPercent / 100,
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFFF0F0F0),
                  color: const Color(0xFF1677FF),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_receivedPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333)),
                    ),
                    const Text('收款率',
                        style:
                            TextStyle(fontSize: 8, color: Color(0xFF999999))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('收款进度',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333))),
                const SizedBox(height: 6),
                _progressDetail('已收款', _yearReceived, const Color(0xFF17A96E)),
                const SizedBox(height: 6),
                _progressDetail(
                    '未收款', _yearUnreceived, const Color(0xFFFF8C00)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressDetail(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
        const SizedBox(width: 6),
        Text('¥${value.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFFE8EAED), blurRadius: 3, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('月度收入',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333))),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_monthlyIncome.reduce(max) * 1.3)
                    .ceilToDouble()
                    .clamp(1.0, double.infinity),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '¥${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      );
                    },
                  ),
                  touchCallback: (event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        _touchedBarIndex = -1;
                        return;
                      }
                      _touchedBarIndex =
                          barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        return Text(
                          '${value.toInt() + 1}月',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFFAAAAAA)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                              fontSize: 9, color: Color(0xFFAAAAAA)),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (_monthlyIncome.reduce(max) / 5).clamp(1.0, double.infinity),
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: Color(0xFFF0F0F0), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (i) {
                  final isTouched = i == _touchedBarIndex;
                  final color = isTouched
                      ? const Color(0xFF0E5DE5)
                      : const Color(0xFF1677FF);
                  final width = isTouched ? 22.0 : 16.0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _monthlyIncome[i],
                        color: color,
                        width: width,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(String title, Map<String, double> data,
      int touchedIndex, Function(int) onTouch) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFFE8EAED), blurRadius: 3, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333))),
          const SizedBox(height: 8),
          if (data.isEmpty)
            Center(
              child: Text('暂无数据',
                  style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: PieChart(
                    PieChartData(
                      sections: List.generate(entries.length, (i) {
                        final entry = entries[i];
                        final isTouched = i == touchedIndex;
                        final radius = isTouched ? 35.0 : 32.0;
                        return PieChartSectionData(
                          value: entry.value,
                          color: _colors[i % _colors.length],
                          radius: radius,
                          title: '',
                          borderSide: isTouched
                              ? const BorderSide(color: Colors.white, width: 2)
                              : null,
                        );
                      }),
                      sectionsSpace: 2,
                      centerSpaceRadius: 22,
                      centerSpaceColor: Colors.transparent,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              onTouch(-1);
                              return;
                            }
                            onTouch(pieTouchResponse
                                .touchedSection!.touchedSectionIndex);
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: _colors[0], shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text('¥${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...List.generate(entries.length, (i) {
                        final entry = entries[i];
                        final isTouched = i == touchedIndex;
                        final pct = total > 0
                            ? (entry.value / total * 100).toStringAsFixed(0)
                            : '0';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: () => onTouch(isTouched ? -1 : i),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _colors[i % _colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isTouched
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                      color: isTouched
                                          ? const Color(0xFF1677FF)
                                          : const Color(0xFF555555),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('¥${entry.value.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 4),
                                Text('$pct%',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF999999))),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showChartSettings() {
    showDialog(
      context: context,
      builder: (ctx) {
        bool showBar = _showBarChart;
        bool showType = _showTypePie;
        bool showClient = _showClientPie;

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('图表设置'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('收入柱状图'),
                  value: showBar,
                  onChanged: (v) {
                    setState(() => showBar = v!);
                    _toggleChart('show_bar_chart', v!);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('类型饼图'),
                  value: showType,
                  onChanged: (v) {
                    setState(() => showType = v!);
                    _toggleChart('show_type_pie', v!);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('客户饼图'),
                  value: showClient,
                  onChanged: (v) {
                    setState(() => showClient = v!);
                    _toggleChart('show_client_pie', v!);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
            ],
          ),
        );
      },
    );
  }
}
