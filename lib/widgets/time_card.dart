import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeCard extends StatelessWidget {
  final DateTime currentMessageTime;
  final DateTime previousMessageTime;

  const TimeCard({
    super.key,
    required this.currentMessageTime,
    required this.previousMessageTime,
  });

  @override
  Widget build(BuildContext context) {
    final diff = currentMessageTime.difference(previousMessageTime).inMinutes;

    // عرض البطاقة إذا كان الفارق الزمني أكبر من دقيقة
    if (diff >= 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('dd MMM yyyy – hh:mm a').format(currentMessageTime),
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ),
      );
    }

    return SizedBox.shrink();  // إذا لم يكن الفارق الزمني أكثر من دقيقة لا تظهر البطاقة
  }
}
