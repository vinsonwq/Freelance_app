import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/project_type.dart';

class ProjectTypeManagePage extends StatefulWidget {
  const ProjectTypeManagePage({super.key});

  @override
  State<ProjectTypeManagePage> createState() => _ProjectTypeManagePageState();
}

class _ProjectTypeManagePageState extends State<ProjectTypeManagePage> {
  List<ProjectType> _types = [];
  bool _isLoading = true;

  final List<Color> _presetColors = [
    const Color(0xFF6366F1), // 靛蓝
    const Color(0xFF8B5CF6), // 紫色
    const Color(0xFFEC4899), // 粉色
    const Color(0xFFEF4444), // 红色
    const Color(0xFFF97316), // 橙色
    const Color(0xFFFBBF24), // 黄色
    const Color(0xFF22C55E), // 绿色
    const Color(0xFF14B8A6), // 青色
    const Color(0xFF06B6D4), // 蓝绿
    const Color(0xFF3B82F6), // 蓝色
    const Color(0xFF78716C), // 灰色
    const Color(0xFF1E293B), // 深灰
  ];

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() => _isLoading = true);
    final types = await DatabaseHelper.instance.getAllProjectTypes();
    setState(() {
      _types = types;
      _isLoading = false;
    });
  }

  Future<void> _addType() async {
    final controller = TextEditingController();
    Color selectedColor = const Color(0xFF6366F1);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新增项目类型'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '请输入项目类型名称',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('选择颜色', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors.map((color) {
                  final isSelected = selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected 
                            ? Border.all(color: const Color(0xFF0F172A), width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: isSelected 
                          ? const Icon(Icons.check, size: 20, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('项目类型名称不能为空')),
                  );
                  return;
                }
                final existing = await DatabaseHelper.instance.getProjectTypeByName(name);
                if (existing != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('该项目类型已存在')),
                  );
                  return;
                }
                await DatabaseHelper.instance.createProjectType(
                  ProjectType(name: name, colorHex: '#${selectedColor.value.toRadixString(16).toUpperCase().substring(2)}'),
                );
                Navigator.pop(ctx);
                _loadTypes();
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editType(ProjectType type) async {
    final controller = TextEditingController(text: type.name);
    Color selectedColor = _parseColor(type.colorHex);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑项目类型'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '请输入项目类型名称',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('选择颜色', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors.map((color) {
                  final isSelected = selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected 
                            ? Border.all(color: const Color(0xFF0F172A), width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: isSelected 
                          ? const Icon(Icons.check, size: 20, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('项目类型名称不能为空')),
                  );
                  return;
                }
                type.name = name;
                type.colorHex = '#${selectedColor.value.toRadixString(16).toUpperCase().substring(2)}';
                await DatabaseHelper.instance.updateProjectType(type);
                Navigator.pop(ctx);
                _loadTypes();
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteType(ProjectType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除项目类型 "${type.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteProjectType(type.id!);
      _loadTypes();
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('项目类型管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addType,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _types.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: const Color(0xFFCBD5E1)),
                      const SizedBox(height: 16),
                      const Text('暂无项目类型', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 8),
                      Text('点击右上角 + 添加', style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _types.length,
                  itemBuilder: (context, index) {
                    final type = _types[index];
                    final color = _parseColor(type.colorHex);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        title: Text(
                          type.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                              onPressed: () => _editType(type),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                              onPressed: () => _deleteType(type),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addType,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}