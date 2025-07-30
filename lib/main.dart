import 'dart:convert';
import 'package:ameriapp/pages/barberPages/agendaBarber.dart';
import 'package:ameriapp/pages/barberPages/userAgenda.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  OneSignal.initialize('09c94a3b-6d81-4003-97b0-a2fd08c7242d');
  await OneSignal.Notifications.requestPermission(true);

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    event.preventDefault();
    event.notification.display();
  });

  final playerId = OneSignal.User.pushSubscription.id;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TableData()),
      ],
      child: MyApp(),
    ),
  );
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
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  String mensaje = '';

  Future<void> cargaTokenAdmin() async {
    final playerId = OneSignal.User.pushSubscription.id;

    if (playerId == null) {
      print("❌ No se pudo obtener el Player ID");
      return;
    }

    try {
      var url = Uri.parse('https://siproe.onrender.com/api/notification/sendTokenId');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "tokenId": playerId,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'Token registrado exitosamente',
        );
      } else if (response.statusCode == 409) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'Token ya registrado',
        );
      } else {
        print('Error al cargar el token del administrador: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al cargar el token del administrador: $e');
    }
  }

  void _login() async {

    // FirebaseMessaging messaging = FirebaseMessaging.instance;
    // String? token = await messaging.getToken();
    // print("Firebase Token:++++++++++++++++++++++++++ $token");
        
    String usuario = _userController.text;
    String pass = _passController.text;
    String tipo = '';

    try {
      var url = Uri.parse('https://siproe.onrender.com/api/login/loginUser');

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': usuario, 'password': pass}),
      );

      if (response.statusCode == 404) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Usuario no Encontrado!',
        );
      } else if (response.statusCode == 401) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Contraseña Incorrecta!',
        );
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        tipo = data['tipo'].toString();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('id', jsonEncode(data['id']));
        await prefs.setString('nombre_user', jsonEncode(data['nombre_user']));

        if(tipo == "1") {

          cargaTokenAdmin();
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AgendaBarber()),
          );
        } else if (tipo == "3") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AgendaUserScreen()),
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

  void _registrar() async {
    String nombre = _nombreController.text;
    String direccion = _direccionController.text;
    String correo = _correoController.text;
    String usuario = _usuarioController.text;
    String contrasena = _contrasenaController.text;

    if (nombre.isEmpty || direccion.isEmpty || correo.isEmpty || usuario.isEmpty || contrasena.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Por favor, completa todos los campos.',
      );
      return;
    }

    try {

      var url = Uri.parse('https://siproe.onrender.com/api/login/crearUsuario');

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_user': nombre,
          'direccion': direccion,
          'correo': correo,
          'username': usuario,
          'password': contrasena,
          'fecha_creacion': DateTime.now().toIso8601String(),
          'tipo': 3
        }),
      );

      if (response.statusCode == 200) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'Usuario registrado exitosamente.',
        );

        _clearForm();
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Error al registrar usuario: ${response.statusCode}',
        );
      }

    } catch (e) {
      print('Error al registrar usuario: $e');
    }
  }

  void _clearForm() {
    _nombreController.text = '';
    _direccionController.text = '';
    _correoController.text = '';
    _usuarioController.text = '';
    _contrasenaController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barberia Axel'),
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
              ),
            ),
            SizedBox(height: 5),
            TextField(
              controller: _userController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(), hintText: 'Usuario'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(), hintText: 'Contraseña'),
              obscureText: true,
            ),
            SizedBox(height: 20),

            /// Texto clickeable que abre el modal de registro
            InkWell(
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    bool isButtonEnabled = false;

                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setModalState) {
                        void checkFields() {
                          setModalState(() {
                            isButtonEnabled =
                                _nombreController.text.trim().isNotEmpty &&
                                _correoController.text.trim().isNotEmpty &&
                                _direccionController.text.trim().isNotEmpty &&
                                _contrasenaController.text.trim().isNotEmpty &&
                                _usuarioController.text.trim().isNotEmpty &&
                                _contrasenaController.text.trim().isNotEmpty;
                          });
                        }

                        return Padding(
                          padding: MediaQuery.of(context).viewInsets.add(
                            const EdgeInsets.all(24.0),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text(
                                  'Formulario de registro',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 24.0),
                                TextField(
                                  controller: _nombreController,
                                  onChanged: (_) => checkFields(),
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre completo',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                TextField(
                                  controller: _direccionController,
                                  onChanged: (_) => checkFields(),
                                  decoration: const InputDecoration(
                                    labelText: 'Dirección',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                TextField(
                                  controller: _correoController,
                                  onChanged: (_) => checkFields(),
                                  decoration: const InputDecoration(
                                    labelText: 'Correo electrónico',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                TextField(
                                  controller: _usuarioController,
                                  onChanged: (_) => checkFields(),
                                  decoration: const InputDecoration(
                                    labelText: 'Usuario',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                TextField(
                                  controller: _contrasenaController,
                                  obscureText: true,
                                  onChanged: (_) => checkFields(),
                                  decoration: const InputDecoration(
                                    labelText: 'Contraseña',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 24.0),
                                ElevatedButton(
                                  onPressed: isButtonEnabled
                                      ? () {
                                          _registrar();

                                          setModalState(() {
                                            _clearForm();
                                            isButtonEnabled = false;
                                          });
                                            
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Registrado: ${_nombreController.text}'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          Navigator.pop(context);
                                        }
                                      : null,
                                  child: const Text('Registrarse'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              child: Text(
                'Regístrate para acceder a nuestros servicios',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _login,
              child: Text('Iniciar Sesión'),
            ),
            Text(
              mensaje,
              style: TextStyle(
                color: mensaje.contains('Exitoso') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
