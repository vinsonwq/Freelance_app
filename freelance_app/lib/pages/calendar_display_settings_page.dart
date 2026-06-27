import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarDisplaySettingsPage extends StatefulWidget {
  const CalendarDisplaySettingsPage({super.key});

  @override
  State<CalendarDisplaySettingsPage> createState() => _CalendarDisplaySettingsPageState();
}

class _CalendarDisplaySettingsPageState extends State<CalendarDisplaySettingsPage> {
  List<String> _calFields = ['项目名称', '项目类型'];
  final List<String> _allCalFields = [
    '项目名称', '项目类型', '客户名称', '项目总额', '已收金额', '项目支出', '项目利润', '是否结清'
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _calFields = prefs.getStringList('cal_fields') ?? ['项目名称', '项目类型'];
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cal_fields', _calFields);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('日历格子展示'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    '日历格子显示字段（最多2个）',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  ),
                ),
                ..._allCalFields.map((field) {
                  final checked = _calFields.contains(field);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          field,
                          style: TextStyle(
                            fontSize: 14,
                            color: checked ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                            fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (checked) {
                              setState(() => _calFields.remove(field));
                              _savePrefs();
                            } else if (_calFields.length < 2) {
                              setState(() => _calFields.add(field));
                              _savePrefs();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('最多只能选择 2 个字段')),
                              );
                            }
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: checked ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              color: checked ? const Color(0xFF6366F1) : Colors.transparent,
                            ),
                            child: checked
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Expanded(
                  child: const Text(
                    '选中的字段将显示在日历格子中，项目名称会显示项目类型的颜色',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}