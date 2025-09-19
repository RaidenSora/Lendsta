import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/loan.dart';
import '../models/person.dart';
import '../models/payment.dart';

class LoansDatabase {
  static final LoansDatabase _instance = LoansDatabase._internal();
  factory LoansDatabase() => _instance;
  LoansDatabase._internal();

  static const _dbName = 'loans.db';
  static const _dbVersion = 5; // v5: add payments table + remaining in summaries
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
      whereClause = 'l.borrower = ?';
      whereArgs = [personName];
    } else {
      whereClause =
          'l.borrower = ? AND date(l.dueDate) BETWEEN date(?) AND date(?)';
      whereArgs = [personName, _isoDateOnly(start), _isoDateOnly(end)];
    }

    final rows = await db.rawQuery('''
    WITH paid AS (
      SELECT loanId, COALESCE(SUM(amount),0) AS paid_total FROM payments GROUP BY loanId
    )
    SELECT
      COUNT(*) AS total_count,
      COALESCE(SUM(l.amount), 0) AS total_amount,
      COALESCE(AVG(l.interest), 0) AS avg_interest,
      SUM(CASE WHEN l.status = 'paid' THEN 1 ELSE 0 END) AS paid_count,
      COALESCE(SUM(CASE WHEN l.status != 'paid' THEN (l.amount - COALESCE(p.paid_total,0)) ELSE 0 END), 0) AS unpaid_amount
    FROM loans l
    LEFT JOIN paid p ON p.loanId = l.id
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

    // payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loanId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT
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
    // v4 -> v5: add payments table
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          loanId INTEGER NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          note TEXT
        );
      ''');
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
    // Manually cascade payments for this loan
    await db.delete('payments', where: 'loanId = ?', whereArgs: [id]);
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
    WITH paid AS (
      SELECT loanId, COALESCE(SUM(amount),0) AS paid_total FROM payments GROUP BY loanId
    )
    SELECT
      COUNT(*) AS total_count,
      COALESCE(SUM(l.amount), 0)            AS total_amount,
      COALESCE(AVG(l.interest), 0)          AS avg_interest,
      SUM(CASE WHEN l.status = 'paid'     THEN 1 ELSE 0 END) AS paid_count,
      COALESCE(SUM(CASE WHEN l.status != 'paid' THEN (l.amount - COALESCE(p.paid_total,0)) ELSE 0 END), 0) AS unpaid_amount
    FROM loans l
    LEFT JOIN paid p ON p.loanId = l.id
    ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
  ''';

    final rows = await db.rawQuery(sql, args);
    final m = rows.first;

    int asInt(Object? v) => switch (v) {
      int i => i,
      num n => n.toInt(),
      _ => 0,
    };
    double asDouble(Object? v) => switch (v) {
      double d => d,
      num n => n.toDouble(),
      _ => 0.0,
    };

    return LoanSummary(
      totalCount: asInt(m['total_count']),
      totalAmount: asDouble(m['total_amount']),
      avgInterest: asDouble(m['avg_interest']),
      paidCount: asInt(m['paid_count']),
      unpaidAmount: asDouble(m['unpaid_amount']),
    );
  }

  // ----- Payments -----
  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    final id = await db.insert('payments', payment.toMap());
    // Auto-update status if fully paid
    try {
      final paid = await getPaidTotalForLoan(payment.loanId);
      final loanRows = await db.query(
        'loans',
        where: 'id = ?',
        whereArgs: [payment.loanId],
        limit: 1,
      );
      if (loanRows.isNotEmpty) {
        final amount = (loanRows.first['amount'] as num).toDouble();
        if (paid >= amount) {
          await db.update(
            'loans',
            {'status': 'paid'},
            where: 'id = ?',
            whereArgs: [payment.loanId],
          );
        }
      }
    } catch (_) {}
    return id;
  }

  Future<List<Payment>> getPaymentsForLoan(int loanId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'loanId = ?',
      whereArgs: [loanId],
      orderBy: 'date(date) ASC',
    );
    return maps.map(Payment.fromMap).toList();
  }

  Future<double> getPaidTotalForLoan(int loanId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) AS total FROM payments WHERE loanId = ?',
      [loanId],
    );
    final m = rows.first;
    return ((m['total'] as num?)?.toDouble()) ?? 0.0;
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
