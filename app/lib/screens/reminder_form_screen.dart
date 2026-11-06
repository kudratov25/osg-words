import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../data/db/app_database.dart';
import '../data/db/tables.dart';
import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../notifications/scheduler.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_container.dart';

class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({this.existing, super.key});

  final Reminder? existing;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late TimeOfDay _time;
  late RepeatType _repeatType;
  late int _dayOfWeek; // 1=Mon..7=Sun
  late int _dayOfMonth;
  late DateTime _onDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _time = e != null
        ? TimeOfDay(hour: e.timeMinutes ~/ 60, minute: e.timeMinutes % 60)
        : TimeOfDay.now();
    _repeatType = e?.repeatType ?? RepeatType.daily;
    _dayOfWeek = e?.dayOfWeek ?? DateTime.now().weekday;
    _dayOfMonth = e?.dayOfMonth ?? DateTime.now().day;
    _onDate = e?.onDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _onDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _onDate = picked);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;

    final companion = RemindersCompanion.insert(
      title: _titleController.text.trim(),
      description: Value(_descController.text.trim().isEmpty ? null : _descController.text.trim()),
      timeMinutes: _time.hour * 60 + _time.minute,
      repeatType: Value(_repeatType),
      onDate: Value(_repeatType == RepeatType.once ? DateTime(_onDate.year, _onDate.month, _onDate.day) : null),
      dayOfWeek: Value(_repeatType == RepeatType.weekly ? _dayOfWeek : null),
      dayOfMonth: Value(_repeatType == RepeatType.monthly ? _dayOfMonth : null),
    );

    final repo = context.read<Repository>();
    final scheduler = context.read<NotificationScheduler>();
    await repo.upsertReminder(companion, id: widget.existing?.id);
    await scheduler.refreshAll();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    final repo = context.read<Repository>();
    final scheduler = context.read<NotificationScheduler>();
    await repo.deleteReminder(id);
    await scheduler.refreshAll();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(isEditing ? l.reminderEdit : l.reminderNew),
          actions: [
            if (isEditing)
              IconButton(tooltip: l.reminderDelete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
                      decoration: InputDecoration(
                        labelText: l.reminderTitleLabel,
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(color: AppColors.glassBorder),
                    TextField(
                      controller: _descController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l.reminderDescLabel,
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.reminderTime, style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: Text(
                    _time.format(context),
                    style: const TextStyle(
                        color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  onTap: _pickTime,
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.reminderRepeat, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RepeatType.values.map((t) {
                        final selected = t == _repeatType;
                        return ChoiceChip(
                          label: Text(repeatLabel(l, t)),
                          selected: selected,
                          onSelected: (_) => setState(() => _repeatType = t),
                          selectedColor: AppColors.accent.withValues(alpha: 0.3),
                          backgroundColor: AppColors.glassFill,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_repeatType == RepeatType.once) ...[
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.reminderDate, style: const TextStyle(color: AppColors.textSecondary)),
                        trailing: Text(
                          DateFormat.yMMMd(locale).format(_onDate),
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                        ),
                        onTap: _pickDate,
                      ),
                    ],
                    if (_repeatType == RepeatType.weekly) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (i) {
                          final day = i + 1;
                          final selected = day == _dayOfWeek;
                          return ChoiceChip(
                            label: Text(DateFormat.E(locale).format(DateTime(2024, 1, 1 + i))), // 2024-01-01 = Monday
                            selected: selected,
                            onSelected: (_) => setState(() => _dayOfWeek = day),
                            selectedColor: AppColors.accent.withValues(alpha: 0.3),
                            backgroundColor: AppColors.glassFill,
                            labelStyle: TextStyle(
                              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          );
                        }),
                      ),
                    ],
                    if (_repeatType == RepeatType.monthly) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(l.reminderDayOfMonth, style: const TextStyle(color: AppColors.textSecondary)),
                          Expanded(
                            child: Slider(
                              value: _dayOfMonth.toDouble(),
                              min: 1,
                              max: 31,
                              divisions: 30,
                              activeColor: AppColors.accent,
                              label: '$_dayOfMonth',
                              onChanged: (v) => setState(() => _dayOfMonth = v.round()),
                            ),
                          ),
                          Text('$_dayOfMonth', style: const TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(isEditing ? l.reminderSave : l.reminderCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
