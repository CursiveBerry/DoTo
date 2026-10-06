import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { todo, progress, done }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final TaskStatus status;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    this.status = TaskStatus.todo,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'time': time,
    'status': status.name,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory TaskModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TaskModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      time: data['time'] as String? ?? '',
      status: TaskStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TaskStatus.todo,
      ),
    );
  }

  TaskStatus get nextStatus =>
      TaskStatus.values[(status.index + 1) % TaskStatus.values.length];
}
