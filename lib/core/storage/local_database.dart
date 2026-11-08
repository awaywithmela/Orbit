import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

part 'local_database.g.dart';

@collection
class LocalRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;

  late String value;
}

class LocalDatabase {
  LocalDatabase._();

  static final instance = LocalDatabase._();
  Isar? _isar;

  Future<void> open() async {
    if (_isar != null) return;
    final directory = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [LocalRecordSchema],
      directory: directory.path,
      name: 'orbit_local',
    );
  }

  Future<String?> read(String key) async {
    await open();
    return _isar!.localRecords.where().keyEqualTo(key).findFirst().then(
      (record) => record?.value,
    );
  }

  Future<void> write(String key, String value) async {
    await open();
    await _isar!.writeTxn(() async {
      final existing = await _isar!.localRecords.where().keyEqualTo(key).findFirst();
      final record = existing ?? LocalRecord()..key = key;
      record.value = value;
      await _isar!.localRecords.put(record);
    });
  }

  Future<void> delete(String key) async {
    await open();
    await _isar!.writeTxn(() async {
      final record = await _isar!.localRecords.where().keyEqualTo(key).findFirst();
      if (record != null) await _isar!.localRecords.delete(record.id);
    });
  }
}
