import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tzdata.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agenda Nani',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const RecordatorioScreen(),
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

  DateTime? _fechaSeleccionada;
  List<DateTime> _proximasFechas = [];

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _cargarDatosGuardados();
  }

  // NUEVO: Cargar la fecha guardada en la memoria del teléfono al abrir la app
  Future<void> _cargarDatosGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    final String? fechaGuardada = prefs.getString('fecha_ultima_inyeccion');

    if (fechaGuardada != null) {
      final DateTime fecha = DateTime.parse(fechaGuardada);
      List<DateTime> fechas = [];
      
      // Recalcular las 3 fechas para pintarlas en pantalla
      for (int i = 0; i < 3; i++) {
        fechas.add(fecha.add(Duration(days: 29 + (i * 30))));
      }
      
      setState(() {
        _fechaSeleccionada = fecha;
        _proximasFechas = fechas;
      });
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  String _obtenerMes(int mes) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }

  Future<void> _programarNotificacion(DateTime fechaInicio) async {
    await flutterLocalNotificationsPlugin.cancelAll();

    List<DateTime> nuevasFechas = [];

    for (int i = 0; i < 3; i++) {
      final int diasAAgregar = 29 + (i * 30);
      final DateTime proxima = fechaInicio.add(Duration(days: diasAAgregar));
      nuevasFechas.add(proxima);

      final String titulo = '¡Hola Nani! 💖';
      final String cuerpo = i == 2
          ? 'Dosis #3: Aplica tu inyección y abre la app para programar tus próximos 3 meses.'
          : 'Dosis #${i + 1}: Hoy corresponde aplicar tu inyección.';

      await flutterLocalNotificationsPlugin.zonedSchedule(
        i, 
        titulo,
        cuerpo,
        tz.TZDateTime.from(proxima, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_recordatorio',
            'Recordatorio Inyección',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Colors.pinkAccent,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    }

    // NUEVO: Guardar la fecha en la memoria permanente del teléfono
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fecha_ultima_inyeccion', fechaInicio.toIso8601String());

    setState(() {
      _fechaSeleccionada = fechaInicio;
      _proximasFechas = nuevasFechas;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '¡Listo! Se han guardado y programado tus próximos 3 meses 🌸',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.pinkAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _construirTarjetaFecha(DateTime fecha, int indice) {
    bool esUltima = indice == 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          leading: CircleAvatar(
            backgroundColor: esUltima ? Colors.orange.shade100 : Colors.pink.shade50,
            radius: 28,
            child: Icon(
              esUltima ? Icons.notification_important_rounded : Icons.favorite_rounded,
              color: esUltima ? Colors.orange : Colors.pinkAccent,
              size: 30,
            ),
          ),
          title: Text(
            'Inyección #${indice + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                '${fecha.day} de ${_obtenerMes(fecha.month)}',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (esUltima)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🔔 Reprogramar en la app este día',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade50, Colors.purple.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Icon(
                Icons.favorite_rounded,
                color: Colors.pinkAccent,
                size: 60,
              ),
              const SizedBox(height: 10),
              const Text(
                'Agenda de Nani 💖',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 20),
              
              if (_proximasFechas.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text(
                        'Aún no hay fechas programadas.\n¡Selecciona la fecha de tu última inyección para calcular tus próximos 3 meses!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600, height: 1.5),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _proximasFechas.length,
                    itemBuilder: (context, index) {
                      return _construirTarjetaFecha(_proximasFechas[index], index);
                    },
                  ),
                ),
                
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.pinkAccent.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final DateTime? seleccion = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        helpText: 'SELECCIONA LA ÚLTIMA APLICACIÓN',
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.pinkAccent,
                                onPrimary: Colors.white,
                                onSurface: Colors.black87,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (seleccion != null) {
                        _programarNotificacion(seleccion);
                      }
                    },
                    icon: const Icon(Icons.edit_calendar_rounded, size: 28),
                    label: Text(
                      _proximasFechas.isEmpty ? 'Comenzar a Programar' : 'Elegir Nueva Fecha',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
}