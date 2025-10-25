import 'package:flutter_test/flutter_test.dart';
import 'package:kl_recycling_app/cline_generated/weigh-flow/repository.dart';

void main() {
  group('ItemRepository Tests', () {
    late ItemRepository repository;

    setUp(() async {
      repository = ItemRepository();
      // Initialize database
      await repository.database;
    });

    tearDown(() async {
      await repository.close();
    });

    test('ItemRepository creates and retrieves items', () async {
      // Create an item
      const itemName = 'Test Scrap Metal';
      const itemDescription = 'Test description';
      final itemId = await repository.createItem(itemName, description: itemDescription);

      expect(itemId, isNotEmpty);

      // Retrieve the item
      final retrievedItem = await repository.getItem(itemId);

      expect(retrievedItem, isNotNull);
      expect(retrievedItem!.name, equals(itemName));
      expect(retrievedItem.description, equals(itemDescription));
      expect(retrievedItem.id, equals(itemId));
    });

    test('ItemRepository retrieves all items', () async {
      // Create multiple items
      await repository.createItem('Item 1');
      await repository.createItem('Item 2');
      await repository.createItem('Item 3');

      final allItems = await repository.getAllItems();

      expect(allItems.length, greaterThanOrEqualTo(3));
      expect(allItems.any((item) => item.name == 'Item 1'), isTrue);
      expect(allItems.any((item) => item.name == 'Item 2'), isTrue);
      expect(allItems.any((item) => item.name == 'Item 3'), isTrue);
    });

    test('ItemRepository handles non-existent item', () async {
      const nonExistentId = 'non-existent-id';
      final item = await repository.getItem(nonExistentId);

      expect(item, isNull);
    });

    test('ItemRepository submits labeled images', () async {
      const testWeight = 15.5;
      const testImagePath = '/test/path/image.jpg';

      final submissionId = await repository.submitLabeledImage(
        testImagePath,
        testWeight,
      );

      expect(submissionId, isNotEmpty);

      // Verify the submission was stored
      final allSubmissions = await repository.getAllLabeledImages();
      expect(allSubmissions.length, greaterThanOrEqualTo(1));

      final submission = allSubmissions.firstWhere(
        (s) => s.id == submissionId,
      );

      expect(submission.imagePath, equals(testImagePath));
      expect(submission.weight, equals(testWeight));
      expect(submission.isUploaded, isFalse); // Should not be uploaded initially
    });

    test('ItemRepository submits labeled images with predictions', () async {
      const testWeight = 20.0;
      const predictedWeight = 18.5;
      const testImagePath = '/test/path/predicted_image.jpg';

      final submissionId = await repository.submitLabeledImage(
        testImagePath,
        testWeight,
        predictedWeight: predictedWeight,
      );

      expect(submissionId, isNotEmpty);

      final allSubmissions = await repository.getAllLabeledImages();
      final submission = allSubmissions.firstWhere(
        (s) => s.id == submissionId,
      );

      expect(submission.predictedWeight, equals(predictedWeight));
      expect(submission.weight, equals(testWeight));
    });

    test('ItemRepository submits labeled images with item association', () async {
      // Create an item first
      const itemName = 'Associated Item';
      final itemId = await repository.createItem(itemName);

      const testWeight = 25.0;
      const testImagePath = '/test/path/associated_image.jpg';

      final submissionId = await repository.submitLabeledImage(
        testImagePath,
        testWeight,
        itemId: itemId,
      );

      expect(submissionId, isNotEmpty);

      final allSubmissions = await repository.getAllLabeledImages();
      final submission = allSubmissions.firstWhere(
        (s) => s.id == submissionId,
      );

      expect(submission.itemId, equals(itemId));
    });

    test('ItemRepository retrieves pending uploads', () async {
      // Submit some labeled images
      await repository.submitLabeledImage('/test/path/1.jpg', 10.0);
      await repository.submitLabeledImage('/test/path/2.jpg', 15.0);
      await repository.submitLabeledImage('/test/path/3.jpg', 20.0);

      final pendingUploads = await repository.getPendingUploads();

      expect(pendingUploads.length, greaterThanOrEqualTo(3));
      for (var upload in pendingUploads) {
        expect(upload.isUploaded, isFalse);
      }
    });

    test('ItemRepository marks uploads as completed', () async {
      // Submit a labeled image
      const testWeight = 12.0;
      const testImagePath = '/test/path/mark_uploaded.jpg';

      final submissionId = await repository.submitLabeledImage(
        testImagePath,
        testWeight,
      );

      // Mark as uploaded
      await repository.markAsUploaded(submissionId);

      // Verify it's marked as uploaded
      final allSubmissions = await repository.getAllLabeledImages();
      final submission = allSubmissions.firstWhere(
        (s) => s.id == submissionId,
      );

      expect(submission.isUploaded, isTrue);
    });

    test('ItemRepository handles submission errors gracefully', () async {
      // Test with invalid data
      expect(
        () async => await repository.submitLabeledImage('', 0),
        throwsA(isA<Exception>()),
      );
    });

    test('ItemRepository creates items with timestamps', () async {
      const itemName = 'Timestamp Test Item';
      final beforeCreation = DateTime.now();

      final itemId = await repository.createItem(itemName);

      final afterCreation = DateTime.now();
      final retrievedItem = await repository.getItem(itemId);

      expect(retrievedItem, isNotNull);
      expect(retrievedItem!.createdAt.isAfter(beforeCreation), isTrue);
      expect(retrievedItem.createdAt.isBefore(afterCreation), isTrue);
    });

    test('ItemRepository handles concurrent operations', () async {
      // Test concurrent item creation
      final futures = List.generate(10, (index) async {
        return await repository.createItem('Concurrent Item $index');
      });

      final itemIds = await Future.wait(futures);

      expect(itemIds.length, equals(10));
      expect(itemIds.toSet().length, equals(10)); // All IDs should be unique

      // Verify all items were created
      final allItems = await repository.getAllItems();
      expect(allItems.length, greaterThanOrEqualTo(10));
    });
  });
}
