import 'package:ameriapp/pages/cart/OrdenDetail.dart';
import 'package:flutter/material.dart';

class MenuPages extends StatefulWidget {
  const MenuPages({super.key});

  @override
  State<MenuPages> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPages> {
  final List<Map<String, dynamic>> _cart = [];

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      _cart.add(item);
    });
  }

  // double _getTotal() {
  //   return _cart.fold(0, (sum, item) => sum + item['price']);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú'),
        backgroundColor: Colors.amber,
        actions: [/* ... */],
      ),
    body: ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildCategory("🍗 Alitas", [ 
          alitasItem("7 piezas de alitas", 70, [
            "Mango Habanero",
            "Fresa Hot",
            "BBQ",
            "Solas",
            "Hot Original",
            "Salsa Aparte"
          ]),
          alitasItem("12 piezas de alitas", 120, [
            "Mango Habanero",
            "Fresa Hot",
            "BBQ",
            "Solas",
            "Hot Original",
            "Salsa Aparte"
          ]),
          alitasItem("18 piezas (1kg) de alitas", 180, [
            "Mango Habanero",
            "Fresa Hot",
            "BBQ",
            "Solas",
            "Hot Original",
            "Salsa Aparte"
          ]),
        ]),
        _buildCategory("🍟 Papas", [
          papasItem("Francesa", 50 , [
            "Con todo",
            "Con Queso",
            "Con Queso y Catsup",
            "Solo con Salsa",
          ]),
        ]),
        _buildCategory("🍗 Boneless (5 piezas)", [
          bonelessItem("Boneless", 85, [
            "Mango Habanero",
            "Fresa Hot",
            "BBQ",
            "Solos",
            "Hot Original",
            "Salsa Aparte"
          ]),
        ]),
        _buildCategory("🍔 Hamburguesas", [
          burgersItem("Sencilla (Queso Americano, Carne)", 55, [
            "Queso Oaxaca", 
            "Sin Cebolla", 
            "Sin Picante"
          ]),
          burgersItem("Clasica (Queso Americano, Carne, Tocino)", 75, [
            "Queso Oaxaca", 
            "Sin Cebolla", 
            "Sin Picante"
          ]),
          burgersItem("AmeriBurger (Queso Americano, Carne, Tocino, Piña, Jamon)", 95, [
            "Queso Oaxaca", 
            "Sin Cebolla", 
            "Sin Piña",
            "SIn Jamon",
            "Sin Picante"
          ]),
          burgersItem("Especial (Queso Americano, Queso Oaxaca, Carne, Tocino, Piña, Jamon)", 75, [ 
            "Sin Cebolla", 
            "Sin Piña",
            "Sin Jamon",
            "Sin Picante"
          ]),
          burgersItem("Doble (Queso Americano, Queso Oaxaca, Carne, Tocino, Piña, Jamon)", 90, [
            "Queso Oaxaca", 
            "Sin Cebolla", 
            "Sin Piña",
            "SIn Jamon",
            "Sin Picante"
          ]), 
          
        ]),
        // const Divider(),
        // ListTile(
        //   title: const Text("🛒 Carrito (Visual)"),
        //   subtitle: Text("Productos: ${_cart.length}"),
        //   trailing: Text("\$${_getTotal().toStringAsFixed(2)} MXN"),
        // ),
        // if (_cart.isNotEmpty)
        //   ..._cart.map((item) => ListTile(
        //         leading: const Icon(Icons.check),
        //         title: Text(item['name']),
        //         trailing: Text("\$${item['price']}"),
        //       )),
      ],
    ),
    floatingActionButton: Stack(
    alignment: Alignment.topRight,
    children: [
      FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {
          if (_cart.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailPage(cart: _cart),
              ),
            );
          }
        },
        child: const Icon(Icons.shopping_cart),
      ),
      if (_cart.isNotEmpty)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              _cart.length.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
    ],
  ),
    );
  }

  Widget alitasItem(String nombreBase, double precioBase, List<String> salsasDisponibles) {
    List<String> selectedSalsas = [];

    return StatefulBuilder(
      builder: (context, setState) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ExpansionTile(
          title: Text(nombreBase),
          subtitle: Text("\$${precioBase.toStringAsFixed(2)} MXN"),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 8),
              child: Text("Selecciona tus salsas:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...salsasDisponibles.map((salsa) {
              return CheckboxListTile(
                title: Text(salsa),
                value: selectedSalsas.contains(salsa),
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      selectedSalsas.add(salsa);
                    } else {
                      selectedSalsas.remove(salsa);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                String descripcion = "$nombreBase\nSalsas: ${selectedSalsas.join(', ')}";
                _addToCart({'name': descripcion, 'price': precioBase});
              },
              child: const Text("Agregar al carrito"),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget papasItem(String nombreBase, double precioBase, List<String> salsasDisponibles) {
    List<String> selectedSalsas = [];

    return StatefulBuilder(
      builder: (context, setState) => Card(
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: ExpansionTile(
          title: Text(nombreBase),
          subtitle: Text("\$${precioBase.toStringAsFixed(2)} MXN"),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 8),
              child: Text("Selecciona tus salsas:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...salsasDisponibles.map((salsa) {
              return CheckboxListTile(
                title: Text(salsa),
                value: selectedSalsas.contains(salsa),
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      selectedSalsas.add(salsa);
                    } else {
                      selectedSalsas.remove(salsa);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                String descripcion = "$nombreBase\nSalsas: ${selectedSalsas.join(', ')}";
                _addToCart({'name': descripcion, 'price': precioBase});
              },
              child: const Text("Agregar al carrito"),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget bonelessItem(String nombreBase, double precioBase, List<String> salsasDisponibles) {
    List<String> selectedSalsas = [];

    return StatefulBuilder(
      builder: (context, setState) => Card(
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: ExpansionTile(
          title: Text(nombreBase),
          subtitle: Text("\$${precioBase.toStringAsFixed(2)} MXN"),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 8),
              child: Text("Selecciona tus salsas:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...salsasDisponibles.map((salsa) {
              return CheckboxListTile(
                title: Text(salsa),
                value: selectedSalsas.contains(salsa),
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      selectedSalsas.add(salsa);
                    } else {
                      selectedSalsas.remove(salsa);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                String descripcion = "$nombreBase\nSalsas: ${selectedSalsas.join(', ')}";
                _addToCart({'name': descripcion, 'price': precioBase});
              },
              child: const Text("Agregar al carrito"),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget burgersItem(String nombreBase, double precioBase, List<String> salsasDisponibles) {
    List<String> selectedSalsas = [];

    return StatefulBuilder(
      builder: (context, setState) => Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: ExpansionTile(
          title: Text(nombreBase),
          subtitle: Text("\$${precioBase.toStringAsFixed(2)} MXN"),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 8),
              child: Text("Selecciona tus complementos:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...salsasDisponibles.map((salsa) {
              return CheckboxListTile(
                title: Text(salsa),
                value: selectedSalsas.contains(salsa),
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      selectedSalsas.add(salsa);
                    } else {
                      selectedSalsas.remove(salsa);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                String descripcion = "$nombreBase\nSalsas: ${selectedSalsas.join(', ')}";
                _addToCart({'name': descripcion, 'price': precioBase});
              },
              child: const Text("Agregar al carrito"),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategory(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        ...items,
      ],
    );
  }
}
