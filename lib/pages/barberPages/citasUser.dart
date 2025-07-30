// ignore: file_names
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
  String url = 'https://siproe.onrender.com/api/';

  List<ItemData> get items => List.unmodifiable(_items);

  void agregarItem(ItemData item) {
    _items.add(item);
    notifyListeners();
  }

  Future<void> eliminarItem(BuildContext context, String id, String? idUser) async {
    try {
      var url = Uri.parse('https://siproe.onrender.com/api/agenda/borrarCita/$id');
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CargaDatos(context, idUser!);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar cita')),
        );
      }
    } catch (e) {
      print('Error al conectar con la API: $e');
    }
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    notifyListeners();
  }
}

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => MisCitasScreenState();
}

String formatFechaTabla(String fechaTexto) {
  try {
    final DateTime fecha = DateTime.parse(fechaTexto);
    return DateFormat('dd/MM/yyyy').format(fecha);
  } catch (e) {
    return fechaTexto;
  }
}

Future<void> CargaDatos(BuildContext context, String id) async {
  print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
  print("Cargando datos para el ID: $id");
  try {
    var url = Uri.parse('https://siproe.onrender.com/api/agenda/obtenerAgendaById/$id');
    // var url = Uri.parse('http://10.0.2.2:8080/api/agenda/obtenerAgenda');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print("Datos cargados correctamente");
      // final data = jsonDecode(response.body);
      print(response.body);
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


class MisCitasScreenState extends State<MisCitasScreen> {

  late Timer _timer;
  String? idUser = '';

  Future<Map<String, dynamic>?> obtenerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id');
    final nombreUser = prefs.getString('nombre_user');

    setState(() {
      if (nombreUser != null) {
        idUser = id;
      }
    });


    if (id != null && nombreUser != null) {
      return {'id': id, 'nombre_user': nombreUser};
    }
    return null;
  }

  void ejecutaTimer() {
    _timer = Timer.periodic(Duration(seconds: 20), (Timer timer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CargaDatos(context, idUser!);
      });
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = await obtenerSesion();

      if(!mounted) return;

      if (session == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
      } else {
        idUser = session['id'];

        if(idUser != null) {
          await CargaDatos(context, idUser!);
          ejecutaTimer();
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
        title: const Text('Bienvenido a Barberia Alex'),
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
    );
  }
}