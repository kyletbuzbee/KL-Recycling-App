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
      'category': 'general', // Match filter logic in services screen
      'sizes': ['20 yd', '30 yd', '40 yd'],
      'features': [
        'Same-day delivery',
        'GPS-tracked containers',
        'Flexible rental terms'
      ],
      'cta': 'Get Container Quote'
    },
    {
      'id': 'scrap-metal-pickup',
      'name': 'Scrap Metal Pickup',
      'description': 'Professional scrap metal collection',
      'icon': 'recycle',
      'category': 'general', // This should appear in General tab
      'materials': ['Steel', 'Aluminum', 'Copper', 'Brass'],
      'features': [
        'High-grade payments',
        'Digital weighing',
        'Tax form processing'
      ],
      'cta': 'Request Pickup'
    },
    {
      'id': 'container-service',
      'name': 'Container Service',
      'description': 'Temporary and permanent bins',
      'icon': 'container',
      'category': 'equipment', // Equipment category
      'sizes': ['2 yd', '4 yd', '6 yd', '8 yd'],
      'features': [
        'Weekly service',
        'Flexible scheduling',
        'Lid credits'
      ],
      'cta': 'Schedule Service'
    }
  ];

  // Image paths
  static const String logoPath = 'assets/images/logo.png';
  static const String disaCertificationPath = 'assets/certifications/disa.png';
  static const String isnCertificationPath = 'assets/certifications/isn-logo.png';
  static const String remaCertificationPath = 'assets/certifications/ReMa-certified-logo.png';

  // Images from static website (highest impact first)
  static const String heroImagePath = 'assets/images/hero_facility.jpg';           // 1st - Replace gradient hero
  static const String facilityExteriorPath = 'assets/images/facility_exterior.jpg'; // 2nd - Contact/about section
  static const String scrapMetalSamplesPath = 'assets/images/scrap_metal_samples.jpg'; // 3rd - Services page
  static const String serviceTruckPath = 'assets/images/service_truck.jpg';       // 4th - Services page
  static const String containerSizesPath = 'assets/images/container_sizes.jpg';   // 5th - Quote forms
  static const String teamPhotoPath = 'assets/images/team.jpg';                   // 6th - Contact page
  static const String processWeighingPath = 'assets/images/process_weighing.jpg'; // 7th - Process explanation
