import 'package:flutter/material.dart';
import 'package:todo_app/models/task_model.dart';

Future<TaskModel?> showAddTaskDialog(BuildContext context) {
  return showDialog<TaskModel>(
    context: context,
    builder: (_) => const _AddTaskDialog(),
  );
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  late DateTime _date;
  late TimeOfDay _time;
  bool _remind = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = DateTime.now().add(const Duration(hours: 1));
    _date = DateTime(initial.year, initial.month, initial.day);
    _time = TimeOfDay.fromDateTime(initial);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime get _when =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime(today.year, today.month, today.day))
          ? today
          : _date,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_remind && !_when.isAfter(DateTime.now())) {
      setState(() => _error = 'Pick a date and time in the future.');
      return;
    }

    final label =
        '${MaterialLocalizations.of(context).formatMediumDate(_date)} • ${_time.format(context)}';

    Navigator.pop(
      context,
      TaskModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        time: label,
        reminderAt: _remind ? _when : null,
        notificationId:
            (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 0x7FFFFFFF,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);

    return AlertDialog(
      title: const Text('New Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Remind me'),
                value: _remind,
                onChanged: (v) => setState(() {
                  _remind = v;
                  _error = null;
                }),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(loc.formatMediumDate(_date)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_time.format(context)),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
