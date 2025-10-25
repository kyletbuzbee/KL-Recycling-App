/// Repository for Weigh Flow Feature
/// Handles data persistence and network operations
/// TODO: Replace mock implementation with real database and API calls
library;

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ItemModel {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ItemModel({
    required this.id,
    required this.name,
    this.description,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}

class LabeledImageModel {
  final String id;
  final String imagePath;
  final double weight;
  final double? predictedWeight;
  final String? itemId;
  final DateTime createdAt;
  final bool isUploaded;
  final Map<String, dynamic>? metadata;

  LabeledImageModel({
    required this.id,
    required this.imagePath,
    required this.weight,
    this.predictedWeight,
    this.itemId,
    DateTime? createdAt,
    this.isUploaded = false,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'weight': weight,
      'predicted_weight': predictedWeight,
      'item_id': itemId,
      'created_at': createdAt.toIso8601String(),
      'is_uploaded': isUploaded ? 1 : 0,
      'metadata': jsonEncode(metadata ?? {}),
    };
  }

  factory LabeledImageModel.fromJson(Map<String, dynamic> json) {
    return LabeledImageModel(
      id: json['id'],
      imagePath: json['image_path'],
      weight: json['weight'],
      predictedWeight: json['predicted_weight'],
      itemId: json['item_id'],
      createdAt: DateTime.parse(json['created_at']),
      isUploaded: json['is_uploaded'] == 1,
      metadata: json['metadata'] != null ? jsonDecode(json['metadata']) : null,
    );
  }
}

class ItemRepository {
  static const String _itemsTable = 'items';
  static const String _labeledImagesTable = 'labeled_images';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'weigh_flow.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Items table
    await db.execute('''
      CREATE TABLE $_itemsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Labeled images table for offline queuing
    await db.execute('''
      CREATE TABLE $_labeledImagesTable (
        id TEXT PRIMARY KEY,
        image_path TEXT NOT NULL,
        weight REAL NOT NULL,
        predicted_weight REAL,
        item_id TEXT,
        created_at TEXT NOT NULL,
        is_uploaded INTEGER DEFAULT 0,
        metadata TEXT,
        FOREIGN KEY (item_id) REFERENCES $_itemsTable (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_labeled_images_uploaded ON $_labeledImagesTable(is_uploaded)');
    await db.execute('CREATE INDEX idx_labeled_images_created ON $_labeledImagesTable(created_at)');
  }

  // Item operations
  Future<ItemModel?> getItem(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        _itemsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return ItemModel.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      // TODO: Replace with proper logging
      print('Error getting item: $e');
      return null;
    }
  }

  Future<List<ItemModel>> getAllItems() async {
    try {
      final db = await database;
      final maps = await db.query(_itemsTable, orderBy: 'created_at DESC');

      return maps.map((map) => ItemModel.fromJson(map)).toList();
    } catch (e) {
      print('Error getting all items: $e');
      return [];
    }
  }

  Future<String> createItem(String name, {String? description}) async {
    try {
      final db = await database;
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final item = ItemModel(
        id: id,
        name: name,
        description: description,
      );

      await db.insert(_itemsTable, item.toJson());
      return id;
    } catch (e) {
      print('Error creating item: $e');
      throw Exception('Failed to create item');
    }
  }

  // Labeled image operations
  Future<String> submitLabeledImage(String imagePath, double weight, {double? predictedWeight, String? itemId}) async {
    try {
      final db = await database;
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final labeledImage = LabeledImageModel(
        id: id,
        imagePath: imagePath,
        weight: weight,
        predictedWeight: predictedWeight,
        itemId: itemId,
      );

      await db.insert(_labeledImagesTable, labeledImage.toJson());

      // TODO: Queue for background upload
      _queueForUpload(labeledImage);

      return id;
    } catch (e) {
      print('Error submitting labeled image: $e');
      throw Exception('Failed to submit labeled image');
    }
  }

  Future<List<LabeledImageModel>> getPendingUploads() async {
    try {
      final db = await database;
      final maps = await db.query(
        _labeledImagesTable,
        where: 'is_uploaded = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      return maps.map((map) => LabeledImageModel.fromJson(map)).toList();
    } catch (e) {
      print('Error getting pending uploads: $e');
      return [];
    }
  }

  Future<void> markAsUploaded(String id) async {
    try {
      final db = await database;
      await db.update(
        _labeledImagesTable,
        {'is_uploaded': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error marking as uploaded: $e');
    }
  }

  Future<List<LabeledImageModel>> getAllLabeledImages() async {
    try {
      final db = await database;
      final maps = await db.query(_labeledImagesTable, orderBy: 'created_at DESC');

      return maps.map((map) => LabeledImageModel.fromJson(map)).toList();
    } catch (e) {
      print('Error getting all labeled images: $e');
      return [];
    }
  }

  // Background upload simulation
  void _queueForUpload(LabeledImageModel labeledImage) {
    // TODO: Implement real background upload using WorkManager or similar
    // For now, just simulate queuing
    print('Queued for upload: ${labeledImage.id}');

    // Simulate async upload process
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        // TODO: Replace with real API call
        // await _uploadToServer(labeledImage);

        // Mark as uploaded in database
        await markAsUploaded(labeledImage.id);
        print('Upload completed: ${labeledImage.id}');
      } catch (e) {
        print('Upload failed: ${labeledImage.id}, error: $e');
        // TODO: Implement retry logic
      }
    });
  }

  // TODO: Implement real API upload
  Future<void> _uploadToServer(LabeledImageModel labeledImage) async {
    // TODO: Replace with actual HTTP request to training API
    // Example:
    // final response = await http.post(
    //   Uri.parse('https://api.klrecycling.com/training/submit-labeled-image'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'id': labeledImage.id,
    //     'image_path': labeledImage.imagePath,
    //     'weight': labeledImage.weight,
    //     'predicted_weight': labeledImage.predictedWeight,
    //     'item_id': labeledImage.itemId,
    //     'metadata': labeledImage.metadata,
    //   }),
    // );

    // if (response.statusCode != 200) {
    //   throw Exception('Upload failed: ${response.statusCode}');
    // }

    throw UnimplementedError('Real API upload not yet implemented');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
