import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/business_customer.dart';

class BusinessCustomerProvider extends ChangeNotifier {
  static const String _tableName = 'business_customers';

  Database? _database;
  bool _isLoading = false;
  String? _error;
  List<BusinessCustomer> _customers = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<BusinessCustomer> get customers => _customers;

  // Filtered lists
  List<BusinessCustomer> get activeCustomers =>
    _customers.where((c) => c.isActive).toList();

  List<BusinessCustomer> get premiumCustomers =>
    _customers.where((c) => c.tier == CustomerTier.premium).toList();

  List<BusinessCustomer> get enterpriseCustomers =>
    _customers.where((c) => c.tier == CustomerTier.enterprise).toList();

  // Initialize database
  Future<void> _initDatabase() async {
    if (_database != null) return;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'business_customers.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            firebaseId TEXT,
            companyName TEXT NOT NULL,
            businessType TEXT NOT NULL,
            tier TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            lastActivity TEXT NOT NULL,
            isActive INTEGER NOT NULL,
            lifetimeValue REAL NOT NULL,
            totalTransactions INTEGER NOT NULL,
            averageTransaction REAL NOT NULL,
            billingInfo TEXT,
            contractStatus TEXT NOT NULL,
            contractStartDate TEXT,
            contractEndDate TEXT,
            ein TEXT,
            licenseNumber TEXT,
            taxId TEXT,
            businessAddress TEXT,
            businessPhone TEXT,
            volumeDiscounts TEXT,
            minimumOrderValue REAL NOT NULL,
            preferredMaterials TEXT,
            rushServiceAllowed INTEGER NOT NULL,
            specialInstructions TEXT,
            accountManagerId TEXT,
            accountManagerName TEXT,
            accountExecutiveNotes TEXT,
            emailNotifications INTEGER NOT NULL,
            smsNotifications INTEGER NOT NULL,
            reportFrequency TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Analytics
  double get totalLifetimeValue =>
    _customers.fold(0, (sum, c) => sum + c.lifetimeValue);

  int get totalActiveAccounts =>
    _customers.where((c) => c.isActive).length;

  double get averageTransactionValue {
    final active = activeCustomers;
    if (active.isEmpty) return 0;
    final total = active.fold<double>(0, (sum, c) => sum + c.averageTransaction);
    return total / active.length;
  }

  // Load customers from local database
  Future<void> loadCustomers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _initDatabase();
      final maps = await _database!.query(_tableName);

      _customers = maps
        .map((map) => BusinessCustomer.fromJson(map))
        .toList();

      _customers.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new customer
  Future<BusinessCustomer?> createCustomer(BusinessCustomer customer) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _initDatabase();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newCustomer = customer.copyWith(
        id: id,
        lastActivity: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _database!.insert(_tableName, _customerToMap(newCustomer));

      _customers.insert(0, newCustomer);
      notifyListeners();

      return newCustomer;

    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating customer: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update customer
  Future<bool> updateCustomer(BusinessCustomer customer) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _initDatabase();
      final updatedCustomer = customer.copyWith(lastActivity: DateTime.now());

      final result = await _database!.update(
        _tableName,
        _customerToMap(updatedCustomer),
        where: 'id = ?',
        whereArgs: [customer.id],
      );

      if (result > 0) {
        final index = _customers.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          _customers[index] = updatedCustomer;
          _customers.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
          notifyListeners();
        }
        return true;
      }

      return false;

    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating customer: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete customer
  Future<bool> deleteCustomer(String customerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _initDatabase();
      final result = await _database!.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (result > 0) {
        _customers.removeWhere((c) => c.id == customerId);
        notifyListeners();
        return true;
      }

      return false;

    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting customer: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search and filter
  List<BusinessCustomer> searchCustomers(String query, {
    CustomerTier? tier,
    ContractStatus? status,
  }) {
    return _customers.where((customer) {
      final matchesQuery = query.isEmpty ||
        customer.companyName.toLowerCase().contains(query.toLowerCase()) ||
        customer.businessType.toLowerCase().contains(query.toLowerCase());

      final matchesTier = tier == null || customer.tier == tier;
      final matchesStatus = status == null || customer.contractStatus == status;

      return matchesQuery && matchesTier && matchesStatus;
    }).toList();
  }

  // Analytics methods
  Map<CustomerTier, int> get customerCountByTier {
    final map = <CustomerTier, int>{};

    for (final tier in CustomerTier.values) {
      map[tier] = _customers.where((c) => c.tier == tier && c.isActive).length;
    }

    return map;
  }

  Map<ContractStatus, int> get customerCountByStatus {
    final map = <ContractStatus, int>{};

    for (final status in ContractStatus.values) {
      map[status] = _customers.where((c) => c.contractStatus == status).length;
    }

    return map;
  }

  Map<String, int> get customerCountByBusinessType {
    final map = <String, int>{};

    for (final customer in _customers) {
      map[customer.businessType] = (map[customer.businessType] ?? 0) + 1;
    }

    return map;
  }

  List<BusinessCustomer> getTopCustomersByValue({int limit = 10}) {
    final sorted = List<BusinessCustomer>.from(
      _customers.where((c) => c.isActive)
    );
    sorted.sort((a, b) => b.lifetimeValue.compareTo(a.lifetimeValue));
    return sorted.take(limit).toList();
  }

  List<BusinessCustomer> getRecentActivity({int limit = 20}) {
    final sorted = List<BusinessCustomer>.from(_customers);
    sorted.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return sorted.take(limit).toList();
  }

  BusinessCustomer? getCustomerById(String id) {
    return _customers.cast<BusinessCustomer?>().firstWhere(
      (c) => c?.id == id,
      orElse: () => null,
    );
  }

  Map<String, dynamic> _customerToMap(BusinessCustomer customer) {
    return customer.toJson();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clean up
  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }
}
