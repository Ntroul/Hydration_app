enum ReminderStatus { upcoming, completed, skipped }

class Reminder {
  final String time;
  final int amountMl;
  final ReminderStatus status;

  const Reminder({
    required this.time,
    required this.amountMl,
    required this.status,
  });
}

// Shared sample data used across screens
final List<Reminder> sampleReminders = const [
  Reminder(time: '8:00 PM', amountMl: 250, status: ReminderStatus.upcoming),
  Reminder(time: '7:00 PM', amountMl: 250, status: ReminderStatus.upcoming),
  Reminder(time: '5:30 PM', amountMl: 250, status: ReminderStatus.completed),
  Reminder(time: '3:00 PM', amountMl: 250, status: ReminderStatus.completed),
  Reminder(time: '1:00 PM', amountMl: 250, status: ReminderStatus.skipped),
];