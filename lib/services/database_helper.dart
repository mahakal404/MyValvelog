import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/heart_valve_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('heart_valve.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE entries (
  id $idType,
  model $textType,
  serialNo $textType,
  batchNo $textType,
  jobCardNo $textType,
  size $textType,
  quantity $intType,
  status $textType,
  sign $textType,
  assembly $textType,
  section $textType,
  borrowedFromAssembly TEXT,
  takeTime $textType,
  submitTime $textType,
  timestamp $textType
  )
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns
      await db.execute("ALTER TABLE entries ADD COLUMN jobCardNo TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE entries ADD COLUMN assembly TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE entries ADD COLUMN section TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE entries ADD COLUMN takeTime TEXT");
      await db.execute("ALTER TABLE entries ADD COLUMN submitTime TEXT");

      // Copy cardNoDate to jobCardNo for existing entries
      await db.execute("UPDATE entries SET jobCardNo = cardNoDate");
      // Fallback takeTime and submitTime to timestamp for existing entries
      await db.execute("UPDATE entries SET takeTime = timestamp, submitTime = timestamp");
    }
    
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE entries ADD COLUMN borrowedFromAssembly TEXT");
    }

    if (oldVersion < 4) {
      // Migrate old model names to new nomenclature
      await db.execute("UPDATE entries SET model = 'THV4' WHERE model = 'Model 4'");
      await db.execute("UPDATE entries SET model = 'THV6' WHERE model = 'Model 6'");
    }
  }

  Future<int> insertEntry(HeartValveEntry entry) async {
    final db = await instance.database;
    return await db.insert('entries', entry.toMap());
  }

  Future<List<HeartValveEntry>> getAllEntries() async {
    final db = await instance.database;
    
    // Order by timestamp descending (newest first)
    final result = await db.query('entries', orderBy: 'timestamp DESC');
    
    return result.map((json) => HeartValveEntry.fromMap(json)).toList();
  }
  
  Future<List<HeartValveEntry>> getEntriesForMonth(int year, int month) async {
    final db = await instance.database;
    
    // Create a date string for filtering (e.g. "2023-10-")
    // Note: ISO8601 strings are used, so they look like "YYYY-MM-DDThh:mm:ss"
    String monthStr = month.toString().padLeft(2, '0');
    String queryPrefix = '$year-$monthStr-';

    final result = await db.query(
      'entries',
      where: 'timestamp LIKE ?',
      whereArgs: ['$queryPrefix%'],
      orderBy: 'timestamp DESC'
    );
    
    return result.map((json) => HeartValveEntry.fromMap(json)).toList();
  }

  Future<int> updateEntry(HeartValveEntry entry) async {
    final db = await instance.database;
    return db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await instance.database;
    return await db.delete(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
