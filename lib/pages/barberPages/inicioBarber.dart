import 'package:flutter/material.dart';

class HomeBarber extends StatelessWidget {
  const HomeBarber({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
              backgroundImage: AssetImage('assets/logo.png'),
            )),
            SizedBox(height: 20),
          ],
        )
      ),
    );
  }
}