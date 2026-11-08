import 'package:flutter/material.dart';

import 'src/app.dart';
import 'core/notifications/smart_notification_service.dart';
import 'core/ads/ads_consent_service.dart';
import 'core/storage/local_database.dart';

export 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AdsConsentService.initialize();
  } catch (_) {
    // Consent or ad setup must never prevent the app from opening.
  }
  await LocalDatabase.instance.open();

  try {
    await SmartNotificationService.instance.initialize();
  } catch (_) {
    // Notification setup should never prevent the first frame from rendering.
  }
  runApp(const OrbitApp());
}
