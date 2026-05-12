// ignore: deprecated_member_use
import 'package:drift/web.dart';
import 'package:drift/drift.dart';

QueryExecutor createConnection() {
  return WebDatabase('lifelog_db');
}
