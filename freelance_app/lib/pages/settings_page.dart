import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'project_type_manage_page.dart';
import 'client_manage_page.dart';
import 'field_display_settings_page.dart';
import 'calendar_display_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _nickname = '自由职业者';
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nickname = prefs.getString('nickname') ?? '自由职业者';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', _nickname);
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('我的'),
        leading: const SizedBox(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfile(),
          const SizedBox(height: 16),
          _buildSection(
            '数据管理',
            Icons.data_usage,
            [
              _settingsTile(Icons.category, '项目类型管理', '', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectTypeManagePage()));
              }),
              _settingsTile(Icons.people, '客户管理', '', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientManagePage()));
              }),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            '显示设置',
            Icons.visibility,
            [
              _settingsTile(Icons.list, '字段显示设置', '列表页显示哪些字段', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldDisplaySettingsPage()));
              }),
              _settingsTile(Icons.calendar_today, '日历格子展示', '最多选2个字段', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarDisplaySettingsPage()));
              }),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            '账户设置',
            Icons.account_circle,
            [
              _settingsTile(Icons.person, '修改昵称', _nickname, () => _showEditNickname()),
              _settingsTile(Icons.lock, '应用锁密码', '未开启', () {}),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            '其他',
            Icons.more_horiz,
            [
              _settingsTile(Icons.file_download, '导出数据（CSV）', '', _exportData, isPrimary: true),
              _settingsTile(Icons.feedback, '建议与反馈', '', () {}),
              _settingsTile(Icons.info_outline, '版本', _version, () {}),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 32, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nickname,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '版本 $_version',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.8)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          Column(children: children),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String label, String value, VoidCallback onTap, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isPrimary ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
                ),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
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
          decoration: const InputDecoration(
            hintText: '请输入昵称',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _nickname = controller.text.trim().isEmpty ? '自由职业者' : controller.text.trim());
              _savePrefs();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}