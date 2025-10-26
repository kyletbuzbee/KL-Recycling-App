import 'package:flutter/material.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/services/notification_service.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = false;
  bool _remindersEnabled = true;
  bool _weeklySummariesEnabled = true;
  bool _achievementsEnabled = true;
  bool _tipsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.getNotificationSettings();
    setState(() {
      _notificationsEnabled = settings['notificationsEnabled'] as bool;
      _remindersEnabled = settings['reminderEnabled'] as bool;
      _weeklySummariesEnabled = settings['weeklySummaryEnabled'] as bool;
      _achievementsEnabled = settings['achievementEnabled'] as bool;
      _tipsEnabled = settings['tipsEnabled'] as bool;
      _reminderTime = TimeOfDay(
        hour: settings['reminderHour'] as int,
        minute: settings['reminderMinute'] as int,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master notification toggle
            CustomCard(
              color: AppColors.surface,
              child: SwitchListTile(
                title: Text(
                  'Enable Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Allow the app to send you notifications',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                value: _notificationsEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (value) async {
                  setState(() => _notificationsEnabled = value);
                  await NotificationService.setNotificationsEnabled(value);

                  if (value) {
                    // Re-enable individual settings when master toggle is on
                    await NotificationService.setReminderEnabled(_remindersEnabled);
                    await NotificationService.setWeeklySummaryEnabled(_weeklySummariesEnabled);
                    await NotificationService.setAchievementEnabled(_achievementsEnabled);
                    await NotificationService.setTipsEnabled(_tipsEnabled);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'NOTIFICATION TYPES',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceSecondary,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 16),

            // Recycling reminders
            CustomCard(
              color: AppColors.surface,
              child: SwitchListTile(
                title: Text(
                  'Daily Recycling Reminders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _notificationsEnabled ? AppColors.onSurface : AppColors.onSurfaceSecondary,
                  ),
                ),
                subtitle: Text(
                  'Get notified daily about recycling opportunities',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                value: _notificationsEnabled && _remindersEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: _notificationsEnabled ? (value) async {
                  setState(() => _remindersEnabled = value);
                  await NotificationService.setReminderEnabled(value);
                } : null,
              ),
            ),

            // Reminder time picker (only show if reminders are enabled)
            if (_notificationsEnabled && _remindersEnabled) ...[
              const SizedBox(height: 8),
              CustomCard(
                color: AppColors.surface,
                child: ListTile(
                  title: Text(
                    'Reminder Time',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    _reminderTime.format(context),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final TimeOfDay? selectedTime = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                      );

                      if (selectedTime != null) {
                        setState(() => _reminderTime = selectedTime);
                        await NotificationService.setReminderTime(selectedTime);

                        // Reschedule if reminders are enabled
                        if (_remindersEnabled) {
                          await NotificationService.scheduleDailyReminder(
                            time: selectedTime,
                            enabled: true,
                          );
                        }
                      }
                    },
                    color: AppColors.primary,
                  ),
                  onTap: () async {
                    final TimeOfDay? selectedTime = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );

                    if (selectedTime != null) {
                      setState(() => _reminderTime = selectedTime);
                      await NotificationService.setReminderTime(selectedTime);

                      if (_remindersEnabled) {
                        await NotificationService.scheduleDailyReminder(
                          time: selectedTime,
                          enabled: true,
                        );
                      }
                    }
                  },
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Weekly summaries
            CustomCard(
              color: AppColors.surface,
              child: SwitchListTile(
                title: Text(
                  'Weekly Progress Summaries',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _notificationsEnabled ? AppColors.onSurface : AppColors.onSurfaceSecondary,
                  ),
                ),
                subtitle: Text(
                  'Receive weekly reports on your recycling impact',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                value: _notificationsEnabled && _weeklySummariesEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: _notificationsEnabled ? (value) async {
                  setState(() => _weeklySummariesEnabled = value);
                  await NotificationService.setWeeklySummaryEnabled(value);
                } : null,
              ),
            ),

            const SizedBox(height: 8),

            // Achievement notifications
            CustomCard(
              color: AppColors.surface,
              child: SwitchListTile(
                title: Text(
                  'Achievement Announcements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _notificationsEnabled ? AppColors.onSurface : AppColors.onSurfaceSecondary,
                  ),
                ),
                subtitle: Text(
                  'Get notified when you unlock new badges and milestones',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                value: _notificationsEnabled && _achievementsEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: _notificationsEnabled ? (value) async {
                  setState(() => _achievementsEnabled = value);
                  await NotificationService.setAchievementEnabled(value);
                } : null,
              ),
            ),

            const SizedBox(height: 8),

            // Eco tips
            CustomCard(
              color: AppColors.surface,
              child: SwitchListTile(
                title: Text(
                  'Eco Tips & Education',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _notificationsEnabled ? AppColors.onSurface : AppColors.onSurfaceSecondary,
                  ),
                ),
                subtitle: Text(
                  'Learn new ways to reduce waste and help the environment',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                value: _notificationsEnabled && _tipsEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: _notificationsEnabled ? (value) async {
                  setState(() => _tipsEnabled = value);
                  await NotificationService.setTipsEnabled(value);

                  if (value) {
                    await NotificationService.scheduleWeeklyTip();
                  }
                } : null,
              ),
            ),

            const SizedBox(height: 32),

            // Test notifications section
            Text(
              'TEST NOTIFICATIONS',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceSecondary,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 16),

            CustomCard(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Test Notification Types',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Send Recycling Reminder'),
                    subtitle: const Text('Test the daily reminder notification'),
                    trailing: IconButton(
                      icon: const Icon(Icons.send),
                      color: AppColors.primary,
                      onPressed: _notificationsEnabled ? () {
                        NotificationService.sendEcoTip();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Eco tip notification sent!')),
                        );
                      } : null,
                    ),
                    enabled: _notificationsEnabled,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Send Achievement Notification'),
                    subtitle: const Text('Test achievement unlock notification'),
                    trailing: IconButton(
                      icon: const Icon(Icons.emoji_events),
                      color: AppColors.primary,
                      onPressed: _notificationsEnabled ? () {
                        NotificationService.sendAchievementNotification(
                          achievementTitle: 'Test Achievement',
                          description: 'This is a test notification',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Achievement notification sent!')),
                        );
                      } : null,
                    ),
                    enabled: _notificationsEnabled,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Info card
            CustomCard(
              color: AppColors.info.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notifications help you maintain consistent recycling habits and stay motivated on your environmental journey. You can customize when and what type of notifications you receive.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
