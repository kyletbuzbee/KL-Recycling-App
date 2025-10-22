class AppConstants {
  // App Configuration
  static const String appName = 'K&L Recycling';
  static const String version = '1.0.0';

  // Business Information
  static const String phoneNumber = '903-217-4260';
  static const String email = 'info@klrecyclingaz.com';
  static const String websiteUrl = 'https://klrecyclingaz.com';
  static const String address = 'Tyler, Texas';
  static const double businessLat = 32.3519;
  static const double businessLng = -95.2972;
  static const int serviceRadiusMiles = 50;

  // Material Types
  static const List<String> acceptedMaterials = [
    'Steel',
    'Aluminum',
    'Copper',
    'Brass',
    'Zinc',
    'Stainless Steel',
    'Cast Iron'
  ];

  // Services
  static const List<Map<String, dynamic>> services = [
    {
      'id': 'roll-off-containers',
      'name': 'Roll-Off Containers',
      'description': 'Flexible container rental services',
      'icon': 'truck',
      'sizes': ['20 yd', '30 yd', '40 yd'],
      'features': [
        'Same-day delivery',
        'GPS-tracked containers',
        'Flexible rental terms'
      ]
    },
    {
      'id': 'scrap-metal-pickup',
      'name': 'Scrap Metal Pickup',
      'description': 'Professional scrap metal collection',
      'icon': 'recycle',
      'materials': ['Steel', 'Aluminum', 'Copper', 'Brass'],
      'features': [
        'High-grade payments',
        'Digital weighing',
        'Tax form processing'
      ]
    },
    {
      'id': 'container-service',
      'name': 'Container Service',
      'description': 'Temporary and permanent bins',
      'icon': 'container',
      'sizes': ['2 yd', '4 yd', '6 yd', '8 yd'],
      'features': [
        'Weekly service',
        'Flexible scheduling',
        'Lid credits'
      ]
    }
  ];
}
