import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/project.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  List<Project> _projects = [];
  Map<String, List<String>> _dateProjectMap = {};

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await DatabaseHelper.instance.getAllProjects();
    final map = <String, List<String>>{};
    for (final p in projects) {
      for (final d in p.scheduleDates) {
        map.putIfAbsent(d, () => []).add(p.projectName);
      }
    }
    setState(() {
      _projects = projects;
      _dateProjectMap = map;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) { _month = 1; _year++; }
      if (_month < 1) { _month = 12; _year--; }
      if (_year < 2021) _year = 2021;
      if (_year > 2099) _year = 2099;
    });
  }

  List<Widget> _buildCalendarCells() {
    final firstDay = DateTime(_year, _month, 1);
    final startWeekday = (firstDay.weekday - 1) % 7; // 周一开头：周一=0，周日=6
    final daysInMonth = DateUtils.getDaysInMonth(_year, _month);
    final prevMonth = _month == 1 ? 12 : _month - 1;
    final prevYear = _month == 1 ? _year - 1 : _year;
    final prevDays = DateUtils.getDaysInMonth(prevYear, prevMonth);

    final cells = <Widget>[];

    for (int i = 0; i < startWeekday; i++) {
      final d = prevDays - startWeekday + 1 + i;
      cells.add(_buildCell(d, isOtherMonth: true));
    }

    final today = DateTime.now();
    for (int d = 1; d <= daysInMonth; d++) {
      final isToday = _year == today.year && _month == today.month && d == today.day;
      final dateStr = '$_year-${_month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      final projectsForDate = _dateProjectMap[dateStr] ?? [];
      final dayIndex = (startWeekday + d - 1) % 7;
      final isWeekend = dayIndex == 5 || dayIndex == 6; // 周六=5, 周日=6
      cells.add(_buildCell(d, isToday: isToday, projects: projectsForDate, dateStr: dateStr, isWeekend: isWeekend));
    }

    final totalCells = startWeekday + daysInMonth;
    final remaining = (7 - totalCells % 7) % 7;
    for (int i = 1; i <= remaining; i++) {
      cells.add(_buildCell(i, isOtherMonth: true));
    }

    return cells;
  }

  Widget _buildCell(int day, {bool isOtherMonth = false, bool isToday = false, List<String> projects = const [], String? dateStr, bool isWeekend = false}) {
    return GestureDetector(
      onTap: isOtherMonth ? null : () => _onDateTap(dateStr!),
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFF1677FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                color: isOtherMonth
                    ? const Color(0xFFCCCCCC)
                    : isToday
                        ? Colors.white
                        : isWeekend
                    ? const Color(0xFFE84A3F)
                    : const Color(0xFF2C2C2A),
              ),
            ),
            if (projects.isNotEmpty && !isOtherMonth) ...[
              const SizedBox(height: 2),
              ...projects.take(2).map((name) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: isToday ? Colors.white.withOpacity(0.3) : const Color(0xFF1677FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  name.length > 4 ? name.substring(0, 4) : name,
                  style: TextStyle(
                    fontSize: 9,
                    color: isToday ? Colors.white : const Color(0xFF1677FF),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  void _onDateTap(String dateStr) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddProjectSheet(dateStr: dateStr, onSaved: _loadProjects),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = List.generate(12, (i) => '${i + 1}月');
    final yearNames = List.generate(2099 - 2021 + 1, (i) => '${2021 + i}年');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('日程'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1677FF)),
            onPressed: () {
              final today = DateTime.now();
              final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              _onDateTap(dateStr);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    DropdownButton<String>(
                      value: '$_year年',
                      items: yearNames.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                      onChanged: (v) => setState(() => _year = int.parse(v!.replaceAll('年', ''))),
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: '${_month}月',
                      items: monthNames.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setState(() => _month = int.parse(v!.replaceAll('月', ''))),
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _navButton(Icons.chevron_left, () => _changeMonth(-1)),
                    const SizedBox(width: 20),
                    _navButton(Icons.chevron_right, () => _changeMonth(1)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: const [
                Expanded(child: Center(child: Text('日', style: TextStyle(fontSize: 12, color: Color(0xFFE84A3F), fontWeight: FontWeight.w500)))),
                Expanded(child: Center(child: Text('一', style: TextStyle(fontSize: 12, color: Color(0xFF999999))))),
                Expanded(child: Center(child: Text('二', style: TextStyle(fontSize: 12, color: Color(0xFF999999))))),
                Expanded(child: Center(child: Text('三', style: TextStyle(fontSize: 12, color: Color(0xFF999999))))),
                Expanded(child: Center(child: Text('四', style: TextStyle(fontSize: 12, color: Color(0xFF999999))))),
                Expanded(child: Center(child: Text('五', style: TextStyle(fontSize: 12, color: Color(0xFF999999))))),
                Expanded(child: Center(child: Text('六', style: TextStyle(fontSize: 12, color: Color(0xFFE84A3F), fontWeight: FontWeight.w500)))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GridView.count(
                crossAxisCount: 7,
                childAspectRatio: 0.85,
                children: _buildCalendarCells(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, size: 28, color: const Color(0xFF555555)),
        ),
      ),
    );
  }
}

class _AddProjectSheet extends StatefulWidget {
  final String dateStr;
  final VoidCallback onSaved;

  const _AddProjectSheet({required this.dateStr, required this.onSaved});

  @override
  State<_AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends State<_AddProjectSheet> {
  final _nameController = TextEditingController();
  final _clientController = TextEditingController();
  final _typeController = TextEditingController();
  final _totalController = TextEditingController();
  final _receivedController = TextEditingController();
  final _remarkController = TextEditingController();
  bool _isSettled = false;
  bool _isExisting = false;
  Project? _existingProject;
  List<String> _projectNameSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final names = await DatabaseHelper.instance.getAllProjectNames();
    setState(() => _projectNameSuggestions = names);
  }

  void _checkExisting(String name) async {
    if (name.isEmpty) {
      setState(() { _isExisting = false; _existingProject = null; });
      return;
    }
    final proj = await DatabaseHelper.instance.getProjectByName(name);
    setState(() {
      _isExisting = proj != null;
      _existingProject = proj;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (_isExisting && _existingProject != null) {
      final newDates = [..._existingProject!.scheduleDates];
      if (!newDates.contains(widget.dateStr)) newDates.add(widget.dateStr);
      newDates.sort();
      await DatabaseHelper.instance.appendDates(name, newDates);
    } else {
      final proj = Project(
        projectName: name,
        scheduleDates: [widget.dateStr],
        clientName: _clientController.text.trim().isNotEmpty ? _clientController.text.trim() : null,
        projectType: _typeController.text.trim().isNotEmpty ? _typeController.text.trim() : null,
        totalAmount: double.tryParse(_totalController.text) ?? 0.0,
        receivedAmount: double.tryParse(_receivedController.text) ?? 0.0,
        isSettled: _isSettled,
        remarks: _remarkController.text.trim().isNotEmpty ? _remarkController.text.trim() : null,
      );
      await DatabaseHelper.instance.createProject(proj);
    }

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('添加日程', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '项目名称 *',
                border: OutlineInputBorder(),
              ),
              onChanged: _checkExisting,
            ),
            if (_isExisting)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('已关联已有项目，金额等信息保持不变', style: TextStyle(fontSize: 13, color: Color(0xFF8A6D0))),
              ),
            const SizedBox(height: 12),
            if (!_isExisting) ...[
              TextField(
                controller: _clientController,
                decoration: const InputDecoration(labelText: '客户名称', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: '项目类型', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '项目总额', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _receivedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '已收金额', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('是否结清'),
                value: _isSettled,
                onChanged: (v) => setState(() => _isSettled = v),
              ),
              TextField(
                controller: _remarkController,
                decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1677FF),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
