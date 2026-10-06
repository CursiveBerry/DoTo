import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_app/models/task_model.dart';

class TaskService {
  TaskService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      _firestore.collection('users').doc(uid).collection('tasks');

  Stream<List<TaskModel>> watchTasks(String uid) {
    return _tasks(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TaskModel.fromDoc).toList());
  }

  Future<void> addTask(String uid, TaskModel task) =>
      _tasks(uid).add(task.toMap());

  Future<void> updateStatus(String uid, String taskId, TaskStatus status) =>
      _tasks(uid).doc(taskId).update({'status': status.name});

  Future<void> deleteTask(String uid, String taskId) =>
      _tasks(uid).doc(taskId).delete();
}
