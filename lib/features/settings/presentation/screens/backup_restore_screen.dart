import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  Future<File> _getDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gastomigo.db');

    return File(path);
  }

  Future<void> backupDatabase(BuildContext context) async {
    try {
      final dbFile = await _getDatabaseFile();

      if (!await dbFile.exists()) {
        throw Exception('Database file not found.');
      }

      final directory = await getTemporaryDirectory();
      final backupPath = join(
        directory.path,
        'gastomigo_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );

      final backupFile = await dbFile.copy(backupPath);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        text: 'GastoMigo Backup',
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> restoreDatabase(BuildContext context) async {
    try {
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Restore Backup?'),
            content: const Text(
              'This will replace your current local GastoMigo database. Continue only if you trust the selected backup file.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      if (shouldRestore != true) return;

      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      await AppDatabase.instance.close();

      final pickedFile = File(result.files.single.path!);
      final dbFile = await _getDatabaseFile();

      await pickedFile.copy(dbFile.path);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restored. Please restart the app.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backup Local Data',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a backup copy of your local GastoMigo database and save it to your preferred storage.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => backupDatabase(context),
                  icon: const Icon(Icons.backup_rounded),
                  label: const Text('Backup Database'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restore Local Data',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Restore a previous GastoMigo database backup. This will replace your current local database.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => restoreDatabase(context),
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Restore Backup'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}