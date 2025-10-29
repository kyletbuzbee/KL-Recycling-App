import 'package:flutter/material.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/core/constants.dart';

import 'package:kl_recycling_app/core/widgets/common/custom_card.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  String _contactReason = 'General Inquiry';

  final List<String> _contactReasons = [
    'General Inquiry',
    'Container Quote',
    'Scrap Metal Pickup',
    'Service Question',
    'Billing Question',
    'Complaint',
    'Emergency Service',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitContactForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Prepare contact form data
      final contactData = {
        'contact_reason': _contactReason,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // TODO: Replace with actual backend service call
      // For now, simulate sending to API or database
      await Future.delayed(const Duration(seconds: 2));

      // Print to console for debugging (in production, this would be logged properly)
      debugPrint('Contact form submitted: ${contactData.toString()}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message sent successfully! We\'ll get back to you within 24 hours.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 4),
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _subjectController.clear();
      _messageController.clear();
      setState(() => _contactReason = 'General Inquiry');

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
        title: const Text('Contact Us'),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get In Touch',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re here to help with all your recycling and container needs. Choose the best way to reach us.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Contact Information Cards
            Row(
              children: [
                Expanded(
                  child: _ContactCard(
                    assetPath: 'assets/icons/contact_phone.png',
                    title: 'Call Us',
                    subtitle: AppConstants.phoneNumber,
                    description: 'Mon-Fri 7:30AM-5:00PM\nSat 8:00AM-12:00PM',
                    onTap: () => _callPhone(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.email,
                    title: 'Email Us',
                    subtitle: AppConstants.email,
                    description: '24/7 email support\nResponse within 24 hours',
                    onTap: () => _sendEmail(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ContactCard(
              assetPath: 'assets/icons/location_pin_service.png',
              title: 'Visit Our Yard',
              subtitle: AppConstants.address,
              description: 'Monday - Friday: 7:30 AM - 5:00 PM\nSaturday: 8:00 AM - 12:00 PM',
              onTap: () => _getDirections(context),
            ),

            const SizedBox(height: 32),

            // Contact Form
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Us a Message',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill out the form below and we\'ll get back to you as soon as possible.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Reason
                    const Text(
                      'Reason for Contact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _contactReason,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message),
                      ),
                      items: _contactReasons.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _contactReason = value!);
                      },
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
                        // Allow letters, spaces, hyphens, apostrophes (2-50 chars)
                        final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]{2,50}$");
                        if (!nameRegex.hasMatch(value)) {
                          return 'Please enter a valid name (2-50 characters, letters only)';
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

                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        hintText: '(555) 123-4567',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null; // Phone is optional
                        }
                        // Allow digits, spaces, hyphens, parentheses (7-15 chars)
                        final phoneRegex = RegExp(r'^[\d\s\-\(\)]{7,15}$');
                        if (!phoneRegex.hasMatch(value)) {
                          return 'Please enter a valid phone number (7-15 digits)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Subject
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.subject),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Message
                    TextFormField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your message';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitContactForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                                  ),
                                )
                            : const Text(
                                'Send Message',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Certifications Section
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Certifications & Licenses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Licensed, insured, and committed to professional service standards.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CertificationBadge(
                        imagePath: AppConstants.disaCertificationPath,
                        label: 'DISA Certified',
                        size: 60,
                      ),
                      _CertificationBadge(
                        imagePath: AppConstants.isnCertificationPath,
                        label: 'ISN Member',
                        size: 60,
                      ),
                      _CertificationBadge(
                        imagePath: AppConstants.remaCertificationPath,
                        label: 'ReMA Certified',
                        size: 60,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Frequently Asked Questions
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _FAQItem(
                    question: 'What types of metal do you accept?',
                    answer: 'We accept steel, aluminum, copper, brass, and other non-hazardous scrap metals.',
                  ),

                  const SizedBox(height: 12),

                  _FAQItem(
                    question: 'Do you offer same-day service?',
                    answer: 'Yes, we offer same-day pickup and delivery services within our service area.',
                  ),

                  const SizedBox(height: 12),

                  _FAQItem(
                    question: 'What are your business hours?',
                    answer: 'Monday-Friday: 7:30 AM - 5:00 PM, Saturday: 8:00 AM - 12:00 PM.',
                  ),

                  const SizedBox(height: 12),

                  _FAQItem(
                    question: 'Do you provide containers?',
                    answer: 'Yes, we offer roll-off containers in various sizes for temporary and permanent use.',
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'For more FAQs or specific questions, please use the contact form above.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _callPhone(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call ${AppConstants.phoneNumber}')),
    );
  }

  void _sendEmail(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Email ${AppConstants.email}')),
    );
  }

  void _getDirections(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Directions to ${AppConstants.address}')),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  const _ContactCard({
    this.icon,
    this.assetPath,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  }) : assert(icon != null || assetPath != null, 'Either icon or assetPath must be provided');

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: assetPath != null
                    ? Image.asset(
                        assetPath!,
                        width: 20,
                        height: 20,
                        color: AppColors.primary,
                      )
                    : Icon(
                        icon,
                        size: 20,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceSecondary,
          ),
        ),
      ],
    );
  }
}

class _CertificationBadge extends StatelessWidget {
  final String imagePath;
  final String label;
  final double size;

  const _CertificationBadge({
    required this.imagePath,
    required this.label,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: size * 0.4,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
