import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _nickname = '自由职业者';
  String _version = '1.0.0';
  List<String> _calFields = ['项目名称', '项目类型'];
  final List<String> _allCalFields = [
    '项目名称', '项目类型', '客户名称', '项目总额', '是否结清'
  ];

  // 字段显示设置
  Map<String, bool> _fieldVisible = {
    '客户名称': true,
    '项目类型': true,
    '项目总额': true,
    '已收金额': true,
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
      _nickname = prefs.getString('nickname') ?? '自由职业者';
      _calFields = prefs.getStringList('cal_fields') ?? ['项目名称', '项目类型'];
      for (final key in _fieldVisible.keys) {
        _fieldVisible[key] = prefs.getBool('field_$key') ?? (key != '备注');
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', _nickname);
    await prefs.setStringList('cal_fields', _calFields);
    for (final entry in _fieldVisible.entries) {
      await prefs.setBool('field_${entry.key}', entry.value);
    }
  }

  Future<void> _exportData() async {
    try {
      final path = await DatabaseHelper.instance.exportCSV();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          _buildProfile(),
          _buildSection('字段显示设置', _buildFieldToggles()),
          _buildSection('日历格子展示（最多选2个）', _buildCalFieldChecks()),
          _buildSection('账户', [
            _settingsTile('修改昵称', _nickname, () => _showEditNickname()),
            _settingsTile('修改头像', '点击设置', () {}),
            _settingsTile('应用锁密码', '未开启', () {}),
          ]),
          _buildSection('数据', [
            ListTile(
              title: const Text('导出数据（CSV）', style: TextStyle(color: Color(0xFF1677FF))),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
              onTap: _exportData,
            ),
            ListTile(
              title: const Text('建议与反馈'),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1677FF), Color(0xFF69B1FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🎨', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_nickname, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('版本 $_version', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999), letterSpacing: 0.5),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
      ],
    );
  }

  List<Widget> _buildFieldToggles() {
    return _fieldVisible.entries.map((entry) {
      return SwitchListTile(
        title: Text(entry.key),
        value: entry.value,
        activeColor: const Color(0xFF1677FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        onChanged: (v) {
          setState(() => _fieldVisible[entry.key] = v);
          _savePrefs();
        },
      );
    }).toList();
  }

  List<Widget> _buildCalFieldChecks() {
    return _allCalFields.map((field) {
      final checked = _calFields.contains(field);
      return CheckboxListTile(
        title: Text(field),
        value: checked,
        activeColor: const Color(0xFF1677FF),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        onChanged: (v) {
          if (v == true && _calFields.length >= 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('最多只能选择 2 个字段')),
            );
            return;
          }
          setState(() {
            if (v == true) {
              _calFields.add(field);
            } else {
              _calFields.remove(field);
            }
          });
          _savePrefs();
        },
      );
    }).toList();
  }

  Widget _settingsTile(String label, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 18),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _showEditNickname() {
    final controller = TextEditingController(text: _nickname);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '请输入昵称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              setState(() => _nickname = controller.text.trim().isEmpty ? '自由职业者' : controller.text.trim());
              _savePrefs();
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
