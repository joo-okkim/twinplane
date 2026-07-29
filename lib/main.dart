import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const AuthGate());
}
