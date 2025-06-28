import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_section_model.dart';
import '../services/firestore_service.dart';
import 'product_provider.dart';

/// Provider for product sections using Stream
final productSectionsStreamProvider = StreamProvider<List<ProductSection>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProductSectionsStream();
});

/// Provider for product sections using Future (alternative to stream)
final productSectionsFutureProvider = FutureProvider<List<ProductSection>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getProductSections();
});

/// State notifier for product section management (admin functions)
final productSectionProvider = StateNotifierProvider<ProductSectionNotifier, AsyncValue<List<ProductSection>>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ProductSectionNotifier(firestoreService);
});

/// State notifier for product section management
class ProductSectionNotifier extends StateNotifier<AsyncValue<List<ProductSection>>> {
  final FirestoreService _firestoreService;

  ProductSectionNotifier(this._firestoreService) : super(const AsyncValue.loading()) {
    loadProductSections();
  }

  /// Load product sections
  Future<void> loadProductSections({bool refresh = false}) async {
    try {
      if (refresh) {
        state = const AsyncValue.loading();
      }

      final sections = await _firestoreService.getProductSections();
      state = AsyncValue.data(sections);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Create a new product section (admin only)
  Future<String> createProductSection(ProductSection section) async {
    try {
      final sectionId = await _firestoreService.createProductSection(section);
      
      // Reload sections to include the new one
      await loadProductSections(refresh: true);
      
      return sectionId;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update an existing product section (admin only)
  Future<void> updateProductSection(String sectionId, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateProductSection(sectionId, data);
      
      // Update the section in the current state
      state.whenData((sections) {
        final updatedSections = sections.map((section) {
          if (section.id == sectionId) {
            return section.copyWith(
              title: data['title'] ?? section.title,
              subtitle: data['subtitle'] ?? section.subtitle,
              seeMoreText: data['seeMoreText'] ?? section.seeMoreText,
              seeMoreRoute: data['seeMoreRoute'] ?? section.seeMoreRoute,
              displayCount: data['displayCount'] ?? section.displayCount,
              imageUrl: data['imageUrl'] ?? section.imageUrl,
              isActive: data['isActive'] ?? section.isActive,
              order: data['order'] ?? section.order,
              updatedAt: DateTime.now(),
              metadata: data['metadata'] ?? section.metadata,
            );
          }
          return section;
        }).toList();
        
        state = AsyncValue.data(updatedSections);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Delete a product section (admin only)
  Future<void> deleteProductSection(String sectionId) async {
    try {
      await _firestoreService.deleteProductSection(sectionId);
      
      // Remove the section from the current state
      state.whenData((sections) {
        final updatedSections = sections.where((section) => section.id != sectionId).toList();
        state = AsyncValue.data(updatedSections);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Toggle section active status (admin only)
  Future<void> toggleSectionStatus(String sectionId, bool isActive) async {
    try {
      await updateProductSection(sectionId, {'isActive': isActive});
    } catch (e) {
      rethrow;
    }
  }

  /// Reorder sections (admin only)
  Future<void> reorderSections(List<ProductSection> sections) async {
    try {
      // Update order for each section
      for (int i = 0; i < sections.length; i++) {
        await _firestoreService.updateProductSection(sections[i].id, {'order': i});
      }
      
      // Reload sections with new order
      await loadProductSections(refresh: true);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Create demo product sections for testing (admin only)
  Future<void> createDemoProductSections() async {
    try {
      await _firestoreService.createDemoProductSections();
      
      // Reload sections to include the new demo sections
      await loadProductSections(refresh: true);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

/// Provider for a specific product section by ID
final productSectionByIdProvider = FutureProvider.family<ProductSection?, String>((ref, sectionId) async {
  final sections = await ref.watch(productSectionsFutureProvider.future);
  return sections.firstWhere(
    (section) => section.id == sectionId,
    orElse: () => throw Exception('Section not found'),
  );
}); 