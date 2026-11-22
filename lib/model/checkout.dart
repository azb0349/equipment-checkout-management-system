class Checkout {
  final int? id;
  final int equipmentId;
  final int borrowerId;
  final String checkoutDate;
  final String dueDate;
  final String? returnDate;

  Checkout({
    this.id,
    required this.equipmentId,
    required this.borrowerId,
    required this.checkoutDate,
    required this.dueDate,
    this.returnDate,
  });

  // Convert checkout information into a database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'borrowerId': borrowerId,
      'checkoutDate': checkoutDate,
      'dueDate': dueDate,
      'returnDate': returnDate,
    };
  }

  // Convert a database record into a Checkout object.
  factory Checkout.fromMap(Map<String, dynamic> map) {
    return Checkout(
      id: map['id'] as int?,
      equipmentId: map['equipmentId'] as int,
      borrowerId: map['borrowerId'] as int,
      checkoutDate: map['checkoutDate'] as String,
      dueDate: map['dueDate'] as String,
      returnDate: map['returnDate'] as String?,
    );
  }
}
