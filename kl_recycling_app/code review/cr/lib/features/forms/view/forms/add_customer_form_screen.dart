import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/features/business_customer/logic/business_customer_provider.dart';
import 'package:kl_recycling_app/features/business_customer/models/business_customer.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/constants/app_icons.dart';
import 'package:kl_recycling_app/core/widgets/common/app_icon_tile.dart';

class AddCustomerFormScreen extends StatefulWidget {
  final BusinessCustomer? customer;

  const AddCustomerFormScreen({
    super.key,
    this.customer,
  });

  @override
  State<AddCustomerFormScreen> createState() => _AddCustomerFormScreenState();
}

class _AddCustomerFormScreenState extends State<AddCustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _einController = TextEditingController();
  final _licenseController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  CustomerTier _selectedTier = CustomerTier.standard;
  ContractStatus _selectedStatus = ContractStatus.active;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _loadCustomerData(widget.customer!);
    }
  }

  void _loadCustomerData(BusinessCustomer customer) {
    _companyController.text = customer.companyName;
    _businessTypeController.text = customer.businessType;
    _einController.text = customer.ein ?? '';
    _licenseController.text = customer.licenseNumber ?? '';
    _taxIdController.text = customer.taxId ?? '';
    _addressController.text = customer.businessAddress ?? '';
    _phoneController.text = customer.businessPhone ?? '';
    _selectedTier = customer.tier;
    _selectedStatus = customer.contractStatus;
    _isActive = customer.isActive;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _businessTypeController.dispose();
    _einController.dispose();
    _licenseController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          )
          else
            IconButton(
              icon: AppIconTile(
                assetPath: AppIcons.qualityControlVerified,
                semanticLabel: 'Save customer',
                width: 24,
                height: 24,
              ),
              onPressed: _saveCustomer,
              tooltip: 'Save Customer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: 'Company Name *',
                  prefixIcon: AppIconTile(
                    assetPath: AppIcons.containerRollOff,
                    semanticLabel: 'Company building',
                    width: 20,
                    height: 20,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _businessTypeController.text.isEmpty
                    ? 'construction'
                    : _businessTypeController.text,
                decoration: InputDecoration(
                  labelText: 'Business Type *',
                  prefixIcon: AppIconTile(
                    assetPath: AppIcons.constructionDebris,
                    semanticLabel: 'Business type category',
                    width: 20,
                    height: 20,
                  ),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  'construction',
                  'manufacturing',
                  'automotive',
                  'electronics',
                  'industrial',
                  'demolition',
                  'other',
                ].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text('${type[0].toUpperCase()}${type.substring(1).toLowerCase()}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _businessTypeController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Business type is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Service Configuration
              Text(
                'Service Configuration',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Service Tier and Status in one row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CustomerTier>(
                      initialValue: _selectedTier,
                      decoration: const InputDecoration(
                        labelText: 'Service Tier',
                        prefixIcon: Icon(Icons.star),
                        border: OutlineInputBorder(),
                      ),
                      items: CustomerTier.values.map((tier) {
                        return DropdownMenuItem(
                          value: tier,
                          child: Text('${tier.name[0].toUpperCase()}${tier.name.substring(1).toLowerCase()}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedTier = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<ContractStatus>(
                      initialValue: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Contract Status',
                        prefixIcon: const Icon(Icons.business),
                        border: const OutlineInputBorder(),
                      ),
                      items: ContractStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text('${status.name[0].toUpperCase()}${status.name.substring(1).toLowerCase()}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Active Account'),
                subtitle: const Text(
                    'Active customers can place orders and receive services'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),

              const SizedBox(height: 32),

              // Business Details
              Text(
                'Business Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _einController,
                      decoration: const InputDecoration(
                        labelText: 'EIN',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                        helperText: 'Employer Identification Number',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(
                        labelText: 'License Number',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _taxIdController,
                decoration: const InputDecoration(
                  labelText: 'Tax ID',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Business Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Business Phone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  final phoneRegExp = RegExp(r'^\(?(\d{3})\)?[-.\s]?(\d{3})[-.\s]?(\d{4})$');
                  if (!phoneRegExp.hasMatch(value)) {
                    return 'Enter a valid phone number (e.g., XXX-XXX-XXXX)';
                  }
                  return null;
                },
              ),

              // Bottom padding for navigation
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customer = BusinessCustomer(
        id: widget.customer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        companyName: _companyController.text.trim(),
        businessType: _businessTypeController.text,
        tier: _selectedTier,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        lastActivity: widget.customer?.lastActivity ?? DateTime.now(),
        isActive: _isActive,
        lifetimeValue: widget.customer?.lifetimeValue ?? 0.0,
        totalTransactions: widget.customer?.totalTransactions ?? 0,
        averageTransaction: widget.customer?.averageTransaction ?? 0.0,
        billingInfo: widget.customer?.billingInfo ?? {},
        contractStatus: _selectedStatus,
        contractStartDate: widget.customer?.contractStartDate,
        contractEndDate: widget.customer?.contractEndDate,
        ein: _einController.text.isEmpty ? null : _einController.text.trim(),
        licenseNumber: _licenseController.text.isEmpty ? null : _licenseController.text.trim(),
        taxId: _taxIdController.text.isEmpty ? null : _taxIdController.text.trim(),
        businessAddress: _addressController.text.isEmpty ? null : _addressController.text.trim(),
        businessPhone: _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
      );

      final provider = context.read<BusinessCustomerProvider>();
      BusinessCustomer? result;

      if (widget.customer == null) {
        result = await provider.createCustomer(customer);
        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.companyName} has been created'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Return to customer list
        }
      } else {
        final success = await provider.updateCustomer(customer);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${customer.companyName} has been updated'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Return to customer details
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update customer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
