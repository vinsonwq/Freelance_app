import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/project.dart';
import 'project_detail_page.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  String _timeMode = 'month';
  int _selectedYear = DateTime.now().year;
  int _selectedQuarter = 2;
  int _selectedMonth = DateTime.now().month;
  String _filterClient = '';
  String _filterType = '';
  String _filterSettled = '全部';
  List<Project> _projects = [];
  double _totalAmount = 0;
  double _totalReceived = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    List<Project> projects;
    if (_timeMode == 'year') {
      projects = await DatabaseHelper.instance.getProjectsByYear(_selectedYear);
    } else if (_timeMode == 'quarter') {
      projects = await DatabaseHelper.instance.getProjectsByQuarter(_selectedYear, _selectedQuarter);
    } else {
      projects = await DatabaseHelper.instance.getProjectsByMonth(_selectedYear, _selectedMonth);
    }

    if (_filterClient.isNotEmpty) {
      projects = projects.where((p) => p.clientName == _filterClient).toList();
    }
    if (_filterType.isNotEmpty) {
      projects = projects.where((p) => p.projectType == _filterType).toList();
    }
    if (_filterSettled == '已结清') {
      projects = projects.where((p) => p.isSettled).toList();
    } else if (_filterSettled == '未结清') {
      projects = projects.where((p) => !p.isSettled).toList();
    }

    double total = 0;
    double received = 0;
    for (final p in projects) {
      total += p.totalAmount;
      received += p.receivedAmount;
    }

    setState(() {
      _projects = projects;
      _totalAmount = total;
      _totalReceived = received;
    });
  }

  String _getDateLabel(Project p) {
    final dates = p.scheduleDates;
    if (dates.isEmpty) return '';
    if (dates.length == 1) return dates.first.substring(5);
    return '${dates.first.substring(5)} ~ ${dates.last.substring(5)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text('项目列表')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildTimeTabs(),
                const SizedBox(height: 10),
                _buildFilters(),
                const SizedBox(height: 10),
                _buildSummary(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _projects.isEmpty
                ? const Center(child: Text('暂无数据', style: TextStyle(color: Color(0xFF999999))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _projects.length,
                    itemBuilder: (ctx, i) => _buildProjectCard(_projects[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: ['年', '季度', '月份'].asMap().entries.map((entry) {
          final idx = entry.key;
          final label = entry.value;
          final modes = ['year', 'quarter', 'month'];
          final isActive = _timeMode == modes[idx];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _timeMode = modes[idx]);
                _loadData();
              },
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive
                      ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                      : null,
                ),
                child: Center(
                  child: Text(label, style: TextStyle(fontSize: 13, color: isActive ? const Color(0xFF1677FF) : const Color(0xFF666666))),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _filterChip('全部客户', _filterClient, (v) => setState(() => _filterClient = v)),
        _filterChip('全部类型', _filterType, (v) => setState(() => _filterType = v)),
        _filterChip('全部状态', _filterSettled, (v) => setState(() => _filterSettled = v)),
      ],
    );
  }

  Widget _filterChip(String label, String value, Function(String) onChanged) {
    return FutureBuilder<List<String>>(
      future: label.contains('客户')
          ? DatabaseHelper.instance.getAllClientNames()
          : label.contains('类型')
              ? DatabaseHelper.instance.getAllProjectTypeNames()
              : null,
      builder: (ctx, snapshot) {
        final items = snapshot.data ?? [];
        if (label.contains('状态')) {
          return _buildDropdown(label, _filterSettled, ['全部', '已结清', '未结清'], (v) {
            setState(() => _filterSettled = v!);
            _loadData();
          });
        }
        final options = [label, ...items];
        return _buildDropdown(label, value.isEmpty ? label : value, options, (v) {
          onChanged(v == label ? '' : v!);
          _loadData();
        });
      },
    );
  }

  Widget _buildDropdown(String hint, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8EAED)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        hint: Text(hint, style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 12)))).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        isDense: true,
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE8EAED), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryItem('总金额', '¥${_totalAmount.toStringAsFixed(0)}')),
          Container(width: 0.5, height: 30, color: const Color(0xFFE8EAED)),
          Expanded(child: _summaryItem('项目数', '${_projects.length}')),
          Container(width: 0.5, height: 30, color: const Color(0xFFE8EAED)),
          Expanded(child: _summaryItem('已收款', '¥${_totalReceived.toStringAsFixed(0)}', color: const Color(0xFF17A96E))),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color ?? const Color(0xFF1677FF))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
      ],
    );
  }

  Widget _buildProjectCard(Project p) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ProjectDetailPage(project: p),
          ),
        );
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EAED), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(p.projectName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                  Text('¥${p.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1677FF))),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (p.projectType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(4)),
                      child: Text(p.projectType!, style: const TextStyle(fontSize: 11, color: Color(0xFF1677FF))),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.isSettled ? const Color(0xFFF0FAF5) : const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(p.isSettled ? '已结清' : '未结清', style: TextStyle(fontSize: 11, color: p.isSettled ? const Color(0xFF17A96E) : const Color(0xFFE87C17))),
                  ),
                  Text(_getDateLabel(p), style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
