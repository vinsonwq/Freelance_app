class ProjectType {
  int? id;
  String name;
  String colorHex;
  int createdAt;

  ProjectType({
    this.id,
    required this.name,
    this.colorHex = '#6366F1',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'created_at': createdAt,
    };
  }

  factory ProjectType.fromMap(Map<String, dynamic> map) {
    return ProjectType(
      id: map['id'],
      name: map['name'] ?? '',
      colorHex: map['color_hex'] ?? '#6366F1',
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}