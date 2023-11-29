// ignore_for_file: avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Sqlite {
  static const sqlFileName = 'calendar.db';
  static const dbVersion = 1;
  static const userTable = 'user';
  static const friendTable = 'friend';
  static const journeyTable = 'journey';
  static const eventTable = 'event';

  static Database? db;
  static Future<Database?> get open async => db ??= await initDatabase();

  static Future<Database?> initDatabase() async {
    print('初始化資料庫');
    String path =
        "${await getDatabasesPath()}/$sqlFileName"; // 這是 Future 的資料，前面要加 await
    print('DB PATH $path');

    try {
      db = await openDatabase(path, version: dbVersion, onCreate: _onCreate);
      print('資料庫已成功打開');
    } catch (e) {
      print('打開資料庫時出現錯誤: $e');
    }

    print('DB DB $db');
    return db;
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 會員
    await db.execute('''
        CREATE TABLE $userTable (
        userMall text
        );
      ''');
    print('建立使用者資料表');
    await db.execute('''
        CREATE TABLE $friendTable (
        fID integer primary key AUTOINCREMENT,
        userMall integer,
        account text,
        name text
        );
      ''');
    print('建立好友資料表');
    // 行程
    // userMall integer 有需要?
    await db.execute('''
        CREATE TABLE $journeyTable (
          jID integer,
          userMall text,
          journeyName text,
          journeyStartTime int,
          journeyEndTime int,
          color integer,
          location text,
          remark text,
          remindTime integer,
          remindStatus integer,
          isAllDay integer
        );
      ''');
    print('建立行程資料表');
    // 活動
    await db.execute('''
        CREATE TABLE $eventTable (
        eID integer,
        userMall text,
        eventName text,
        eventBlockStartTime int,
        eventBlockEndTime int,
        eventTime int,
        timeLengthHours int,
        timeLengthMins int,
        eventFinalStartTime int,
        eventFinalEndTime int,
        state int,
        matchTime int,
        friends text,
        location text,
        remindStatus int,
        remindTime int,
        remark text
        );
      ''');
    print('建立活動資料表');
  }

  // 新增
  static Future<List> insert(
      {required String tableName,
      required Map<String, dynamic> insertData}) async {
    final Database? database = await open;
    try {
      int? result = await database?.insert(tableName, insertData,
          conflictAlgorithm: ConflictAlgorithm.replace);
      result ??= 0;
      return [true, result];
    } catch (err) {
      print('DbException$err');
      return [false, -1];
    }
  }

  // 抓所有資料
  static Future<List<Map<String, dynamic>>?> queryAll(
      {required String tableName}) async {
    final Database? database = await open;
    var result = await database?.query(tableName, columns: null);
    result ??= [];
    print('sqlite拿全部資料');
    return result;
  }

  // 找特定形成id的資料
  static Future<List<Map<String, dynamic>>> queryByColumn({
    required String tableName,
    required String columnName,
    required dynamic columnValue,
  }) async {
    final Database? database = await open;
    return await database!.query(
      tableName,
      where: '$columnName = ?',
      whereArgs: [columnValue],
    );
  }

  // 刪除資料庫
  static Future<void> dropDatabase() async {
    var path = await getDatabasesPath();
    String dbPath = join(path, sqlFileName);
    await deleteDatabase(dbPath);
    db = null; // Reset the database object
    print('資料庫已刪除');
  }

  // 編輯
  static Future<void> update(
      {required String tableName,
      required Map<String, dynamic> updateData,
      required String tableIdName,
      required int updateID}) async {
    final Database? database = await open;
    await database?.update(tableName, updateData,
        where: '$tableIdName = ?', whereArgs: [updateID]);
    print('更新資料庫成功1');
  }

  static Future<List<Map<String, dynamic>>?> queryRow(
      {required String tableName,
      required String key,
      required String value}) async {
    final Database? database = await open;
    var sql = 'SELECT * FROM $tableName WHERE $key=?';
    return await database?.rawQuery(sql, [value]);
  }

  // 刪除
  static Future<int?> deleteJourney(
      {required String tableName,
      required String tableIdName,
      required int deleteId}) async {
    final Database? database = await open;
    return await database?.delete(tableName, where: '$tableIdName=$deleteId');
  }

  // 清空資料表
  static Future<void> clear({
    required String tableName,
  }) async {
    final Database? database = await open;
    print("以清空 $tableName 資料表");
    return await database?.execute('DELETE FROM `$tableName`;');
  }

  // 新增用戶到 userTable
  static Future<List> insertUser(String uid, String userMall) async {
    Map<String, dynamic> userData = {
      'userMall': uid,
      'userMall': userMall,
    };

    return await insert(tableName: userTable, insertData: userData);
  }

  // 查詢 usertable 中的用戶 userMall
  static Future<String?> getUserUid() async {
    final Database? database = await open;
    try {
      // 從 usertable 中取得所有資料
      final List<Map<String, dynamic>>? results =
          await database?.query(userTable);
      if (results != null && results.isNotEmpty) {
        // 由於 usertable 只存儲一個用戶的資料，所以我們直接返回第一條記錄的 uid
        return results.first['userMall'] as String;
      }
    } catch (e) {
      print('查詢 userMall 時出現錯誤: $e');
    }
    return null; // 如果沒有找到用戶資料，或者發生錯誤，返回 null
  }
}
