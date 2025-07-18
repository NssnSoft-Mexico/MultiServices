import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final List<Map<String, dynamic>> cart;

  const OrderDetailPage({super.key, required this.cart});

  double getTotal() {
    return cart.fold(0, (sum, item) => sum + item['price']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del Pedido"),
        backgroundColor: Colors.amber,
      ),
      body: cart.isEmpty
          ? const Center(child: Text("Tu carrito está vacío"))
          : ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return ListTile(
                  leading: const Icon(Icons.fastfood),
                  title: Text(item['name']),
                  trailing: Text("\$${item['price'].toStringAsFixed(2)}"),
                );
              },
            ),
      bottomNavigationBar: Container(
        color: Colors.amber.shade100,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("\$${getTotal().toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
