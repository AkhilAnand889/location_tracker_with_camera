import 'package:flutter/material.dart';

class CustomSnackBar extends SnackBar {
  CustomSnackBar({
    Key? key,
    required String message,
    Color backgroundColor = Colors.green,
    Duration duration = const Duration(seconds: 3),
  }) : super(
          key: key,
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: duration,
        );
}

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snackbar Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar(
                message: 'Image successfully saved to the gallery',
                backgroundColor: Colors.blue, // Customize the background color
              ),
            );
          },
          child: Text('Show Snackbar'),
        ),
      ),
    );
  }
}
