import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_debug.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AppDatabase.instance.database;
  //await DatabaseDebug.printDatabaseStatus();

  runApp(const GastoMigoApp());
}