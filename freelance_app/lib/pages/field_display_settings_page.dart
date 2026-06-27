import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FieldDisplaySettingsPage extends StatefulWidget {
  const FieldDisplaySettingsPage({super.key});

  @override
  State<FieldDisplaySettingsPage> createState() => _FieldDisplaySettingsPageState();
}

class _FieldDisplaySettingsPageState extends State<FieldDisplaySettingsPage> {
  Map<String, bool> _fieldVisible = {
    '客户名称': true,
    '项目类型': true,
    '项目总额': true,
    '已收金额': true,
    '项目支出': true,
    '项目利润': true,
    '是否结清': true,
    '备注': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final key in _fieldVisible.keys) {
        _fieldVisible[key] = prefs.getBool('field_$key') ?? (key != '备注');
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _fieldVisible.entries) {
      await prefs.setBool('field_${entry.key}', entry.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('字段显示设置'),
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
                    '列表页显示字段',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  ),
                ),
                ..._fieldVisible.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        Switch(
                          value: entry.value,
                          activeColor: const Color(0xFF6366F1),
                          activeTrackColor: const Color(0xFFE0E7FF),
                          onChanged: (v) {
                            setState(() => _fieldVisible[entry.key] = v);
                            _savePrefs();
                          },
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
                    '关闭的字段将不会在列表页显示，但数据仍会保存',
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