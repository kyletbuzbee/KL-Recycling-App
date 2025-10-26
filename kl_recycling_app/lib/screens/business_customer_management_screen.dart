import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/business_customer_provider.dart';
import '../models/business_customer.dart';
import '../widgets/common/custom_card.dart';
import '../config/theme.dart';

class BusinessCustomerManagementScreen extends StatefulWidget {
  const BusinessCustomerManagementScreen({super.key});

  @override
  State<BusinessCustomerManagementScreen> createState() =>
      _BusinessCustomerManagementScreenState();
}

class _BusinessCustomerManagementScreenState
    extends State<BusinessCustomerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  CustomerTier _selectedTierFilter = CustomerTier.standard;
  ContractStatus _selectedStatusFilter = ContractStatus.active;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessCustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('B2B Customer Management'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: _showAddCustomerDialog,
            tooltip: 'Add New Customer',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalyticsDialog,
            tooltip: 'View Analytics',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceOverlayLight,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customers by name or business type...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // Filters row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(
                        'All Tiers',
                        CustomerTier.standard,
                        _selectedTierFilter,
                        (value) => setState(() => _selectedTierFilter = value),
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        'Premium',
                        CustomerTier.premium,
                        _selectedTierFilter,
                        (value) => setState(() => _selectedTierFilter = value),
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        'Enterprise',
                        CustomerTier.enterprise,
                        _selectedTierFilter,
                        (value) => setState(() => _selectedTierFilter = value),
                      ),
                      const SizedBox(width: 16),
                      _statusFilterChip(
                        'Active',
                        ContractStatus.active,
                        _selectedStatusFilter,
                        (value) => setState(() => _selectedStatusFilter = value),
                      ),
                      const SizedBox(width: 8),
                      _statusFilterChip(
                        'Pending',
                        ContractStatus.pending,
                        _selectedStatusFilter,
                        (value) => setState(() => _selectedStatusFilter = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Customer list/grid
          Expanded(
            child: Consumer<BusinessCustomerProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading customers',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(provider.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: provider.loadCustomers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredCustomers = provider.searchCustomers(_searchController.text);

                if (filteredCustomers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_center_outlined,
                          size: 64,
                          color: AppColors.onSurfaceSecondaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text('Add your first business customer to get started'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddCustomerDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Customer'),
                        ),
                      ],
                    ),
                  );
                }

                return _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        return _buildCustomerCard(customer);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        return _buildCustomerListTile(customer);
                      },
                    );
              },
            ),
          ),
        ],
      ),

    );
  }

  Widget _filterChip(
    String label,
    CustomerTier value,
    CustomerTier selectedValue,
    ValueChanged<CustomerTier> onSelected,
  ) {
    final isSelected = value == selectedValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelected(value);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
    );
  }

  Widget _statusFilterChip(
    String label,
    ContractStatus value,
    ContractStatus selectedValue,
    ValueChanged<ContractStatus> onSelected,
  ) {
    final isSelected = value == selectedValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelected(value);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green,
    );
  }

  Widget _buildCustomerCard(BusinessCustomer customer) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  customer.companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: customer.tierColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  customer.tierDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            customer.businessType,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceSecondaryLight,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.onSurfaceSecondaryLight,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  customer.businessAddress ?? 'No address',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Spacer(),

          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: customer.statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                customer.contractStatusDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: customer.statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  customer.formattedLifetimeValue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () => _showCustomerMenu(customer),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _showCustomerDetails(customer),
    );
  }

  Widget _buildCustomerListTile(BusinessCustomer customer) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: customer.tierColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: customer.tierColor.withOpacity(0.3)),
          ),
          child: Icon(
            Icons.business,
            color: customer.tierColor,
            size: 24,
          ),
        ),

        title: Text(
          customer.companyName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.businessType),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: customer.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  customer.contractStatusDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: customer.statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              customer.formattedLifetimeValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditCustomerDialog(customer);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(customer);
                    break;
                  case 'analytics':
                    _showCustomerAnalytics(customer);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'analytics',
                  child: Row(
                    children: [
                      Icon(Icons.analytics, size: 18),
                      SizedBox(width: 8),
                      Text('Analytics'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        onTap: () => _showCustomerDetails(customer),
      ),
    );
  }

  void _showCustomerMenu(BusinessCustomer customer) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showCustomerDetails(customer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Customer'),
              onTap: () {
                Navigator.pop(context);
                _showEditCustomerDialog(customer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                _showCustomerAnalytics(customer);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Customer',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(customer);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    _showCustomerDialog(null, 'Add New Customer');
  }

  void _showEditCustomerDialog(BusinessCustomer customer) {
    _showCustomerDialog(customer, 'Edit Customer');
  }

  void _showCustomerDialog(BusinessCustomer? customer, String title) {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        customer: customer,
        title: title,
      ),
    );
  }

  void _showCustomerDetails(BusinessCustomer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customer: customer),
      ),
    );
  }

  void _showCustomerAnalytics(BusinessCustomer customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerAnalyticsDialog(customer: customer),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => BusinessAnalyticsDialog(),
    );
  }

  void _showDeleteConfirmation(BusinessCustomer customer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete "${customer.companyName}"? This action cannot be undone and will remove all associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                final success = await context
                    .read<BusinessCustomerProvider>()
                    .deleteCustomer(customer.id);

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${customer.companyName} has been deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete customer'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class CustomerFormDialog extends StatefulWidget {
  final BusinessCustomer? customer;
  final String title;

  const CustomerFormDialog({
    super.key,
    this.customer,
    required this.title,
  });

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
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
    // Note: Email would come from billingInfo if stored there
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
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
                  const Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name *',
                      border: OutlineInputBorder(),
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
                    decoration: const InputDecoration(
                      labelText: 'Business Type *',
                      border: OutlineInputBorder(),
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
                        child: Text(type.capitalize()),
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

                  const SizedBox(height: 24),

                  // Service Tiers & Status
                  const Text(
                    'Service Configuration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<CustomerTier>(
                          initialValue: _selectedTier,
                          decoration: const InputDecoration(
                            labelText: 'Service Tier',
                            border: OutlineInputBorder(),
                          ),
                          items: CustomerTier.values.map((tier) {
                            return DropdownMenuItem(
                              value: tier,
                              child: Text(tier.name.capitalize()),
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
                          decoration: const InputDecoration(
                            labelText: 'Contract Status',
                            border: OutlineInputBorder(),
                          ),
                          items: ContractStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.name.capitalize()),
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

                  const SizedBox(height: 24),

                  // Business Details
                  const Text(
                    'Business Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Business Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Business Phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveCustomer,
                          child: Text(widget.customer == null ? 'Create' : 'Update'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

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

    Navigator.pop(context);

    final provider = context.read<BusinessCustomerProvider>();
    BusinessCustomer? result;

    if (widget.customer == null) {
      result = await provider.createCustomer(customer);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.companyName} has been created'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      final success = await provider.updateCustomer(customer);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${customer.companyName} has been updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class CustomerDetailScreen extends StatelessWidget {
  final BusinessCustomer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(customer.companyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerFormDialog(
                    customer: customer,
                    title: 'Edit Customer',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and tier badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: customer.tierColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    customer.tierDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: customer.statusColor.withOpacity(0.1),
                    border: Border.all(color: customer.statusColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    customer.contractStatusDisplay,
                    style: TextStyle(
                      color: customer.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Company Information
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Company Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _detailRow('Business Type', customer.businessType.capitalize()),
                  _detailRow('Lifetime Value', customer.formattedLifetimeValue),
                  _detailRow('Total Transactions', customer.totalTransactions.toString()),
                  _detailRow('Average Transaction', customer.formattedAverageTransaction),

                  if (customer.businessAddress != null)
                    _detailRow('Address', customer.businessAddress!),

                  if (customer.businessPhone != null)
                    _detailRow('Phone', customer.businessPhone!),

                  if (customer.ein != null) _detailRow('EIN', customer.ein!),

                  if (customer.licenseNumber != null)
                    _detailRow('License', customer.licenseNumber!),

                  if (customer.accountManagerName != null)
                    _detailRow('Account Manager', customer.accountManagerName!),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Activity Summary
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: Text('Activity data will be displayed here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class CustomerAnalyticsDialog extends StatelessWidget {
  final BusinessCustomer customer;

  const CustomerAnalyticsDialog({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${customer.companyName} - Analytics'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _analyticsRow('Lifetime Value', customer.formattedLifetimeValue),
          _analyticsRow('Transactions', customer.totalTransactions.toString()),
          _analyticsRow('Average Order', customer.formattedAverageTransaction),
          _analyticsRow(
            'Service Tier',
            customer.tierDisplayName,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _analyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class BusinessAnalyticsDialog extends StatelessWidget {
  const BusinessAnalyticsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessCustomerProvider>();

    return AlertDialog(
      title: const Text('Business Analytics'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _analyticsRow('Total Customers', provider.customers.length.toString()),
            _analyticsRow('Active Accounts', provider.totalActiveAccounts.toString()),
            _analyticsRow(
              'Total Lifetime Value',
              NumberFormat.currency(symbol: '\$').format(provider.totalLifetimeValue),
            ),
            _analyticsRow(
              'Average Transaction',
              NumberFormat.currency(symbol: '\$').format(provider.averageTransactionValue),
            ),

            const Divider(height: 32),

            const Text(
              'By Service Tier',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...CustomerTier.values.map(
              (tier) => _analyticsRow(
                tier.name.capitalize(),
                provider.customerCountByTier[tier].toString(),
              ),
            ),

            const Divider(height: 32),

            const Text(
              'By Contract Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...ContractStatus.values.map(
              (status) => _analyticsRow(
                status.name.capitalize(),
                provider.customerCountByStatus[status].toString(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _analyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
