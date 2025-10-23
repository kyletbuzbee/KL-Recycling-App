class AppConstants {
  // App Configuration
  static const String appName = 'K&L Recycling';
  static const String version = '1.0.0';

  // Business Information
  static const String phoneNumber = '(903) 592-6299';
  static const String email = 'info@kl-recycling.com';
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
      'id': 'mobile-car-crushing',
      'name': 'Mobile Car Crushing',
      'description': 'On-site vehicle crushing services',
      'icon': 'truck',
      'category': 'specialized',
      'features': [
        'Mobile crushing equipment',
        'On-site service available',
        'Competitive pricing'
      ],
      'cta': 'Request Service'
    },
    {
      'id': 'oil-gas-demo',
      'name': 'Oil & Gas Demo',
      'description': 'Equipment demolition and recycling',
      'icon': 'recycle',
      'category': 'specialized',
      'features': [
        'Heavy equipment dismantling',
        'Hazardous materials handling',
        'Permitted and insured'
      ],
      'cta': 'Get Quote'
    },
    {
      'id': 'roll-off-containers',
      'name': 'Roll-Off Containers',
      'description': 'Flexible container rental services',
      'icon': 'container',
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
      'id': 'public-drop-off',
      'name': 'Public Drop-Off Locations',
      'description': 'Convenient recycling drop-off sites',
      'icon': 'location',
      'category': 'general',
      'features': [
        'Multiple locations',
        '24/7 access at select sites',
        'All materials accepted'
      ],
      'cta': 'Find Location'
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
}
