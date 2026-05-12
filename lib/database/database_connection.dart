import 'package:drift/drift.dart';
import 'database_connection_native.dart'
    if (dart.library.html) 'database_connection_web.dart';

QueryExecutor openConnection() => createConnection();
