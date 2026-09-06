import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String name;
  final IconData icon;

  const ServiceCategory({
    this.id = '',
    required this.name,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
    };
  }

  factory ServiceCategory.fromMap(Map<String, dynamic> map, String docId) {
    // To avoid Icon Tree Shaking issues, we try to match the icon from our predefined list
    // If not found, we use a fallback constant icon
    final String name = map['name'] ?? '';
    final IconData iconData = _getIconForService(name);

    return ServiceCategory(
      id: docId,
      name: name,
      icon: iconData,
    );
  }

  static IconData _getIconForService(String name) {
    switch (name) {
      case 'Electrician':
        return Icons.electrical_services;
      case 'Plumber':
        return Icons.plumbing;
      case 'AC Technician':
        return Icons.ac_unit;
      case 'Solar Panel Service':
        return Icons.solar_power;
      case 'Home Tutor':
        return Icons.school;
      case 'Car Wash at Home':
        return Icons.local_car_wash;
      case 'Painter':
        return Icons.format_paint;
      case 'CCTV Service':
        return Icons.videocam;
      case 'Event Decoration':
        return Icons.celebration;
      case 'Beauty Salon / Haircut':
        return Icons.content_cut;
      case 'House Cleaning':
        return Icons.cleaning_services;
      case 'Maid Service':
        return Icons.home;
      case 'Carpenter':
        return Icons.carpenter;
      case 'Laundry & Ironing':
        return Icons.local_laundry_service;
      default:
        return Icons.home_repair_service;
    }
  }
}

const List<ServiceCategory> allServiceCategories = [
  ServiceCategory(name: 'Electrician', icon: Icons.electrical_services),
  ServiceCategory(name: 'Plumber', icon: Icons.plumbing),
  ServiceCategory(name: 'AC Technician', icon: Icons.ac_unit),
  ServiceCategory(name: 'Solar Panel Service', icon: Icons.solar_power),
  ServiceCategory(name: 'Home Tutor', icon: Icons.school),
  ServiceCategory(name: 'Car Wash at Home', icon: Icons.local_car_wash),
  ServiceCategory(name: 'Painter', icon: Icons.format_paint),
  ServiceCategory(name: 'CCTV Service', icon: Icons.videocam),
  ServiceCategory(name: 'Event Decoration', icon: Icons.celebration),
  ServiceCategory(name: 'Beauty Salon / Haircut', icon: Icons.content_cut),
  ServiceCategory(name: 'House Cleaning', icon: Icons.cleaning_services),
  ServiceCategory(name: 'Maid Service', icon: Icons.home),
  ServiceCategory(name: 'Carpenter', icon: Icons.carpenter),
  ServiceCategory(name: 'Laundry & Ironing', icon: Icons.local_laundry_service),
];

List<String> get serviceCategoryNames =>
    allServiceCategories.map((category) => category.name).toList();

ServiceCategory? findServiceByName(String name) {
  try {
    return allServiceCategories.firstWhere(
      (category) => category.name == name,
    );
  } catch (_) {
    return null;
  }
}
