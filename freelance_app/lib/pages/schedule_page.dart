import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/project.dart';
import '../models/project_type.dart';
import '../models/client.dart';

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
  Map<String, String> _projectTypeMap = {}; // 项目名称 -> 项目类型
  Map<String, String> _typeColorMap = {}; // 项目类型 -> 颜色

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await DatabaseHelper.instance.getAllProjects();
    final types = await DatabaseHelper.instance.getAllProjectTypes();

    final map = <String, List<String>>{};
    final typeMap = <String, String>{};
    final colorMap = <String, String>{};

    for (final p in projects) {
      for (final d in p.scheduleDates) {
        map.putIfAbsent(d, () => []).add(p.projectName);
      }
      if (p.projectType != null && p.projectType!.isNotEmpty) {
        typeMap[p.projectName] = p.projectType!;
      }
    }

    for (final t in types) {
      colorMap[t.name] = t.colorHex;
    }

    setState(() {
      _projects = projects;
      _dateProjectMap = map;
      _projectTypeMap = typeMap;
      _typeColorMap = colorMap;
    });
  }

  Color _getProjectColor(String projectName, bool isToday) {
    final typeName = _projectTypeMap[projectName];
    if (typeName != null && _typeColorMap.containsKey(typeName)) {
      try {
        final color = Color(
            int.parse(_typeColorMap[typeName]!.replaceFirst('#', '0xFF')));
        return isToday ? color.withOpacity(0.9) : color.withOpacity(0.15);
      } catch (_) {}
    }
    return isToday
        ? Colors.white.withOpacity(0.3)
        : const Color(0xFF6366F1).withOpacity(0.15);
  }

  Color _getProjectTextColor(String projectName, bool isToday) {
    if (isToday) return Colors.white;
    final typeName = _projectTypeMap[projectName];
    if (typeName != null && _typeColorMap.containsKey(typeName)) {
      try {
        return Color(
            int.parse(_typeColorMap[typeName]!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return const Color(0xFF6366F1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) {
        _month = 1;
        _year++;
      }
      if (_month < 1) {
        _month = 12;
        _year--;
      }
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
      final isToday =
          _year == today.year && _month == today.month && d == today.day;
      final dateStr =
          '$_year-${_month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      final projectsForDate = _dateProjectMap[dateStr] ?? [];
      final dayIndex = (startWeekday + d - 1) % 7;
      final isWeekend = dayIndex == 5 || dayIndex == 6; // 周六=5, 周日=6
      cells.add(_buildCell(d,
          isToday: isToday,
          projects: projectsForDate,
          dateStr: dateStr,
          isWeekend: isWeekend));
    }

    final totalCells = startWeekday + daysInMonth;
    final remaining = (7 - totalCells % 7) % 7;
    for (int i = 1; i <= remaining; i++) {
      cells.add(_buildCell(i, isOtherMonth: true));
    }

    return cells;
  }

  Widget _buildCell(int day,
      {bool isOtherMonth = false,
      bool isToday = false,
      List<String> projects = const [],
      String? dateStr,
      bool isWeekend = false}) {
    return GestureDetector(
      onTap: isOtherMonth ? null : () => _onDateTap(dateStr!),
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFF6366F1) : Colors.transparent,
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getProjectColor(name, isToday),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      name.length > 4 ? name.substring(0, 4) : name,
                      style: TextStyle(
                        fontSize: 9,
                        color: _getProjectTextColor(name, isToday),
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
      builder: (ctx) =>
          _AddProjectSheet(dateStr: dateStr, onSaved: _loadProjects),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = List.generate(12, (i) => '${i + 1}月');
    final yearNames = List.generate(2099 - 2021 + 1, (i) => '${2021 + i}年');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('日程'),
        leading: const SizedBox(),
        actions: [
          GestureDetector(
            onTap: () {
              final today = DateTime.now();
              final dateStr =
                  '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              _onDateTap(dateStr);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.add, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text('添加',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: '$_year年',
                        items: yearNames
                            .map((y) =>
                                DropdownMenuItem(value: y, child: Text(y)))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _year = int.parse(v!.replaceAll('年', ''))),
                        underline: const SizedBox(),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A)),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            size: 18, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: '${_month}月',
                        items: monthNames
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _month = int.parse(v!.replaceAll('月', ''))),
                        underline: const SizedBox(),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A)),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            size: 18, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _navButton(Icons.chevron_left, () => _changeMonth(-1)),
                    const SizedBox(width: 12),
                    _navButton(Icons.chevron_right, () => _changeMonth(1)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const [
                Expanded(
                    child: Center(
                        child: Text('日',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w600)))),
                Expanded(
                    child: Center(
                        child: Text('一',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500)))),
                Expanded(
                    child: Center(
                        child: Text('二',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500)))),
                Expanded(
                    child: Center(
                        child: Text('三',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500)))),
                Expanded(
                    child: Center(
                        child: Text('四',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500)))),
                Expanded(
                    child: Center(
                        child: Text('五',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500)))),
                Expanded(
                    child: Center(
                        child: Text('六',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cells = _buildCalendarCells();
                final rowCount = (cells.length / 7).ceil();
                final cellWidth = (constraints.maxWidth - 32 - 12) / 7;
                final cellHeight = constraints.maxHeight / rowCount;
                final aspectRatio = cellWidth / cellHeight;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GridView.count(
                    crossAxisCount: 7,
                    childAspectRatio: aspectRatio,
                    padding: const EdgeInsets.all(8),
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    children: cells,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(icon, size: 20, color: const Color(0xFF475569)),
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
  List<ProjectType> _projectTypes = [];
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _loadProjectTypesAndClients();
  }

  Future<void> _loadSuggestions() async {
    final names = await DatabaseHelper.instance.getAllProjectNames();
    setState(() => _projectNameSuggestions = names);
  }

  Future<void> _loadProjectTypesAndClients() async {
    final types = await DatabaseHelper.instance.getAllProjectTypes();
    final clients = await DatabaseHelper.instance.getAllClients();
    setState(() {
      _projectTypes = types;
      _clients = clients;
    });
  }

  void _checkExisting(String name) async {
    if (name.isEmpty) {
      setState(() {
        _isExisting = false;
        _existingProject = null;
      });
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
        clientName: _clientController.text.trim().isNotEmpty
            ? _clientController.text.trim()
            : null,
        projectType: _typeController.text.trim().isNotEmpty
            ? _typeController.text.trim()
            : null,
        totalAmount: double.tryParse(_totalController.text) ?? 0.0,
        receivedAmount: double.tryParse(_receivedController.text) ?? 0.0,
        isSettled: _isSettled,
        remarks: _remarkController.text.trim().isNotEmpty
            ? _remarkController.text.trim()
            : null,
      );
      await DatabaseHelper.instance.createProject(proj);
    }

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('添加日程 - ${widget.dateStr}',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '项目名称 *',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                child: const Text('已关联已有项目，金额等信息保持不变',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8A6D0B))),
              ),
            const SizedBox(height: 12),
            if (!_isExisting) ...[
              // 客户快捷选择
              if (_clients.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('快捷选择客户',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _clients
                          .map((c) => GestureDetector(
                                onTap: () => setState(
                                    () => _clientController.text = c.name),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _clientController.text == c.name
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _clientController.text == c.name
                                          ? Colors.white
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              TextField(
                controller: _clientController,
                decoration: const InputDecoration(
                  labelText: '客户名称',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              // 项目类型快捷选择
              if (_projectTypes.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('快捷选择项目类型',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _projectTypes
                          .map((t) => GestureDetector(
                                onTap: () => setState(
                                    () => _typeController.text = t.name),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _typeController.text == t.name
                                        ? _parseColor(t.colorHex)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _parseColor(t.colorHex),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _typeController.text == t.name
                                              ? Colors.white
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              TextField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: '项目类型',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '项目总额',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _receivedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '已收金额',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('是否结清', style: TextStyle(fontSize: 14)),
                  Switch(
                    value: _isSettled,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (v) => setState(() => _isSettled = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remarkController,
                decoration: const InputDecoration(
                  labelText: '备注',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
