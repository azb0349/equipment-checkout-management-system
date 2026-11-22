class Equipment {
  final int? id;
  final String name;
  final String category;
  final String condition;

  Equipment({
    this.id,
    required this.name,
    required this.category,
    required this.condition,
  });

  // Convert equipment information into a database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'condition': condition,
    };
  }

  // Convert a database record into an Equipment object.
  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      condition: map['condition'] as String,
    );
  }
}
