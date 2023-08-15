import 'package:flutter/material.dart';

class QualityButton extends StatelessWidget {
  final int quality;
  final double selectedQuality;
  final Function(double) onPressed;

  const QualityButton(this.quality, this.selectedQuality, this.onPressed);

  @override
  Widget build(BuildContext context) {
    final isSelected = quality == selectedQuality.floor(); // Compare integer parts
    final buttonColor = isSelected
        ? Color.fromARGB(255, 33, 243, 54)
        : Color.fromARGB(255, 205, 210, 207);
    return ElevatedButton(
      onPressed: () => onPressed(quality.toDouble()),
      style: ElevatedButton.styleFrom(
        primary: buttonColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
      child: Text(
  '$quality KB', // Use the updated quality value
  style: TextStyle(
    fontSize: 14,
    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    color: isSelected ? Colors.white : Colors.black,
  ),
),

    );
  }
}
