import 'dart:async';
import 'dart:convert';
import 'package:ameriapp/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class Horario {
  final int id;
  final String hora;

  Horario({required this.id, required this.hora});
}
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => PantallaInicioState();
}

class PantallaInicioState extends State<PantallaInicio> {
    DateTime _selectedDay = DateTime.now();
    Map<DateTime, List<Horario>> _agendaPorDia = {};
    Horario? _horarioSeleccionado;
    String idCliente = "";
    // ignore: unused_field
    late Timer _timer;
    String IdPlayer = "";

  Future<Map<String, dynamic>?> obtenerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('id');
    final nombreUser = prefs.getString('nombre_user');

    idCliente = (id ?? "0");

    if (id != null && nombreUser != null) {
      return {'id': id, 'nombre_user': nombreUser};
    }
    return null;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void ejecutaTimer() {
    _timer = Timer.periodic(Duration(seconds: 20), (Timer timer) {
      if (mounted) {
        _cargarDatos(context);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos(context);
      obtenerSesion().then((session) {
        if (session == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        } else {
          _cargarDatos(context);
          ejecutaTimer(); // ✅ solo una vez aquí
        }
      });
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sesión cerrada')),
    );

    _timer.cancel();
  }

  Future<void> sendToAdmin() async {
    final String adminPlayerId = IdPlayer; // reemplázalo
    const restApiKey = 'os_v2_app_bheuuo3nqfaahf5qul6qrrzefxert2l2fkcubp4otcc2db5i3zjsa5kpck4oj37e3jz6sdjteoh26vhhf57ahp4qhrqzkymmil7nmgy';
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');

    final body = {
      'app_id': '09c94a3b-6d81-4003-97b0-a2fd08c7242d',
      'include_player_ids': [adminPlayerId],
      'headings': {'en': 'Nueva cita agendada'},
      'contents': {'en': 'Un cliente ha reservado una cita.'},
    };

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Basic $restApiKey',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("Notificación Enviada");
      } else {
        print('❌ Error al enviar al admin: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al conectar: $e');
    }
  }

  Future<void> _getPlayerId() async {
    try {
      var url = Uri.parse('https://siproe.onrender.com/api/notification/getTokenId');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final player = data[0];
        final String tokenId = player['tokenId'];
        
        setState(() {
          IdPlayer = tokenId;
        });

      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error al conectar con la API: $e');
    }
  }

  Future<void> _crearCita() async {

    if (_horarioSeleccionado?.hora == null || _horarioSeleccionado!.hora.isEmpty) {
      print("⛔ Hora no válida, cancelando");
      return;
    }

    try {
      var url = Uri.parse('https://siproe.onrender.com/api/agenda/actualizarCita');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'estatus': true,
          'id_cliente': int.tryParse(idCliente) ?? 0,
          'id': _horarioSeleccionado!.id,
        }),
      );

      if (response.statusCode == 200) {

        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'Cita agendada exitosamente',
        );

        await _getPlayerId();
        await sendToAdmin();
        await _cargarDatos(context);

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
      var url = Uri.parse('https://siproe.onrender.com/api/agenda/obtenerAgendaByStatus/false');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final Map<DateTime, List<Horario>> tempAgenda = {};

        for (final item in data) {
          if (item['id_cliente'] == null) {
            final id = item['id'];
            final fecha = DateTime.parse(item['fecha']);
            final hora = item['hora'].toString();
            final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);

            tempAgenda.putIfAbsent(fechaSinHora, () => []);
            tempAgenda[fechaSinHora]!.add(Horario(id: id, hora: hora));
          }
        }

        setState(() {
          _agendaPorDia = tempAgenda;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Información cargada')),
        );

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
        title: const Text('Bienvenido a Barberia Axel'),
        backgroundColor: Color.fromARGB(255, 1, 100, 87),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _logout();
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
                locale: 'es_ES',
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _horarioSeleccionado = null;
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
                    children: horariosDelDia.map((horario) {
                      final isSelected = _horarioSeleccionado?.id == horario.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.green : null,
                          ),
                          onPressed: () {
                            setState(() {
                              _horarioSeleccionado = horario;
                            });
                          },
                          child: Text(
                            horario.hora,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _horarioSeleccionado == null
                  ? null
                  : () async {
                      await _crearCita();

                      setState(() {
                        _horarioSeleccionado = null;
                      });
                    },
              child: Text('Agendar cita'),
            ),
            SizedBox(height: 10)
          ],
        ),
      ),
            ],
          ),
        ),
      ),
    );
  }
}