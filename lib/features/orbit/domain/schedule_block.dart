import 'package:flutter/material.dart';

class ScheduleBlock {
  const ScheduleBlock({
    required this.time,
    required this.title,
    required this.description,
    required this.details,
    required this.duration,
    required this.icon,
    required this.color,
    this.id,
  });

  final String? id;
  final String time;
  final String title;
  final String description;
  final String details;
  final String duration;
  final IconData icon;
  final Color color;
}
