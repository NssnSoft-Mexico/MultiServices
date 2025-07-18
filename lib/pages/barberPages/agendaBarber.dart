import 'dart:async';
import 'dart:convert';
import 'package:ameriapp/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ItemData {
  final String id;
  final String fecha;
  final String hora;
  final bool estatus;

  ItemData({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.estatus,
  });
}

class TableData extends ChangeNotifier {
  final List<ItemData> _items = [];

  List<ItemData> get items => List.unmodifiable(_items);

  void agregarItem(ItemData item) {
    _items.add(item);
    notifyListeners();
  }

  void eliminarItem(BuildContext context, String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EliminarCita(context, id);
    });
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TableData(),
      child: AgendaBarber(),
    ),
  );
}

class AgendaBarber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TableData(),
      child: MaterialApp(
        title: 'Agenda Barber',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: AgendaScreen(),
      ),
    );
  }
}

class AgendaScreen extends StatefulWidget {
  @override
  _AgendaBarberState createState() => _AgendaBarberState();
}

Future<void> CargaDatos(BuildContext context) async {
  try {
    var url = Uri.parse('https://siproe.onrender.com/api/agenda/obtenerAgenda');
    // var url = Uri.parse('http://10.0.2.2:8080/api/agenda/obtenerAgenda');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final tableData = Provider.of<TableData>(context, listen: false);
      tableData.limpiar();

      for (final item in data) {
        tableData.agregarItem(
          ItemData(
            id: item['id'].toString(),
            fecha: item['fecha'],
            hora: item['hora'],
            estatus: item['estatus']
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Información cargada')),
      );
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

// ignore: non_constant_identifier_names
Future<void> EliminarCita(BuildContext context, String id) async {
  try {
    var url = Uri.parse('https://siproe.onrender.com/api/agenda/borrarCita/$id');
    // var url = Uri.parse('http://10.0.2.2:8080/api/agenda/borrarCita/$id');

    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      CargaDatos(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar cita')),
      );
    }
  } catch (e) {
    print('Error al conectar con la API: $e');
  }
}

String formatFechaTabla(String fechaTexto) {
  try {
    final DateTime fecha = DateTime.parse(fechaTexto);
    return DateFormat('dd/MM/yyyy').format(fecha);
  } catch (e) {
    return fechaTexto;
  }
}

class _AgendaBarberState extends State<AgendaScreen> {
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  DateTime? _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CargaDatos(context);
    });
  }

  Future<void> AgregarAgenda(
    BuildContext context,
    TextEditingController fechaController,
    TextEditingController horaController,
  ) async {
    final hora = _horaController.text.trim();

    if (_fechaSeleccionada == null || hora.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final fechaFormateada = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!);

    try {
      var url = Uri.parse('https://siproe.onrender.com/api/agenda/crearAgenda');
      // var url = Uri.parse('http://10.0.2.2:8080/api/agenda/crearAgenda');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "fecha": fechaFormateada,
          "hora": hora,
          "id_cliente": null,
          "estatus": false,
        }),
      );

      if (response.statusCode == 200) {
        CargaDatos(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error al conectar con la API: $e');
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
        _fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableData = Provider.of<TableData>(context);

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                clipBehavior: Clip.hardEdge,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Agregar Horarios a la Agenda',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _fechaController,
                        readOnly: true,
                        onTap: () => _seleccionarFecha(context),
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _horaController,
                        decoration: InputDecoration(
                          labelText: 'Hora (Ejemplo: 10:00 AM)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => AgregarAgenda(
                          context,
                          _fechaController,
                          _horaController,
                        ),
                        child: Text('Agregar a la Agenda'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              SingleChildScrollView(                
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0), // Espacio al final
                  child: DataTable(
                    columnSpacing: 36,
                    columns: const [
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Hora')),
                      DataColumn(label: Text('Estatus')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: tableData.items.map<DataRow>((item) {
                      return DataRow(cells: [
                        DataCell(Text(formatFechaTabla(item.fecha))),
                        DataCell(Text(item.hora)),
                        DataCell(Text(item.estatus == false ? "Sin Agendar" : "Agendada")),
                        DataCell(
                          TextButton(
                            onPressed: () {
                              tableData.eliminarItem(context, item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Cita eliminada')),
                              );
                            },
                            child: Text('Borrar'),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
