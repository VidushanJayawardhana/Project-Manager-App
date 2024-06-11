import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:fl_chart/fl_chart.dart';
import 'project_model.dart';
import 'project_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const HomeScreen({required this.flutterLocalNotificationsPlugin});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? graduationDate;
  int daysLeft = 0;
  TimeOfDay notificationTime = const TimeOfDay(hour: 10, minute: 0);
  int notificationFrequency = 1;
  List<Project> projects = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadProjects();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString('graduation_date');
    final storedHour = prefs.getInt('notification_hour') ?? 10;
    final storedMinute = prefs.getInt('notification_minute') ?? 0;
    final storedFrequency = prefs.getInt('notification_frequency') ?? 1;

    if (storedDate != null) {
      setState(() {
        graduationDate = DateTime.parse(storedDate);
        daysLeft = _calculateDaysLeft(graduationDate!);
        notificationTime = TimeOfDay(hour: storedHour, minute: storedMinute);
        notificationFrequency = storedFrequency;
      });
      _scheduleDailyNotifications();
    }
  }

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final storedProjects = prefs.getStringList('projects') ?? [];

    setState(() {
      projects = storedProjects.map((projectString) {
        final projectData = projectString.split('|');
        return Project(
            id: projectData[0],
            name: projectData[1],
            progress: int.parse(projectData[2]));
      }).toList();
    });
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final projectStrings = projects
        .map((project) => '${project.id}|${project.name}|${project.progress}')
        .toList();
    await prefs.setStringList('projects', projectStrings);
  }

  int _calculateDaysLeft(DateTime date) {
    final now = DateTime.now();
    return date.difference(now).inDays;
  }

  Future<void> _scheduleDailyNotifications() async {
    await widget.flutterLocalNotificationsPlugin.cancelAll();
    for (int i = 0; i < notificationFrequency; i++) {
      final scheduledTime = _nextInstanceOf(notificationTime.hour,
          notificationTime.minute + i * (1440 ~/ notificationFrequency));
      await _scheduleNotification(scheduledTime, i);
    }
  }

  Future<void> _scheduleNotification(
      tz.TZDateTime scheduledDate, int id) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'daily_notification_channel_id',
      'Daily Notifications',
      channelDescription: 'Daily reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await widget.flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Days Left',
      'You have $daysLeft days left before graduation.',
      scheduledDate,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _pickGraduationDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('graduation_date', pickedDate.toIso8601String());
      setState(() {
        graduationDate = pickedDate;
        daysLeft = _calculateDaysLeft(graduationDate!);
      });
      _scheduleDailyNotifications();
    }
  }

  Future<void> _pickNotificationTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: notificationTime,
    );

    if (pickedTime != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', pickedTime.hour);
      await prefs.setInt('notification_minute', pickedTime.minute);
      setState(() {
        notificationTime = pickedTime;
      });
      _scheduleDailyNotifications();
    }
  }

  void _updateNotificationFrequency(int frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_frequency', frequency);
    setState(() {
      notificationFrequency = frequency;
    });
    _scheduleDailyNotifications();
  }

  void _addProject(Project project) {
    setState(() {
      projects.add(project);
    });
    _saveProjects();
  }

  void _editProject(Project updatedProject) {
    setState(() {
      final index =
          projects.indexWhere((project) => project.id == updatedProject.id);
      if (index != -1) {
        projects[index] = updatedProject;
      }
    });
    _saveProjects();
  }

  void _deleteProject(String id) {
    setState(() {
      projects.removeWhere((project) => project.id == id);
    });
    _saveProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Manager'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Days left before graduation:'),
              Text(
                daysLeft.toString(),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              ElevatedButton(
                onPressed: _pickGraduationDate,
                child: const Text('Set Graduation Date'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _pickNotificationTime,
                child: const Text('Set Notification Time'),
              ),
              const SizedBox(height: 16.0),
              const Text('Notification Frequency:'),
              DropdownButton<int>(
                value: notificationFrequency,
                items: [1, 2, 3, 4].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value times per day'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    _updateNotificationFrequency(newValue);
                  }
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjectDetailsScreen(
                        onSave: _addProject,
                      ),
                    ),
                  );
                },
                child: Text('Add Project'),
              ),
              SizedBox(height: 32.0),
              Text('Project Progress'),
              Container(
                padding: EdgeInsets.all(16.0),
                height: 300,
                child: buildBarChart(),
              ),
              SizedBox(height: 32.0),
              Text('Project List'),
              ListView.builder(
                shrinkWrap: true,
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ListTile(
                    title: Text(project.name),
                    subtitle: Text('Progress: ${project.progress}%'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailsScreen(
                                  project: project,
                                  onSave: _editProject,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteProject(project.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= projects.length) {
                  return const Text('');
                }
                return Text(projects[index].name);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text('${value.toInt()}%');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: projects
            .asMap()
            .entries
            .map(
              (entry) => BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.progress.toDouble(),
                    color: Colors.blue,
                    width: 20,
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
