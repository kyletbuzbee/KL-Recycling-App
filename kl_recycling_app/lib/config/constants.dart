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

  // K&L Recycling Locations
  // AI-Generated Icon Paths (for new features)
  static const String iconCameraEstimate = 'assets/icons/camera_estimate.png';
  static const String iconAiAnalysis = 'assets/icons/ai_analysis.png';
  static const String iconScaleWeight = 'assets/icons/scale_weight.png';
  static const String iconMaterialDetector = 'assets/icons/material_detector.png';
  static const String iconSteelScrap = 'assets/icons/steel_scrap.png';
  static const String iconAluminumScrap = 'assets/icons/aluminum_scrap.png';
  static const String iconCopperScrap = 'assets/icons/copper_scrap.png';
  static const String iconBrassScrap = 'assets/icons/brass_scrap.png';
  static const String iconRolloffContainer = 'assets/icons/rolloff_container.png';
  static const String iconTruckDelivery = 'assets/icons/truck_delivery.png';
  static const String iconHookLiftTruck = 'assets/icons/hook_lift_truck.png';
  static const String iconLocationPin = 'assets/icons/location_pin.png';
  static const String iconAnalyticsDashboard = 'assets/icons/analytics_dashboard.png';
  static const String iconSustainabilityMetrics = 'assets/icons/sustainability_metrics.png';
  static const String iconCustomerManagement = 'assets/icons/customer_management.png';
  static const String iconCarCrusher = 'assets/icons/car_crusher.png';
  static const String iconHomeDashboard = 'assets/icons/home_dashboard.png';
  static const String iconNotificationCenter = 'assets/icons/notification_center.png';
  static const String iconSettings = 'assets/icons/settings_preferences.png';
  static const String iconSafetyFirst = 'assets/icons/safety_first.png';
  static const String iconComplianceCertified = 'assets/icons/compliance_certified.png';

  static const List<Map<String, dynamic>> locations = [
    {
      'name': "K&L Recycling - Tyler (HQ)",
      'address': "4134 Chandler Highway, Tyler, TX 75702",
      'phone': "(903) 592-8288",
      'hours': "9:00 AM - 5:00 PM Mon-Fri",
      'services': ["Ferrous Metals", "Non-Ferrous Metals", "Industrial Services"],
      'isHeadquarters': true,
      'state': "TX",
      'lat': 32.3135,
      'lng': -95.3222
    },
    {
      'name': "K&L Recycling - Tyler Highway 271",
      'address': "10757 Highway 271, Tyler, TX 75708",
      'phone': "(903) 877-4442",
      'hours': "9:00 AM - 5:00 PM Mon-Fri",
      'services': ["Ferrous Metals", "Non-Ferrous Metals"],
      'isHeadquarters': false,
      'state': "TX",
      'lat': 32.3388,
      'lng': -95.2658
    },
    {
      'name': "K&L Recycling - Mineola",
      'address': "2590 Highway 80 West, Mineola, TX 75773",
      'phone': "(903) 569-6231",
      'hours': "9:00 AM - 5:00 PM Mon-Fri, 8:00 AM - 12:00 PM Sat",
      'services': ["Ferrous Metals", "Non-Ferrous Metals", "Roll-off Containers"],
      'isHeadquarters': false,
      'state': "TX",
      'lat': 32.6609,
      'lng': -95.4975
    },
    {
      'name': "K&L Recycling - Crockett",
      'address': "403 South 2nd Street, Crockett, TX 75835",
      'phone': "(936) 544-2986",
      'hours': "9:00 AM - 5:00 PM Mon-Fri, 8:00 AM - 12:00 PM Sat",
      'services': ["Ferrous Metals", "Non-Ferrous Metals", "Auto Salvage"],
      'isHeadquarters': false,
      'state': "TX",
      'lat': 31.3186,
      'lng': -95.4564
    },
    {
      'name': "K&L Recycling - Palestine",
      'address': "4340 State Highway 19, Palestine, TX 75801",
      'phone': "(903) 723-0171",
      'hours': "9:00 AM - 5:00 PM Mon-Fri, 8:00 AM - 12:00 PM Sat",
      'services': ["Ferrous Metals", "Non-Ferrous Metals", "Industrial Services"],
      'isHeadquarters': false,
      'state': "TX",
      'lat': 31.7847,
      'lng': -95.6296
    },
    {
      'name': "K&L Recycling - Nacogdoches",
      'address': "2508 Woden Road, Nacogdoches, TX 75961",
      'phone': "(936) 560-2244",
      'hours': "9:00 AM - 5:00 PM Mon-Fri, 8:00 AM - 12:00 PM Sat",
      'services': ["Ferrous Metals", "Non-Ferrous Metals"],
      'isHeadquarters': false,
      'state': "TX",
      'lat': 31.6300,
      'lng': -94.7427
    },
    {
      'name': "K&L Recycling - Jasper",
      'address': "1953 Highway 190 West, Jasper, TX 75951",
      'phone': "(409) 384-9600",
      'hours': "9:00 AM - 5:00 PM Mon-Fri, 8:00 AM - 12:00 PM Sat",
      'services': ["Ferrous Metals", "Non-Ferrous Metals"],
      'isHeadquarters': false,
      'state': "TX",
      'lat': 30.9339,
      'lng': -94.0036
    },
    {
      'name': "K&L Recycling - Jacksonville",
      'address': "599 CR 1520, Jacksonville, TX 75766",
      'phone': "(903) 586-1181",
      'hours': "9:00 AM - 5:00 PM Mon-Fri, 8:00 AM - 12:00 PM Sat",
      'services': ["Ferrous Metals", "Non-Ferrous Metals", "Roll-off Containers"],
      'isHeadquarters': false,
      'state': "TX",
      'lat': 31.9827,
      'lng': -95.2886
    },
    {
      'name': "K&L Recycling - Great Bend",
      'address': "700 Frey Street, Great Bend, KS 67530",
      'phone': "(620) 792-5956",
      'hours': "9:00 AM - 5:00 PM Mon-Fri, 8:00 AM - 12:00 PM Sat",
      'services': ["Ferrous Metals", "Non-Ferrous Metals", "Industrial Services"],
      'isHeadquarters': false,
      'state': "KS",
      'lat': 38.3645,
      'lng': -98.7647
    },
  ];
}
