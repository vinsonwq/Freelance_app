class Client {
  int? id;
  String name;
  String? remarks;
  int createdAt;

  Client({
    this.id,
    required this.name,
    this.remarks,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'remarks': remarks,
      'created_at': createdAt,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'] ?? '',
      remarks: map['remarks'],
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}