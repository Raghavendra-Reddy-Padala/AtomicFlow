import "package:flutter/material.dart";
import "package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart";

class Myheatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final DateTime startDate;
  const Myheatmap({super.key, required this.datasets, required this.startDate});

  @override
  Widget build(BuildContext context) {
    return HeatMap(
      startDate: startDate,
      endDate: DateTime.now(),
      datasets: datasets,
      colorMode: ColorMode.color,
      defaultColor: Colors.white,
      textColor: Colors.black,
      showColorTip: false,
      scrollable: true,
      size: 40,
      colorsets: {
        1: Colors.green.shade100,
        2: Colors.green.shade200,
        3: Colors.green.shade300,
        4: Colors.green.shade400,
        5: Colors.green.shade500,
        6: Colors.green.shade600,
      },
  onClick: (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value.toString())),
        );
      },
      
    );
  }
}
