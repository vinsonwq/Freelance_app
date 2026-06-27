import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/client.dart';

class ClientManagePage extends StatefulWidget {
  const ClientManagePage({super.key});

  @override
  State<ClientManagePage> createState() => _ClientManagePageState();
}

class _ClientManagePageState extends State<ClientManagePage> {
  List<Client> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    final clients = await DatabaseHelper.instance.getAllClients();
    setState(() {
      _clients = clients;
      _isLoading = false;
    });
  }

  Future<void> _addClient() async {
    final nameController = TextEditingController();
    final remarksController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增客户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: '请输入客户名称',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                hintText: '备注（可选）',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 2,
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('客户名称不能为空')),
                );
                return;
              }
              final existing = await DatabaseHelper.instance.getClientByName(name);
              if (existing != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('该客户已存在')),
                );
                return;
              }
              await DatabaseHelper.instance.createClient(
                Client(
                  name: name,
                  remarks: remarksController.text.trim().isNotEmpty ? remarksController.text.trim() : null,
                ),
              );
              Navigator.pop(ctx);
              _loadClients();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _editClient(Client client) async {
    final nameController = TextEditingController(text: client.name);
    final remarksController = TextEditingController(text: client.remarks ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑客户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: '请输入客户名称',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                hintText: '备注（可选）',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 2,
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('客户名称不能为空')),
                );
                return;
              }
              client.name = name;
              client.remarks = remarksController.text.trim().isNotEmpty ? remarksController.text.trim() : null;
              await DatabaseHelper.instance.updateClient(client);
              Navigator.pop(ctx);
              _loadClients();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClient(Client client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除客户 "${client.name}" 吗？'),
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
      await DatabaseHelper.instance.deleteClient(client.id!);
      _loadClients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('客户管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addClient,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: const Color(0xFFCBD5E1)),
                      const SizedBox(height: 16),
                      const Text('暂无客户', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 8),
                      Text('点击右上角 + 添加', style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final client = _clients[index];
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
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person, size: 20, color: Color(0xFF6366F1)),
                        ),
                        title: Text(
                          client.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        subtitle: client.remarks != null && client.remarks!.isNotEmpty
                            ? Text(
                                client.remarks!,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                              onPressed: () => _editClient(client),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                              onPressed: () => _deleteClient(client),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addClient,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}