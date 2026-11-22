class Borrower {
  final int? id;
  final String fullName;
  final String email;
  final String department;

  Borrower({
    this.id,
    required this.fullName,
    required this.email,
    required this.department,
  });

  // Convert borrower information into a database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'department': department,
    };
  }

  // Convert a database record into a Borrower object.
  factory Borrower.fromMap(Map<String, dynamic> map) {
    return Borrower(
      id: map['id'] as int?,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      department: map['department'] as String,
    );
  }
}
