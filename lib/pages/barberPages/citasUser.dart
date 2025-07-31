import 'dart:async';
import 'dart:convert';
import 'package:ameriapp/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void limpiar() {
    _items.clear();
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TableData(),
      child: AgendasBarber(),
    ),
  );
}

class AgendasBarber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TableData(),
      child: MaterialApp(
        title: 'Agenda Barber',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: AgendasScreen(),
      ),
    );
  }
}

class AgendasScreen extends StatefulWidget {
  @override
  _AgendasBarberState createState() => _AgendasBarberState();
}

Future<void> CargaDatos(BuildContext context, String id) async {
  try {
    var url = Uri.parse('https://siproe.onrender.com/api/agenda/obtenerAgendaById/$id');
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
            estatus: item['estatus'],
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

Future<Map<String, dynamic>?> obtenerSesion() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getString('id');
  final nombreUser = prefs.getString('nombre_user');

  if (id != null && nombreUser != null) {
    return {'id': id, 'nombre_user': nombreUser};
  }
  return null;
}

String formatFechaTabla(String fechaTexto) {
  try {
    final DateTime fecha = DateTime.parse(fechaTexto);
    return DateFormat('dd/MM/yyyy').format(fecha);
  } catch (e) {
    return fechaTexto;
  }
}
class _AgendasBarberState extends State<AgendasScreen> {
  DateTime? _fechaSeleccionada;
  String idUser = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {

      obtenerSesion().then((session) {
        if (session == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        } else {
          idUser = session['id'];
          CargaDatos(context, idUser);
        }
      });
    });
  }

  Future<void> mostrarDetallesCita(BuildContext context, String id) async {
    try {
      var url = Uri.parse('https://siproe.onrender.com/api/login/obtenerDetailCita/$id');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if(response.statusCode == 200) {
        final data = jsonDecode(response.body);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
              title: Text('Detalles de la Cita'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Nombre: ${data['nombre_user']}'),
                  Text('Fecha de Creación: ${data['fecha_creacion']}')
                ],
              ),
            ),
          );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener detalles de la cita')),
        );
      }
    } catch (e) {
      print('Error al obtener detalles de la cita: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener detalles de la cita')),
      );
    }
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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableData = Provider.of<TableData>(context);

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(                
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: DataTable(
                    columnSpacing: 33,
                    columns: const [
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Hora')),
                      DataColumn(label: Text('Estatus')),
                    ],
                    rows: tableData.items.map<DataRow>((item) {
                      return DataRow(cells: [
                        DataCell(Text(formatFechaTabla(item.fecha))),
                        DataCell(Text(item.hora)),
                        DataCell(Text(item.estatus == false ? "Sin Agendar" : "Agendada")),
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
