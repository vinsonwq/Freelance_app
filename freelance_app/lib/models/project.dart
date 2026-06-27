import 'dart:convert';
import 'package:flutter/material.dart';

class Project {
  int? id;
  String projectName;
  List<String> scheduleDates;
  String? clientName;
  String? projectType;
  double totalAmount;
  double receivedAmount;
  double expenseAmount;
  bool isSettled;
  String? remarks;
  int createdAt;

  Project({
    this.id,
    required this.projectName,
    required this.scheduleDates,
    this.clientName,
    this.projectType,
    this.totalAmount = 0.0,
    this.receivedAmount = 0.0,
    this.expenseAmount = 0.0,
    this.isSettled = false,
    this.remarks,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_name': projectName,
      'schedule_dates': jsonEncode(scheduleDates),
      'client_name': clientName,
      'project_type': projectType,
      'total_amount': totalAmount,
      'received_amount': receivedAmount,
      'expense_amount': expenseAmount,
      'is_settled': isSettled ? 1 : 0,
      'remarks': remarks,
      'created_at': createdAt,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    List<String> dates = [];
    if (map['schedule_dates'] != null && map['schedule_dates'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['schedule_dates']);
        if (decoded is List) {
          dates = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        dates = [];
      }
    }

    return Project(
      id: map['id'],
      projectName: map['project_name'] ?? '',
      scheduleDates: dates,
      clientName: map['client_name'],
      projectType: map['project_type'],
      totalAmount: (map['total_amount'] ?? 0).toDouble(),
      receivedAmount: (map['received_amount'] ?? 0).toDouble(),
      expenseAmount: (map['expense_amount'] ?? 0).toDouble(),
      isSettled: (map['is_settled'] ?? 0) == 1,
      remarks: map['remarks'],
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool hasDate(int year, int month) {
    return scheduleDates.any((d) {
      final parts = d.split('-');
      if (parts.length < 2) return false;
      return parts[0] == year.toString() && parts[1] == month.toString().padLeft(2, '0');
    });
  }

  bool hasDateInYear(int year) {
    return scheduleDates.any((d) => d.startsWith('$year-'));
  }
}
