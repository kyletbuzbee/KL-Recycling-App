import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kl_recycling_app/services/appointment_service.dart';
import 'package:kl_recycling_app/models/appointment.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';
import 'package:kl_recycling_app/config/theme.dart';

/// Screen for customers to book appointments with K&L Recycling facilities
class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _weightController = TextEditingController();

  // Form state
  AppointmentType _selectedType = AppointmentType.materialPickup;
  String _selectedFacilityId = '';
  DateTime _selectedDate = DateTime.now();
  TimeSlot? _selectedTimeSlot;
  double _estimatedWeight = 0.0;
  bool _isBookingInProgress = false;

  List<TimeSlot> _availableSlots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final appointmentService = context.read<AppointmentService>();

    // Initialize service if not already done
    await appointmentService.initialize();

    // Set default facility to main yard
    final facilities = appointmentService.facilities;
    if (facilities.containsKey('facility_main')) {
      setState(() {
        _selectedFacilityId = 'facility_main';
      });
      await _loadAvailableSlots();
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedFacilityId.isEmpty) return;

    setState(() {
      _isLoadingSlots = true;
    });

    final appointmentService = context.read<AppointmentService>();
    final slots = appointmentService.getAvailableSlots(_selectedFacilityId, _selectedDate);

    setState(() {
      _availableSlots = slots;
      _isLoadingSlots = false;
    });
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate() || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    // Combine selected date and time
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTimeSlot!.dateTime.hour,
      _selectedTimeSlot!.dateTime.minute,
    );

    setState(() {
      _isBookingInProgress = true;
    });

    try {
      final appointmentService = context.read<AppointmentService>();

      final result = await appointmentService.createAppointment(
        customerId: 'user_${DateTime.now().millisecondsSinceEpoch}', // TODO: Use actual user ID
        facilityId: _selectedFacilityId,
        scheduledDateTime: scheduledDateTime,
        type: _selectedType,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        estimatedWeight: _estimatedWeight > 0 ? _estimatedWeight : null,
      );

      if (mounted) {
        setState(() {
          _isBookingInProgress = false;
        });

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedType.displayName} appointment scheduled successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back
          Navigator.of(context).pop();
        } else if (result.hasConflict) {
          await _showConflictDialog(result.conflicts!, result.alternatives!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Failed to schedule appointment')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isBookingInProgress = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling appointment: $e')),
        );
      }
    }
  }

  Future<void> _showConflictDialog(List<SchedulingConflict> conflicts, List<DateTime> alternatives) async {
    final conflict = conflicts.first; // Handle first conflict for simplicity

    final selectedAlternative = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Conflict'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conflict.conflictReason),
            const SizedBox(height: 16),
            const Text('Available alternatives:'),
            const SizedBox(height: 8),
            ...alternatives.take(3).map((alternative) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Radio<DateTime>(
                    value: alternative,
                    groupValue: null,
                    onChanged: (value) => Navigator.of(context).pop(value),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy hh:mm a').format(alternative),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedAlternative != null && mounted) {
      // Book the alternative appointment
      final appointmentService = context.read<AppointmentService>();

      setState(() {
        _isBookingInProgress = true;
      });

      try {
        final result = await appointmentService.createAppointment(
          customerId: 'user_${DateTime.now().millisecondsSinceEpoch}',
          facilityId: _selectedFacilityId,
          scheduledDateTime: selectedAlternative,
          type: _selectedType,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          estimatedWeight: _estimatedWeight > 0 ? _estimatedWeight : null,
        );

        setState(() {
          _isBookingInProgress = false;
        });

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment scheduled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Failed to schedule alternative appointment')),
          );
        }
      } catch (e) {
        setState(() {
          _isBookingInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentService = context.watch<AppointmentService>();
    final facilities = appointmentService.facilities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Appointment Type Selection
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What type of appointment do you need?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppointmentType.values.map((type) {
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(type.icon, size: 16),
                            const SizedBox(width: 4),
                            Text(type.displayName),
                          ],
                        ),
                        selected: _selectedType == type,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedType = type;
                            });
                          }
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Facility Selection
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Facility',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (facilities.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      children: facilities.values.map((facility) => RadioListTile<String>(
                        title: Text(facility.name),
                        subtitle: Text(facility.address),
                        value: facility.id,
                        groupValue: _selectedFacilityId,
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              _selectedFacilityId = value;
                              _selectedTimeSlot = null; // Reset time selection
                            });
                            await _loadAvailableSlots();
                          }
                        },
                      )).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date Selection
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
                          _selectedTimeSlot = null; // Reset time selection
                        });
                        await _loadAvailableSlots();
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Time Slot Selection
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Available Times',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoadingSlots)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedFacilityId.isEmpty)
                    const Text('Please select a facility first')
                  else if (_isLoadingSlots)
                    const Center(child: CircularProgressIndicator())
                  else if (_availableSlots.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No available time slots for this date.\nTry selecting a different date.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableSlots.where((slot) => slot.available).map((slot) {
                        final isSelected = _selectedTimeSlot?.dateTime == slot.dateTime;
                        return ChoiceChip(
                          label: Text(DateFormat('hh:mm a').format(slot.dateTime)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTimeSlot = selected ? slot : null;
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Additional Details (varies by appointment type)
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Additional Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Estimated weight (for some appointment types)
                  if (_selectedType == AppointmentType.materialPickup ||
                      _selectedType == AppointmentType.bulkMaterial)
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Weight (lbs)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 500',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (_weightController.text.isEmpty) return null; // Optional
                        final weight = double.tryParse(_weightController.text);
                        if (weight != null && weight <= 0) {
                          return 'Weight must be greater than 0';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _estimatedWeight = double.tryParse(value) ?? 0.0;
                      },
                    ),

                  if (_selectedType == AppointmentType.materialPickup ||
                      _selectedType == AppointmentType.bulkMaterial)
                    const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Additional Notes (optional)',
                      border: const OutlineInputBorder(),
                      hintText: 'Any special instructions or requirements',
                      helperText: 'Let us know about access restrictions, special equipment needed, or other details',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Booking Summary
            if (_selectedTimeSlot != null)
              CustomCard(
                padding: const EdgeInsets.all(16),
                variant: CardVariant.filled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Type', _selectedType.displayName),
                    _buildSummaryRow('Facility',
                      facilities[_selectedFacilityId]?.name ?? 'Unknown'),
                    _buildSummaryRow('Date',
                      DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate)),
                    _buildSummaryRow('Time',
                      DateFormat('hh:mm a').format(_selectedTimeSlot!.dateTime)),
                    if (_estimatedWeight > 0)
                      _buildSummaryRow('Estimated Weight', '${_estimatedWeight.toStringAsFixed(1)} lbs'),
                    const SizedBox(height: 16),
                    const Text(
                      'Duration: 1 hour standard appointment',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedFacilityId.isNotEmpty &&
                          _selectedTimeSlot != null &&
                          !_isBookingInProgress)
                    ? _submitBooking
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _selectedFacilityId.isNotEmpty &&
                                  _selectedTimeSlot != null &&
                                  !_isBookingInProgress
                      ? AppColors.primary
                      : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: _isBookingInProgress
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Schedule ${_selectedType.displayName}',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
