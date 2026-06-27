import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';
import '../models/project_type.dart';
import '../models/client.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // 内存存储（用于Web平台）
  static List<Project> _memoryProjects = [];
  static List<ProjectType> _memoryProjectTypes = [];
  static List<Client> _memoryClients = [];
  static int _memoryProjectIdCounter = 1;
  static int _memoryTypeIdCounter = 1;
  static int _memoryClientIdCounter = 1;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('freelance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw UnimplementedError('Web platform uses memory storage');
    } else {
      final documentsDir = await getApplicationDocumentsDirectory();
      final path = join(documentsDir.path, filePath);
      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE tb_project (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_name TEXT NOT NULL UNIQUE,
  schedule_dates TEXT NOT NULL,
  client_name TEXT,
  project_type TEXT,
  total_amount REAL DEFAULT 0.0,
  received_amount REAL DEFAULT 0.0,
  expense_amount REAL DEFAULT 0.0,
  is_settled INTEGER DEFAULT 0,
  remarks TEXT,
  created_at INTEGER NOT NULL
)
''');
    await db.execute('''
CREATE TABLE tb_project_type (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  color_hex TEXT NOT NULL DEFAULT '#6366F1',
  created_at INTEGER NOT NULL
)
''');
    await db.execute('''
CREATE TABLE tb_client (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  remarks TEXT,
  created_at INTEGER NOT NULL
)
''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS tb_project_type (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  color_hex TEXT NOT NULL DEFAULT '#6366F1',
  created_at INTEGER NOT NULL
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS tb_client (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  remarks TEXT,
  created_at INTEGER NOT NULL
)
''');
    }
  }

  // ==================== 项目操作 ====================

  Future<int> createProject(Project project) async {
    if (kIsWeb) {
      final p = Project(
        id: _memoryProjectIdCounter++,
        projectName: project.projectName,
        scheduleDates: project.scheduleDates,
        clientName: project.clientName,
        projectType: project.projectType,
        totalAmount: project.totalAmount,
        receivedAmount: project.receivedAmount,
        expenseAmount: project.expenseAmount,
        isSettled: project.isSettled,
        remarks: project.remarks,
        createdAt: project.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      );
      _memoryProjects.add(p);

      // 自动保存项目类型和客户
      if (project.projectType != null && project.projectType!.isNotEmpty) {
        await _autoSaveProjectType(project.projectType!);
      }
      if (project.clientName != null && project.clientName!.isNotEmpty) {
        await _autoSaveClient(project.clientName!);
      }

      return p.id!;
    }
    final db = await instance.database;
    final id = await db.insert('tb_project', project.toMap());

    // 自动保存项目类型和客户
    if (project.projectType != null && project.projectType!.isNotEmpty) {
      await _autoSaveProjectType(project.projectType!);
    }
    if (project.clientName != null && project.clientName!.isNotEmpty) {
      await _autoSaveClient(project.clientName!);
    }

    return id;
  }

  Future<Project?> getProjectByName(String name) async {
    if (kIsWeb) {
      try {
        return _memoryProjects.firstWhere((p) => p.projectName == name);
      } catch (_) {
        return null;
      }
    }
    final db = await instance.database;
    final result = await db.query(
      'tb_project',
      where: 'project_name = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      return Project.fromMap(result.first);
    }
    return null;
  }

  Future<int> appendDates(String projectName, List<String> newDates) async {
    if (kIsWeb) {
      final idx =
          _memoryProjects.indexWhere((p) => p.projectName == projectName);
      if (idx == -1) return 0;
      final p = _memoryProjects[idx];
      final allDates = [...p.scheduleDates];
      for (final d in newDates) {
        if (!allDates.contains(d)) allDates.add(d);
      }
      allDates.sort();
      p.scheduleDates = allDates;
      _memoryProjects[idx] = p;
      return 1;
    }
    final db = await instance.database;
    final existing = await getProjectByName(projectName);
    if (existing == null) return 0;

    final allDates = [...existing.scheduleDates];
    for (final d in newDates) {
      if (!allDates.contains(d)) allDates.add(d);
    }
    allDates.sort();

    return await db.update(
      'tb_project',
      {'schedule_dates': jsonEncode(allDates)},
      where: 'project_name = ?',
      whereArgs: [projectName],
    );
  }

  Future<List<Project>> getAllProjects() async {
    if (kIsWeb) {
      return List.from(_memoryProjects);
    }
    final db = await instance.database;
    final result = await db.query('tb_project', orderBy: 'created_at DESC');
    return result.map((map) => Project.fromMap(map)).toList();
  }

  Future<List<Project>> getProjectsByYear(int year) async {
    final all = await getAllProjects();
    return all.where((p) => p.hasDateInYear(year)).toList();
  }

  Future<List<Project>> getProjectsByMonth(int year, int month) async {
    final all = await getAllProjects();
    return all.where((p) => p.hasDate(year, month)).toList();
  }

  Future<List<Project>> getProjectsByQuarter(int year, int quarter) async {
    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = startMonth + 2;
    final all = await getAllProjects();
    return all.where((p) {
      for (int m = startMonth; m <= endMonth; m++) {
        if (p.hasDate(year, m)) return true;
      }
      return false;
    }).toList();
  }

  Future<List<Project>> getProjectsByDate(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final all = await getAllProjects();
    return all.where((p) => p.scheduleDates.contains(dateStr)).toList();
  }

  Future<int> deleteProject(int id) async {
    if (kIsWeb) {
      final idx = _memoryProjects.indexWhere((p) => p.id == id);
      if (idx == -1) return 0;
      _memoryProjects.removeAt(idx);
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'tb_project',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateProject(Project project) async {
    if (kIsWeb) {
      final idx = _memoryProjects.indexWhere((p) => p.id == project.id);
      if (idx == -1) return 0;
      _memoryProjects[idx] = project;

      // 自动保存项目类型和客户
      if (project.projectType != null && project.projectType!.isNotEmpty) {
        await _autoSaveProjectType(project.projectType!);
      }
      if (project.clientName != null && project.clientName!.isNotEmpty) {
        await _autoSaveClient(project.clientName!);
      }

      return 1;
    }
    final db = await instance.database;
    final result = await db.update(
      'tb_project',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );

    // 自动保存项目类型和客户
    if (project.projectType != null && project.projectType!.isNotEmpty) {
      await _autoSaveProjectType(project.projectType!);
    }
    if (project.clientName != null && project.clientName!.isNotEmpty) {
      await _autoSaveClient(project.clientName!);
    }

    return result;
  }

  Future<List<String>> getAllProjectNames() async {
    final all = await getAllProjects();
    return all.map((p) => p.projectName).toList();
  }

  // ==================== 项目类型操作 ====================

  Future<void> _autoSaveProjectType(String name) async {
    final existing = await getProjectTypeByName(name);
    if (existing == null) {
      await createProjectType(ProjectType(name: name));
    }
  }

  Future<int> createProjectType(ProjectType type) async {
    if (kIsWeb) {
      final t = ProjectType(
        id: _memoryTypeIdCounter++,
        name: type.name,
        colorHex: type.colorHex,
        createdAt: type.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      );
      _memoryProjectTypes.add(t);
      return t.id!;
    }
    final db = await instance.database;
    return await db.insert('tb_project_type', type.toMap());
  }

  Future<ProjectType?> getProjectTypeByName(String name) async {
    if (kIsWeb) {
      try {
        return _memoryProjectTypes.firstWhere((t) => t.name == name);
      } catch (_) {
        return null;
      }
    }
    final db = await instance.database;
    final result = await db.query(
      'tb_project_type',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      return ProjectType.fromMap(result.first);
    }
    return null;
  }

  Future<List<ProjectType>> getAllProjectTypes() async {
    if (kIsWeb) {
      return List.from(_memoryProjectTypes);
    }
    final db = await instance.database;
    final result =
        await db.query('tb_project_type', orderBy: 'created_at DESC');
    return result.map((map) => ProjectType.fromMap(map)).toList();
  }

  Future<List<String>> getAllProjectTypeNames() async {
    final types = await getAllProjectTypes();
    return types.map((t) => t.name).toList();
  }

  Future<int> updateProjectType(ProjectType type) async {
    if (kIsWeb) {
      final idx = _memoryProjectTypes.indexWhere((t) => t.id == type.id);
      if (idx == -1) return 0;
      _memoryProjectTypes[idx] = type;
      return 1;
    }
    final db = await instance.database;
    return await db.update(
      'tb_project_type',
      type.toMap(),
      where: 'id = ?',
      whereArgs: [type.id],
    );
  }

  Future<int> deleteProjectType(int id) async {
    if (kIsWeb) {
      final idx = _memoryProjectTypes.indexWhere((t) => t.id == id);
      if (idx == -1) return 0;
      _memoryProjectTypes.removeAt(idx);
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'tb_project_type',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 客户操作 ====================

  Future<void> _autoSaveClient(String name) async {
    final existing = await getClientByName(name);
    if (existing == null) {
      await createClient(Client(name: name));
    }
  }

  Future<int> createClient(Client client) async {
    if (kIsWeb) {
      final c = Client(
        id: _memoryClientIdCounter++,
        name: client.name,
        remarks: client.remarks,
        createdAt: client.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      );
      _memoryClients.add(c);
      return c.id!;
    }
    final db = await instance.database;
    return await db.insert('tb_client', client.toMap());
  }

  Future<Client?> getClientByName(String name) async {
    if (kIsWeb) {
      try {
        return _memoryClients.firstWhere((c) => c.name == name);
      } catch (_) {
        return null;
      }
    }
    final db = await instance.database;
    final result = await db.query(
      'tb_client',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      return Client.fromMap(result.first);
    }
    return null;
  }

  Future<List<Client>> getAllClients() async {
    if (kIsWeb) {
      return List.from(_memoryClients);
    }
    final db = await instance.database;
    final result = await db.query('tb_client', orderBy: 'created_at DESC');
    return result.map((map) => Client.fromMap(map)).toList();
  }

  Future<List<String>> getAllClientNames() async {
    final clients = await getAllClients();
    return clients.map((c) => c.name).toList();
  }

  Future<int> updateClient(Client client) async {
    if (kIsWeb) {
      final idx = _memoryClients.indexWhere((c) => c.id == client.id);
      if (idx == -1) return 0;
      _memoryClients[idx] = client;
      return 1;
    }
    final db = await instance.database;
    return await db.update(
      'tb_client',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    if (kIsWeb) {
      final idx = _memoryClients.indexWhere((c) => c.id == id);
      if (idx == -1) return 0;
      _memoryClients.removeAt(idx);
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'tb_client',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 统计 ====================

  Future<double> getYearTotal(int year) async {
    final projects = await getProjectsByYear(year);
    return projects.fold<double>(0.0, (sum, p) => sum + p.totalAmount);
  }

  Future<double> getYearReceived(int year) async {
    final projects = await getProjectsByYear(year);
    return projects.fold<double>(0.0, (sum, p) => sum + p.receivedAmount);
  }

  Future<int> getYearProjectCount(int year) async {
    final projects = await getProjectsByYear(year);
    return projects.length;
  }

  // ==================== 导出 ====================

  Future<String> exportCSV() async {
    final projects = await getAllProjects();
    final buffer = StringBuffer();
    buffer.write('项目名称,客户名称,项目类型,项目总额,已收金额,项目支出,是否结清,备注,日期列表\n');
    for (final p in projects) {
      buffer.write(
          '"${p.projectName}","${p.clientName ?? ''}","${p.projectType ?? ''}",'
          '${p.totalAmount},${p.receivedAmount},${p.expenseAmount},'
          '"${p.isSettled ? "已结清" : "未结清"}","${p.remarks ?? ''}",'
          '"${p.scheduleDates.join(';')}"\n');
    }
    final documentsDir = await getApplicationDocumentsDirectory();
    final file = File(
        '${documentsDir.path}/freelance_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
