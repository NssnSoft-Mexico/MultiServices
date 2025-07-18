import 'dart:convert';
import 'package:ameriapp/pages/barberPages/agendaBarber.dart';
import 'package:ameriapp/pages/barberPages/userAgenda.dart';
import 'package:ameriapp/pages/menu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ameri-App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  String mensaje = '';

  void _login() async {

    String usuario = _userController.text;
    String pass = _passController.text;

    try{

    var url = Uri.parse('https://siproe.onrender.com/api/login/loginUser');
    // var url = Uri.parse('http://10.0.2.2:8080/api/login/loginUser');

    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': usuario, 'password': pass}),
    );

    if(response.statusCode == 404){
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Usuario no Encontrado!',
        );
    } else if(response.statusCode == 401) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Contraseña Incorrecta!',
        );
    } else if(response.statusCode == 200) {
      if(usuario == "barbero" && pass == "admin"){
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => AgendaBarber()),
        );
      } else if (usuario == "userBarberos" && pass == "admin") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AgendaUserScreen()),
        );
      } else if (usuario == "ameri" && pass == "admin") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Menupage()),
        );
      }
    } else {
      setState(() {
        mensaje = 'Error en la conexión';
      });
    }
    
    } catch (e) {
      print(e);
    }
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multi Servicios'),
          backgroundColor: Color.fromARGB(255, 1, 100, 87),
        ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 80),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/prueba.png'),
            )),
            SizedBox(height: 20),

            TextField(
              controller: _userController,
              decoration: InputDecoration(labelText: 'Usuario'),
            ),
            TextField(
              controller: _passController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('Iniciar Sesión')
            ),
            Text(
              mensaje,
              style: TextStyle(
                color: mensaje.contains('Exitoso') ? Colors.green : Colors.red,
              ),
            )
          ],
        ),
      ),
    );
  }
}
