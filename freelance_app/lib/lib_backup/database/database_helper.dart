import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('freelance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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
  is_settled INTEGER DEFAULT 0,
  remarks TEXT,
  created_at INTEGER NOT NULL
)
''');

  // 创建新项目
  Future<int> createProject(Project project) async {
    final db = await instance.database;
    return await db.insert('tb_project', project.toMap());
  }

  // 检查项目名称是否存在
  Future<Project?> getProjectByName(String name) async {
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

  // 向已有项目追加日期
  Future<int> appendDates(String projectName, List<String> newDates) async {
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

  // 获取所有项目
  Future<List<Project>> getAllProjects() async {
    final db = await instance.database;
    final result = await db.query('tb_project', orderBy: 'created_at DESC');
    return result.map((map) => Project.fromMap(map)).toList();
  }

  // 按年份获取项目
  Future<List<Project>> getProjectsByYear(int year) async {
    final all = await getAllProjects();
    return all.where((p) => p.hasDateInYear(year)).toList();
  }

  // 按年月获取项目
  Future<List<Project>> getProjectsByMonth(int year, int month) async {
    final all = await getAllProjects();
    return all.where((p) => p.hasDate(year, month)).toList();
  }

  // 按季度获取项目
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

  // 获取某天有哪些项目
  Future<List<Project>> getProjectsByDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final all = await getAllProjects();
    return all.where((p) => p.scheduleDates.contains(dateStr)).toList();
  }

  // 删除项目
  Future<int> deleteProject(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tb_project',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取所有项目名称（用于自动补全）
  Future<List<String>> getAllProjectNames() async {
    final all = await getAllProjects();
    return all.map((p) => p.projectName).toList();
  }

  // 获取所有客户名称
  Future<List<String>> getAllClientNames() async {
    final all = await getAllProjects();
    final names = all.map((p) => p.clientName).where((n) => n != null && n.isNotEmpty).cast<String>().toSet().toList();
    return names;
  }

  // 获取所有项目类型
  Future<List<String>> getAllProjectTypes() async {
    final all = await getAllProjects();
    final types = all.map((p) => p.projectType).where((t) => t != null && t.isNotEmpty).cast<String>().toSet().toList();
    return types;
  }

  // 统计：年度总收入
  Future<double> getYearTotal(int year) async {
    final projects = await getProjectsByYear(year);
    return projects.fold(0.0, (sum, p) => sum + p.totalAmount);
  }

  // 统计：年度已收款
  Future<double> getYearReceived(int year) async {
    final projects = await getProjectsByYear(year);
    return projects.fold(0.0, (sum, p) => sum + p.receivedAmount);
  }

  // 统计：年度项目数
  Future<int> getYearProjectCount(int year) async {
    final projects = await getProjectsByYear(year);
    return projects.length;
  }

  // 导出 CSV
  Future<String> exportCSV() async {
    final projects = await getAllProjects();
    final buffer = StringBuffer();
    buffer.write('项目名称,客户名称,项目类型,项目总额,已收金额,是否结清,备注,日期列表\n');
    for (final p in projects) {
      buffer.write(
        '"${p.projectName}","${p.clientName ?? ''}","${p.projectType ?? ''}",'
        '${p.totalAmount},${p.receivedAmount},'
        '"${p.isSettled ? "已结清" : "未结清"}","${p.remarks ?? ''}",'
        '"${p.scheduleDates.join(';')}"\n'
      );
    }
    final documentsDir = await getApplicationDocumentsDirectory();
    final file = File('${documentsDir.path}/freelance_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
