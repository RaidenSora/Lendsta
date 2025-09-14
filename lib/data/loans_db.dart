import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/loan.dart';
import '../models/person.dart';

class LoansDatabase {
  static final LoansDatabase _instance = LoansDatabase._internal();
  factory LoansDatabase() => _instance;
  LoansDatabase._internal();

  static const _dbName = 'loans.db';
  static const _dbVersion = 4; // v4: collapse statuses to paid/unpaid
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  // ===== Person-scoped queries & summary =====

  Future<List<Loan>> getLoansForPersonBetween(
    String personName, {
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await database;

    if (start == null || end == null) {
      // All-time for that person
      final maps = await db.query(
        'loans',
        where: 'borrower = ?',
        whereArgs: [personName],
        orderBy: 'date(dueDate) ASC',
      );
      return maps.map(Loan.fromMap).toList();
    }

    final maps = await db.query(
      'loans',
      where: 'borrower = ? AND date(dueDate) BETWEEN date(?) AND date(?)',
      whereArgs: [personName, _isoDateOnly(start), _isoDateOnly(end)],
      orderBy: 'date(dueDate) ASC',
    );
    return maps.map(Loan.fromMap).toList();
  }

  Future<PersonSummary> getSummaryForPersonBetween(
    String personName, {
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await database;

    // Build SQL & args depending on all-time or ranged
    final String whereClause;
    final List<Object?> whereArgs;
    if (start == null || end == null) {
      whereClause = 'borrower = ?';
      whereArgs = [personName];
    } else {
      whereClause =
          'borrower = ? AND date(dueDate) BETWEEN date(?) AND date(?)';
      whereArgs = [personName, _isoDateOnly(start), _isoDateOnly(end)];
    }

    // total, avg interest, paid count, and unpaid amount
    final rows = await db.rawQuery('''
    SELECT
      COUNT(*) AS total_count,
      COALESCE(SUM(amount), 0) AS total_amount,
      COALESCE(AVG(interest), 0) AS avg_interest,
      SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) AS paid_count,
      COALESCE(SUM(CASE WHEN status != 'paid' THEN amount ELSE 0 END), 0) AS unpaid_amount
    FROM loans
    WHERE $whereClause
  ''', whereArgs);

    final m = rows.first;
    return PersonSummary(
      totalCount: (m['total_count'] as int?) ?? 0,
      totalAmount: (m['total_amount'] as num?)?.toDouble() ?? 0.0,
      avgInterest: (m['avg_interest'] as num?)?.toDouble() ?? 0.0,
      paidCount: (m['paid_count'] as int?) ?? 0,
      unpaidAmount: (m['unpaid_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ----- Schema -----
  Future<void> _onCreate(Database db, int version) async {
    // loans table (with item + imagePath already)
    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        borrower TEXT NOT NULL,
        item TEXT NOT NULL,
        amount REAL NOT NULL,
        interest REAL NOT NULL,
        dueDate TEXT NOT NULL,
        status TEXT NOT NULL,
        imagePath TEXT
      );
    ''');

    // people table
    await db.execute('''
      CREATE TABLE people (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      );
    ''');

    // No sample seeds on install
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 -> v2: add item, imagePath columns
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE loans ADD COLUMN item TEXT NOT NULL DEFAULT '';",
      );
      await db.execute("ALTER TABLE loans ADD COLUMN imagePath TEXT;");
    }
    // v2 -> v3: add people table
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE people (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        );
      ''');
      // No sample seeds when adding the people table
    }
    // v3 -> v4: remap legacy statuses (approved/pending) to 'unpaid'
    if (oldVersion < 4) {
      await db.execute(
        "UPDATE loans SET status = 'unpaid' WHERE status != 'paid';",
      );
    }
  }

  String? _isoDateOnly(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // ----- Loans CRUD & queries -----
  Future<List<Loan>> getAllLoans() async {
    final db = await database;
    final maps = await db.query('loans', orderBy: 'date(dueDate) ASC');
    return maps.map(Loan.fromMap).toList();
  }

  Future<List<Loan>> getLoansBetween(DateTime? start, DateTime? end) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    final s = _isoDateOnly(start);
    final e = _isoDateOnly(end);

    if (s != null) {
      where.add('date(dueDate) >= date(?)');
      args.add(s);
    }
    if (e != null) {
      where.add('date(dueDate) <= date(?)');
      args.add(e);
    }

    final maps = await db.query(
      'loans',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'dueDate DESC',
    );
    return maps.map(Loan.fromMap).toList();
  }

  Future<int> insertLoan(Loan loan) async {
    final db = await database;
    return db.insert('loans', loan.toMap());
  }

  Future<int> updateLoanStatus(int id, String status) async {
    final db = await database;
    return db.update(
      'loans',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteLoan(int id) async {
    final db = await database;
    return db.delete('loans', where: 'id = ?', whereArgs: [id]);
  }

  // ----- Summary -----
  // Helper: accept nullable and return YYYY-MM-DD or null

  Future<LoanSummary> getSummaryBetween(DateTime? start, DateTime? end) async {
    final db = await database;

    // Build WHERE dynamically depending on which bounds are provided
    final where = <String>[];
    final args = <Object?>[];

    final s = _isoDateOnly(start);
    final e = _isoDateOnly(end);

    if (s != null) {
      where.add('date(dueDate) >= date(?)');
      args.add(s);
    }
    if (e != null) {
      where.add('date(dueDate) <= date(?)');
      args.add(e);
    }

    final sql = '''
    SELECT
      COUNT(*) AS total_count,
      COALESCE(SUM(amount), 0)            AS total_amount,
      COALESCE(AVG(interest), 0)          AS avg_interest,
      SUM(CASE WHEN status = 'paid'     THEN 1 ELSE 0 END) AS paid_count,
      COALESCE(SUM(CASE WHEN status != 'paid' THEN amount ELSE 0 END), 0) AS unpaid_amount
    FROM loans
    ${where.isEmpty ? '' : 'WHERE ' + where.join(' AND ')}
  ''';

    final rows = await db.rawQuery(sql, args);
    final m = rows.first;

    int _asInt(Object? v) => switch (v) {
      int i => i,
      num n => n.toInt(),
      _ => 0,
    };
    double _asDouble(Object? v) => switch (v) {
      double d => d,
      num n => n.toDouble(),
      _ => 0.0,
    };

    return LoanSummary(
      totalCount: _asInt(m['total_count']),
      totalAmount: _asDouble(m['total_amount']),
      avgInterest: _asDouble(m['avg_interest']),
      paidCount: _asInt(m['paid_count']),
      unpaidAmount: _asDouble(m['unpaid_amount']),
    );
  }

  // ----- People CRUD -----
  Future<List<Person>> getAllPeople() async {
    final db = await database;
    final maps = await db.query('people', orderBy: 'name ASC');
    return maps.map(Person.fromMap).toList();
  }

  Future<List<Person>> searchPeople(String query) async {
    final db = await database;
    final maps = await db.query(
      'people',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map(Person.fromMap).toList();
  }

  Future<int> insertPerson(String name) async {
    final db = await database;
    return db.insert('people', {
      'name': name.trim(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore); // ignore dup names
  }

  Future<int> deletePerson(int id) async {
    final db = await database;
    return db.delete('people', where: 'id = ?', whereArgs: [id]);
  }
}

class PersonSummary {
  final int totalCount;
  final double totalAmount;
  final double avgInterest;
  final int paidCount;
  final double unpaidAmount;

  const PersonSummary({
    required this.totalCount,
    required this.totalAmount,
    required this.avgInterest,
    required this.paidCount,
    required this.unpaidAmount,
  });
}

// Summary DTO (unchanged)
class LoanSummary {
  final int totalCount;
  final double totalAmount;
  final double avgInterest;
  final int paidCount;
  final double unpaidAmount;

  const LoanSummary({
    required this.totalCount,
    required this.totalAmount,
    required this.avgInterest,
    required this.paidCount,
    required this.unpaidAmount,
  });
}
