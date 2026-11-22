import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../model/borrower.dart';
import '../model/equipment.dart';
import '../model/checkout.dart';

class DatabaseHelper {
  // Create a single database helper instance.
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // Get the database.
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('equipment_checkout.db');

    return _database!;
  }

  // Open or create the database.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  // Create our three database tables.
  Future<void> _createDB(Database db, int version) async {
    // Equipment table
    await db.execute('''
      CREATE TABLE equipment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        condition TEXT NOT NULL
      )
    ''');

    // Borrowers table
    await db.execute('''
      CREATE TABLE borrowers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT NOT NULL,
        department TEXT NOT NULL
      )
    ''');

    // Checkouts table
    await db.execute('''
      CREATE TABLE checkouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipmentId INTEGER NOT NULL,
        borrowerId INTEGER NOT NULL,
        checkoutDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        returnDate TEXT,
        FOREIGN KEY (equipmentId) REFERENCES equipment(id),
        FOREIGN KEY (borrowerId) REFERENCES borrowers(id)
      )
    ''');
  }

  Future<int> insertEquipment(Equipment equipment) async {
    final db = await database;
    return await db.insert('equipment', equipment.toMap()..remove('id'));
  }

  Future<List<Equipment>> getEquipment() async {
    final db = await database;
    final result = await db.query('equipment');
    return result.map((map) => Equipment.fromMap(map)).toList();
  }

  Future<int> updateEquipment(Equipment equipment) async {
    final db = await database;
    return await db.update(
      'equipment',
      equipment.toMap(),
      where: 'id = ?',
      whereArgs: [equipment.id],
    );
  }

  Future<int> deleteEquipment(int id) async {
    final db = await database;
    final checkoutHistory = await db.query(
      'checkouts',
      where: 'equipmentId = ?',
      whereArgs: [id],
    );
    if (checkoutHistory.isNotEmpty) {
      throw Exception('Cannot delete with checkout history');
    }
    return await db.delete('equipment', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBorrower(Borrower borrower) async {
    final db = await database;
    return await db.insert('borrowers', borrower.toMap()..remove('id'));
  }

  Future<List<Borrower>> getBorrowers() async {
    final db = await database;
    final result = await db.query('borrowers');
    return result.map((map) => Borrower.fromMap(map)).toList();
  }

  Future<int> updateBorrower(Borrower borrower) async {
    final db = await database;
    return await db.update(
      'borrowers',
      borrower.toMap(),
      where: 'id = ?',
      whereArgs: [borrower.id],
    );
  }

  Future<int> deleteBorrower(int id) async {
    final db = await database;
    final checkoutHistory = await db.query(
      'checkouts',
      where: 'borrowerId = ?',
      whereArgs: [id],
    );
    if (checkoutHistory.isNotEmpty) {
      throw Exception('Cannot delete devices with checkout history');
    }
    return await db.delete('borrowers', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertCheckout(Checkout checkout) async {
    final db = await database;
    final activeCheckout = await db.query(
      'checkouts',
      where: 'equipmentId = ? AND returnDate IS NULL',
      whereArgs: [checkout.equipmentId],
    );
    if (activeCheckout.isNotEmpty) {
      throw Exception('The equipment is chekced out');
    }
    if (checkout.dueDate.compareTo(checkout.checkoutDate) <= 0) {
      throw Exception('The due date must be after checkout date');
    }
    return await db.insert('checkouts', checkout.toMap()..remove('id'));
  }

  Future<List<Checkout>> getCheckouts() async {
    final db = await database;
    final result = await db.query('checkouts');
    return result.map((map) => Checkout.fromMap(map)).toList();
  }

  Future<int> returnEquipment(int checkoutId, String returnDate) async {
    final db = await database;
    final checkout = await db.query(
      'checkouts',
      where: 'id = ?',
      whereArgs: [checkoutId],
    );
    if (checkout.isEmpty) {
      throw Exception('Checkout transaction not found');
    }
    return await db.update(
      'checkouts',
      {'ReturnDate': returnDate},
      where: 'id = ?',
      whereArgs: [checkoutId],
    );
  }

  // Get equipment that is not currently checked out.
  Future<List<Equipment>> getAvailableEquipment() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT * FROM equipment
    WHERE id NOT IN (
      SELECT equipmentId FROM checkouts
      WHERE returnDate IS NULL
    )
  ''');

    return result.map((map) => Equipment.fromMap(map)).toList();
  }

  // Get equipment that is currently checked out.
  Future<List<Equipment>> getCheckedOutEquipment() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT equipment.* FROM equipment
    INNER JOIN checkouts
    ON equipment.id = checkouts.equipmentId
    WHERE checkouts.returnDate IS NULL
  ''');

    return result.map((map) => Equipment.fromMap(map)).toList();
  }

  // Get checkout transactions that are overdue.
  Future<List<Checkout>> getOverdueCheckouts() async {
    final db = await database;

    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.query(
      'checkouts',
      where: 'returnDate IS NULL AND dueDate < ?',
      whereArgs: [today],
    );

    return result.map((map) => Checkout.fromMap(map)).toList();
  }

  // Get checkout history with equipment and borrower names.
  Future<List<Map<String, dynamic>>> getCheckoutHistory() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT
      checkouts.*,
      equipment.name AS equipmentName,
      borrowers.fullName AS borrowerName
    FROM checkouts
    INNER JOIN equipment
      ON checkouts.equipmentId = equipment.id
    INNER JOIN borrowers
      ON checkouts.borrowerId = borrowers.id
    ORDER BY checkouts.checkoutDate DESC
  ''');
  }
}
