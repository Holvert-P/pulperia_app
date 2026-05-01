import 'package:flutter/material.dart';

import 'package:app/src/core/app/app.dart';
import 'package:app/src/core/services/notification_service.dart';
import 'package:app/src/features/products/products.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await ProductImporter().seedProductsCatalogIfNeeded();
  runApp(const App());
}
