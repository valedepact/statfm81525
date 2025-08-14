// lib/screens/handball_form_screen.dart
import 'package:flutter/material.dart';

class HandballFormScreen extends StatelessWidget {
  const HandballFormScreen({super.key});

  // A helper widget to create a consistent cell with borders and text
  Widget _buildCell({
    required Widget child,
    required Color borderColor,
    double height = 48.0,
    bool isHeader = false,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 12.0,
        ),
        child: child,
      ),
    );
  }

  // A helper to build a text input cell
  Widget _buildInputCell(Color borderColor) {
    return _buildCell(
      borderColor: borderColor,
      child: const TextField(
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.0),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color borderColor = Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Handball Match Statistics Form',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Match Info Table
            Table(
              border: TableBorder.all(color: borderColor),
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(3),
              },
              children: [
                TableRow(
                  children: [
                    _buildCell(child: const Text('Match No.', textAlign: TextAlign.center), borderColor: borderColor, isHeader: true),
                    _buildInputCell(borderColor),
                    _buildCell(child: const Text('Date', textAlign: TextAlign.center), borderColor: borderColor, isHeader: true),
                    _buildInputCell(borderColor),
                  ],
                ),
                TableRow(
                  children: [
                    _buildCell(child: const Text('City', textAlign: TextAlign.center), borderColor: borderColor, isHeader: true),
                    _buildInputCell(borderColor),
                    _buildCell(child: const Text('Referees', textAlign: TextAlign.center), borderColor: borderColor, isHeader: true),
                    _buildInputCell(borderColor),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Team Names and Final Score Table
            Table(
              border: TableBorder.all(color: borderColor),
              children: [
                TableRow(
                  children: [
                    _buildCell(child: const Text('Home Team', textAlign: TextAlign.center), borderColor: borderColor, isHeader: true),
                    _buildCell(child: const Text('Away Team', textAlign: TextAlign.center), borderColor: borderColor, isHeader: true),
                  ],
                ),
                TableRow(
                  children: [
                    _buildInputCell(borderColor),
                    _buildInputCell(borderColor),
                  ],
                ),
                TableRow(
                  children: [
                    _buildCell(child: const Text('Final Score'), borderColor: borderColor, isHeader: true),
                    _buildInputCell(borderColor),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
