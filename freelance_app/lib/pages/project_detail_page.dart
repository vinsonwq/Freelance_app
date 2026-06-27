import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/project.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _clientController;
  late final TextEditingController _typeController;
  late final TextEditingController _totalController;
  late final TextEditingController _receivedController;
  late final TextEditingController _expenseController;
  late final TextEditingController _remarkController;
  late bool _isSettled;
  late List<String> _scheduleDates;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.projectName);
    _clientController =
        TextEditingController(text: widget.project.clientName ?? '');
    _typeController =
        TextEditingController(text: widget.project.projectType ?? '');
    _totalController =
        TextEditingController(text: widget.project.totalAmount.toString());
    _receivedController =
        TextEditingController(text: widget.project.receivedAmount.toString());
    _expenseController =
        TextEditingController(text: widget.project.expenseAmount.toString());
    _remarkController =
        TextEditingController(text: widget.project.remarks ?? '');
    _isSettled = widget.project.isSettled;
    _scheduleDates = List.from(widget.project.scheduleDates);

    _totalController.addListener(_onAmountChange);
    _receivedController.addListener(_onAmountChange);
    _expenseController.addListener(_onAmountChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _typeController.dispose();
    _totalController.dispose();
    _receivedController.dispose();
    _expenseController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _onAmountChange() {
    setState(() {
      final total = double.tryParse(_totalController.text) ?? 0.0;
      final received = double.tryParse(_receivedController.text) ?? 0.0;
      if (total > 0 && (total - received).abs() < 0.01) {
        _isSettled = true;
      }
    });
  }

  double get _profit {
    final total = double.tryParse(_totalController.text) ?? 0.0;
    final expense = double.tryParse(_expenseController.text) ?? 0.0;
    return total - expense;
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('项目名称不能为空')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProject = widget.project;
      updatedProject.projectName = _nameController.text.trim();
      updatedProject.clientName = _clientController.text.trim().isNotEmpty
          ? _clientController.text.trim()
          : null;
      updatedProject.projectType = _typeController.text.trim().isNotEmpty
          ? _typeController.text.trim()
          : null;
      updatedProject.totalAmount =
          double.tryParse(_totalController.text) ?? 0.0;
      updatedProject.receivedAmount =
          double.tryParse(_receivedController.text) ?? 0.0;
      updatedProject.expenseAmount =
          double.tryParse(_expenseController.text) ?? 0.0;
      updatedProject.isSettled = _isSettled;
      updatedProject.remarks = _remarkController.text.trim().isNotEmpty
          ? _remarkController.text.trim()
          : null;
      updatedProject.scheduleDates = _scheduleDates;

      await DatabaseHelper.instance.updateProject(updatedProject);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除项目 "${widget.project.projectName}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await DatabaseHelper.instance.deleteProject(widget.project.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _addDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2021),
      lastDate: DateTime(2099),
    );
    if (picked != null) {
      final dateStr =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      if (!_scheduleDates.contains(dateStr)) {
        setState(() {
          _scheduleDates.add(dateStr);
          _scheduleDates.sort();
        });
      }
    }
  }

  void _removeDate(String date) {
    setState(() {
      _scheduleDates.remove(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('项目详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE84A3F)),
            onPressed: _isLoading ? null : _delete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('基本信息', [
                    _buildTextField('项目名称 *', _nameController),
                    _buildTextField('客户名称', _clientController),
                    _buildTextField('项目类型', _typeController),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('金额信息', [
                    _buildTextField('项目总额', _totalController,
                        keyboardType: TextInputType.number),
                    _buildTextField('已收金额', _receivedController,
                        keyboardType: TextInputType.number),
                    _buildTextField('项目支出', _expenseController,
                        keyboardType: TextInputType.number),
                    _buildProfitRow(),
                    _buildSettledToggle(),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('日程安排', [
                    _buildDatesSection(),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('备注', [
                    _buildTextField('备注', _remarkController, maxLines: 3),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1677FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('保存修改',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProfitRow() {
    final total = double.tryParse(_totalController.text) ?? 0.0;
    final expense = double.tryParse(_expenseController.text) ?? 0.0;
    final profit = total - expense;
    final profitColor =
        profit >= 0 ? const Color(0xFF17A96E) : const Color(0xFFE84A3F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('项目利润',
              style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A))),
          Text(
            '${profit >= 0 ? '+' : ''}${profit.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: profitColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSettledToggle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('是否结清',
              style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A))),
          Switch(
            value: _isSettled,
            onChanged: (v) => setState(() => _isSettled = v),
            activeColor: const Color(0xFF17A96E),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._scheduleDates.map((date) => Chip(
                  label: Text(date, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeDate(date),
                  backgroundColor: const Color(0xFFF0F5FF),
                  labelStyle: const TextStyle(color: Color(0xFF1677FF)),
                )),
            ActionChip(
              label: const Text('+ 添加日期', style: TextStyle(fontSize: 12)),
              onPressed: _addDate,
              backgroundColor: const Color(0xFFFFF8F0),
              labelStyle: const TextStyle(color: Color(0xFFE87C17)),
            ),
          ],
        ),
      ],
    );
  }
}
