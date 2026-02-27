import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/hive_service.dart';

class BackupService {
  static Future<String> createLocalBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/smartfinance_backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${backupDir.path}/backup_$timestamp.json');

      final encryptedData = await HiveService.exportToJSON();
      await backupFile.writeAsString(encryptedData);

      return backupFile.path;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> restoreFromBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }

      final encryptedData = await backupFile.readAsString();
      await HiveService.importFromJSON(encryptedData);
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<String>> getLocalBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/smartfinance_backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = backupDir.listSync();
      return files
          .where((f) => f.path.endsWith('.json'))
          .map((f) => f.path)
          .toList()
        ..sort((a, b) => b.compareTo(a));
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> shareBackup(String backupPath) async {
    try {
      await Share.shareXFiles(
        [XFile(backupPath)],
        subject: 'FinTrack Backup',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> scheduleAutomaticBackup() async {
    // This would typically be scheduled using a background task service
    return await createLocalBackup();
  }
}
