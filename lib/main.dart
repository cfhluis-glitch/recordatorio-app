import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  tzdata.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RecordatorioScreen(),
    );
  }
}

class RecordatorioScreen extends StatefulWidget {
  const RecordatorioScreen({super.key});

  @override
  State<RecordatorioScreen> createState() => _RecordatorioScreenState();
}

class _RecordatorioScreenState extends State<RecordatorioScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Solicitar permiso de notificaciones en pantalla para Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _programarNotificacion(DateTime fechaInicio) async {
    final DateTime proximaFecha = fechaInicio.add(const Duration(days: 30));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Recordatorio de Inyección',
      'Hoy corresponde aplicar la inyección.',
      tz.TZDateTime.from(proximaFecha, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_recordatorio',
          'Recordatorio Inyección',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      // Usamos inexactAllowWhileIdle para evitar bloqueos en Android 14
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recordatorio programado para: ${proximaFecha.day}/${proximaFecha.month}/${proximaFecha.year}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorio de Nani')),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          onPressed: () async {
            final DateTime? seleccion = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2023),
              lastDate: DateTime(2030),
            );
            if (seleccion != null) {
              _programarNotificacion(seleccion);
            }
          },
          child: const Text(
            'Seleccionar Fecha de Última Inyección',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}