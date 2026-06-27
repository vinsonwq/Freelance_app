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
  List<double> _monthlyIncome = List.filled(12, 0);
  Map<String, double> _typeDistribution = {};
  Map<String, double> _clientDistribution = {};
  bool _showBarChart = true;
  bool _showTypePie = true;
  bool _showClientPie = true;

  final _colors = [
    const Color(0xFF1677FF),
    const Color(0xFF17A96E),
    const Color(0xFFFF8C00),
    const Color(0xFFE84A3F),
    const Color(0xFF9B59B6),
    const Color(0xFF1ABC9C),
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    _loadSettings();
  }

  Future<void> _loadData() async {
    final projects = await DatabaseHelper.instance.getProjectsByYear(_selectedYear);
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
      typeMap[p.projectType ?? '未分类'] = (typeMap[p.projectType ?? '未分类'] ?? 0) + p.totalAmount;
      clientMap[p.clientName ?? '未指定'] = (clientMap[p.clientName ?? '未指定'] ?? 0) + p.totalAmount;
    }

    setState(() {
      _yearTotal = total;
      _yearCount = projects.length;
      _yearReceived = received;
      _monthlyIncome = monthly;
      _typeDistribution = typeMap;
      _clientDistribution = clientMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF555555)),
            onPressed: () => _showChartSettings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricCards(),
            const SizedBox(height: 16),
            if (_showBarChart) _buildBarChart(),
            if (_showBarChart) const SizedBox(height: 16),
            if (_showTypePie) _buildPieChart('项目类型分布', _typeDistribution),
            if (_showTypePie) const SizedBox(height: 16),
            if (_showClientPie) _buildPieChart('客户金额占比', _clientDistribution),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    return Row(
      children: [
        Expanded(
          child: _metricCard('年度总收入', '¥${_yearTotal.toStringAsFixed(0)}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard('总项目数', '$_yearCount', color: const Color(0xFF17A96E)),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color ?? const Color(0xFF1677FF))),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('月度收入', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  IconButton(
                    onPressed: _selectedYear > 2021
                        ? () => setState(() { _selectedYear--; _loadData(); })
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text('$_selectedYear', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  IconButton(
                    onPressed: _selectedYear < 2099
                        ? () => setState(() { _selectedYear++; _loadData(); })
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_monthlyIncome.reduce(max) * 1.2).ceilToDouble().clamp(1.0, double.infinity),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        return Text('${value.toInt() + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _monthlyIncome[i],
                        color: const Color(0xFF1677FF),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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

  Widget _buildPieChart(String title, Map<String, double> data) {
    if (data.isEmpty) return const SizedBox();
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: PieChart(
                  PieChartData(
                    sections: List.generate(entries.length, (i) {
                      final entry = entries[i];
                      final pct = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
                      return PieChartSectionData(
                        value: entry.value,
                        color: _colors[i % _colors.length],
                        radius: 40,
                        title: '',
                      );
                    }),
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(entries.length, (i) {
                    final entry = entries[i];
                    final pct = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _colors[i % _colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 12, color: Color(0xFF555555)), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text('$pct%', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        ],
                      ),
                    );
                  }),
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
      builder: (ctx) => AlertDialog(
        title: const Text('图表设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _settingsCheckbox('收入柱状图', _showBarChart, (v) => _toggleChart('show_bar_chart', v!)),
            _settingsCheckbox('类型饼图', _showTypePie, (v) => _toggleChart('show_type_pie', v!)),
            _settingsCheckbox('客户饼图', _showClientPie, (v) => _toggleChart('show_client_pie', v!)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _settingsCheckbox(String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
