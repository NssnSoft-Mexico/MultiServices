import 'package:flutter/material.dart';


class Pedidospage extends StatelessWidget {
  const Pedidospage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
      ),
      body: Center(
        child: Text('Lista de pedidos'),
      ),
    );
  }
}