import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';

class ScrapPickupForm extends StatefulWidget {
  const ScrapPickupForm({super.key});

  @override
  State<ScrapPickupForm> createState() => _ScrapPickupFormState();
}

class _ScrapPickupFormState extends State<ScrapPickupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _useCurrentLocation = false;
  Position? _currentPosition;
  DateTime? _pickupDate;

  final List<String> _selectedMaterials = [];
  final List<String> _materialOptions = [
    'Steel',
    'Aluminum',
    'Copper',
    'Brass',
    'Stainless Steel',
    'Cast Iron',
    'Other'
  ];

  final List<String> _timeSlots = [
    'Morning (8AM-12PM)',
    'Afternoon (12PM-4PM)',
    'Evening (4PM-7PM)',
    'Anytime'
  ];

  String _selectedTimeSlot = 'Morning (8AM-12PM)';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them to use this feature.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')),
        );
        return;
      }

      setState(() => _isLoading = true);
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _useCurrentLocation = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _pickupDate) {
      setState(() {
        _pickupDate = picked;
      });
    }
  }

  void _toggleMaterial(String material) {
    setState(() {
      if (_selectedMaterials.contains(material)) {
        _selectedMaterials.remove(material);
      } else {
        _selectedMaterials.add(material);
      }
    });
  }

  Future<void> _submitPickupRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one material type')),
      );
      return;
    }
    if (_pickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Submit pickup request to backend/service
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup request submitted! We\'ll contact you to confirm within 24 hours.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scrap Metal Pickup Request'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Pickup Location',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Use Current Location'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_currentPosition != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Using current location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Street Address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: _useCurrentLocation ? 'Street Address (optional)' : 'Street Address *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.home),
                      ),
                      validator: (value) {
                        if (!_useCurrentLocation && (value == null || value.isEmpty)) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: _useCurrentLocation ? 'City (optional)' : 'City *',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (!_useCurrentLocation && (value == null || value.isEmpty)) {
                                return 'Please enter your city';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _zipController,
                            decoration: InputDecoration(
                              labelText: _useCurrentLocation ? 'ZIP Code (optional)' : 'ZIP Code *',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (!_useCurrentLocation && (value == null || value.isEmpty)) {
                                return 'Please enter your ZIP code';
                              }
                              if (!_useCurrentLocation && value != null && value.length != 5) {
                                return 'ZIP code must be 5 digits';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Materials & Scheduling',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Material Types
                    const Text(
                      'Select Material Types',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _materialOptions.map((material) {
                        final isSelected = _selectedMaterials.contains(material);
                        return FilterChip(
                          label: Text(material),
                          selected: isSelected,
                          onSelected: (_) => _toggleMaterial(material),
                          backgroundColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Brief Description of Materials *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 2 tons of steel beams, aluminum cans, etc.',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe your materials';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Pickup Date
                    const Text(
                      'Preferred Pickup Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _pickupDate == null
                              ? 'Select pickup date'
                              : '${_pickupDate!.month}/${_pickupDate!.day}/${_pickupDate!.year}',
                          style: TextStyle(
                            color: _pickupDate == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Time Slot
                    const Text(
                      'Preferred Time Slot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTimeSlot,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: _timeSlots.map((slot) {
                        return DropdownMenuItem(
                          value: slot,
                          child: Text(slot),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedTimeSlot = value!);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Additional Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Any special instructions or access notes',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPickupRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Request Pickup',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
