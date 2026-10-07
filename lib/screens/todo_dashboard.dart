import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/models/task_model.dart';
import 'package:todo_app/provider/auth_provider.dart';
import 'package:todo_app/provider/notification_provider.dart';
import 'package:todo_app/provider/task_provider.dart';
import 'package:todo_app/widgets/app_colors.dart';
import 'package:todo_app/widgets/task_dialog.dart';

class TodoDashboard extends ConsumerStatefulWidget {
  const TodoDashboard({super.key});

  @override
  ConsumerState<TodoDashboard> createState() => _TodoDashboardState();
}

class _TodoDashboardState extends ConsumerState<TodoDashboard> {
  static const _cardColors = [
    kPrimary,
    Color(0xFFFF5A7A),
    Color(0xFF3CCF91),
    Color(0xFFFFC94A),
  ];

  String _query = '';
  TaskStatus? _filter;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  String? get _uid => ref.read(authStateProvider).valueOrNull?.uid;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addTask() async {
    final task = await showAddTaskDialog(context);
    final uid = _uid;
    if (task == null || uid == null) return;

    await ref.read(taskServiceProvider).addTask(uid, task);

    final when = task.reminderAt;
    if (when == null) return;

    final notifier = ref.read(notificationServiceProvider);
    final allowed = await notifier.requestPermission();
    if (!allowed) {
      _snack(
        'Task saved, but notifications are blocked. Enable them in system settings to get reminders.',
      );
      return;
    }

    final scheduled = await notifier.scheduleReminder(
      id: task.notificationId,
      title: task.title,
      body: task.description.isEmpty
          ? 'Time to do your task!'
          : task.description,
      when: when,
      askExactAlarm: true,
    );
    _snack(
      scheduled
          ? 'Reminder set'
          : 'Task saved, but the reminder could not be scheduled.',
    );
  }

  Future<void> _advanceStatus(TaskModel task) async {
    final uid = _uid;
    if (uid == null) return;

    final next = task.nextStatus;
    await ref.read(taskServiceProvider).updateStatus(uid, task.id, next);

    final notifier = ref.read(notificationServiceProvider);
    if (next == TaskStatus.done) {
      await notifier.cancel(task.notificationId);
    } else if (task.status == TaskStatus.done && task.reminderAt != null) {
      await notifier.scheduleReminder(
        id: task.notificationId,
        title: task.title,
        body: task.description.isEmpty
            ? 'Time to do your task!'
            : task.description,
        when: task.reminderAt!,
      );
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final uid = _uid;
    if (uid == null) return;
    await ref.read(notificationServiceProvider).cancel(task.notificationId);
    await ref.read(taskServiceProvider).deleteTask(uid, task.id);
  }

  Future<void> _logout() async {
    
    await ref.read(notificationServiceProvider).cancelAll();
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    ref.listen<AsyncValue<List<TaskModel>>>(tasksProvider, (_, next) {
      final list = next.valueOrNull;
      if (list != null)
        ref.read(notificationServiceProvider).syncReminders(list);
    });
    final username =
        ref.watch(userProfileProvider).valueOrNull?.username ?? 'User';
    final tasksAsync = ref.watch(tasksProvider);
    final tasks = tasksAsync.valueOrNull ?? const <TaskModel>[];

    int count(TaskStatus s) => tasks.where((t) => t.status == s).length;

    final visible = tasks.where((t) {
      final matchesFilter = _filter == null || t.status == _filter;
      final matchesQuery = t.title.toLowerCase().contains(_query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu_rounded, color: kTextDark),
                    onSelected: (_) => _logout(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'logout', child: Text('Log out')),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundImage: AssetImage('lib/assets/profile_pic.png'),
                    backgroundColor: Colors.white,
                    radius: 24,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                '${_greeting()}, $username!',
                style: textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(
                  style: textTheme.bodyLarge!.copyWith(fontSize: 40),
                  children: [
                    const TextSpan(text: 'You have '),
                    TextSpan(
                      text:
                          '${tasks.length} ${tasks.length == 1 ? 'Task' : 'Tasks'}',
                      style: const TextStyle(color: kPrimary),
                    ),
                    const TextSpan(text: ' 👍'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SearchBar(
                elevation: const WidgetStatePropertyAll(2.8),
                backgroundColor: const WidgetStatePropertyAll(kFieldBg),
                leading: const Icon(Icons.search_rounded),
                hintText: 'Search tasks ...',
                hintStyle: WidgetStatePropertyAll(
                  textTheme.bodyMedium!.copyWith(color: Colors.grey[500]),
                ),
                textStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statusButton(
                    'To-Do',
                    const Color(0xFFFF5A7A),
                    Icons.list_alt_rounded,
                    TaskStatus.todo,
                    count(TaskStatus.todo),
                  ),
                  _statusButton(
                    'Progress',
                    const Color(0xFFFFC94A),
                    Icons.bookmark_border_rounded,
                    TaskStatus.progress,
                    count(TaskStatus.progress),
                  ),
                  _statusButton(
                    'Done',
                    const Color(0xFF3CCF91),
                    Icons.done_outline_rounded,
                    TaskStatus.done,
                    count(TaskStatus.done),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Task", style: textTheme.bodyLarge),
                  GestureDetector(
                    onTap: () => setState(() => _filter = null),
                    child: Text(
                      'See All',
                      style: textTheme.bodySmall!.copyWith(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap a card to change its status, long press to delete.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: tasksAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Could not load tasks: $e')),
                  data: (_) => visible.isEmpty
                      ? const Center(
                          child: Text('No tasks here. Tap + to add one!'),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: visible.length,
                          itemBuilder: (context, index) => _taskTile(
                            visible[index],
                            _cardColors[index % _cardColors.length],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusButton(
    String name,
    Color color,
    IconData icon,
    TaskStatus status,
    int count,
  ) {
    final selected = _filter == status;
    return GestureDetector(
      onTap: () => setState(() => _filter = selected ? null : status),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: selected ? 4 : 2, color: color),
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            '$name ($count)',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskTile(TaskModel task, Color baseColor) {
    final done = task.status == TaskStatus.done;
    return GestureDetector(
      onTap: () => _advanceStatus(task),
      onLongPress: () => _deleteTask(task),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseColor, baseColor.withValues(alpha: 0.7)],
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Colors.white,
                fontSize: 18,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.hasUpcomingReminder)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          task.time,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  task.status.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
