import 'package:ameriapp/pages/barberPages/citasUser.dart';
import 'package:ameriapp/pages/barberPages/mainBarber.dart';
import 'package:flutter/material.dart';

// Ensure MisCitasScreen is imported from its correct file
// If it's defined in citasUser.dart, make sure the class exists there

class AgendaUserScreen extends StatefulWidget {
  const AgendaUserScreen({super.key});

  @override
  State<AgendaUserScreen> createState() => _AgendaUserScreenState();
}

class _AgendaUserScreenState extends State<AgendaUserScreen> {
  int _selectedIndex = 0;

  // Lista de pantallas que se alternan en el BottomNavigationBar
  final List<Widget> _pages = [
    const PantallaInicio(),
    AgendasBarber(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal[800],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Mis Citas',
          ),
        ],
      ),
    );
  }
}
