import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in main()',
  );
});
