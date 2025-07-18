import 'dart:convert';
import 'package:ameriapp/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class AgendaUserScreen extends StatefulWidget {
  const AgendaUserScreen({super.key});

  @override
  State<AgendaUserScreen> createState() => _AgendaUserScreenState();
}

class _AgendaUserScreenState extends State<AgendaUserScreen> {
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<String>> _agendaPorDia = {};
  String? _horarioSeleccionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos(context);
    });
  }

  Future<void> _logout() async {
    // Aquí puedes implementar la lógica de cierre de sesión
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage()),
    );
  }

  Future<void> _crearCita() async {
    if (_horarioSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecciona un horario.')),
      );
      return;
    }

    try {
      final url = Uri.parse('https://siproe.onrender.com/api/agenda/actualizarCita');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'estatus': true,
          'id_cliente': 1,
          'id': 7 
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cita creada exitosamente.')),
        );
        _cargarDatos(context); // Recargar agenda
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la cita: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error al conectar con la API: $e');
    }
  }

  Future<void> _cargarDatos(BuildContext context) async {
    try {
      final url = Uri.parse('https://siproe.onrender.com/api/agenda/obtenerAgendaByStatus/false');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final Map<DateTime, List<String>> tempAgenda = {};

        for (final item in data) {
          if (item['id_cliente'] == null) {
            final fecha = DateTime.parse(item['fecha']);
            final hora = item['hora'].toString();
            final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);

            tempAgenda.putIfAbsent(fechaSinHora, () => []);
            tempAgenda[fechaSinHora]!.add(hora);
          }
        }

        setState(() {
          _agendaPorDia = tempAgenda;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error al conectar con la API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final horariosDelDia = _agendaPorDia[DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
        )] ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido a Barberia Alex'),
        backgroundColor: Color.fromARGB(255, 1, 100, 87),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TableCalendar(
                focusedDay: _selectedDay,
                firstDay: DateTime.now(),
                lastDay: DateTime.utc(2030, 12, 31),
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _horarioSeleccionado = null; // Reiniciar selección
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final cleanDay = DateTime(day.year, day.month, day.day);
                    if (_agendaPorDia.containsKey(cleanDay)) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Horarios disponibles:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (horariosDelDia.isEmpty)
                Text("No hay horarios disponibles para este día.")
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: horariosDelDia.map((hora) {
                      final isSelected = _horarioSeleccionado == hora;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.green : null,
                          ),
                          onPressed: () {
                            setState(() {
                              _horarioSeleccionado = hora;
                            });
                          },
                          child: Text(
                            hora,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _horarioSeleccionado == null
                      ? null
                      : () {
                          _crearCita();
                          // Mostrar mensaje de éxito
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cita creada: $_horarioSeleccionado')),
                          );

                          setState(() {
                            _horarioSeleccionado = null; // Reiniciar selección
                          });
                        },
                  child: Text('Crear cita'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
