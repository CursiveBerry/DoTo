import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/models/task_model.dart';
import 'package:todo_app/provider/auth_provider.dart';
import 'package:todo_app/services/task_service.dart';

final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService(ref.watch(firestoreProvider));
});

final tasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(taskServiceProvider).watchTasks(user.uid);
});
