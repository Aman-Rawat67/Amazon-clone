import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/deal_model.dart';
import '../models/product_section_model.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';

/// Provider for banner data
final bannersProvider = StreamProvider<List<BannerModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getBanners();
});

/// Provider for fetching active categories
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return FirestoreService().getCategoriesStream();
});

/// Provider for fetching active deals
final dealsProvider = StreamProvider<List<DealModel>>((ref) {
  return FirestoreService().getDealsStream();
});

/// Provider for home sections data
final homeSectionsProvider = StreamProvider<List<ProductSection>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProductSectionsStream();
});

/// Provider for search suggestions
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return FirestoreService().getSearchSuggestions(query);
});

/// Provider for cart item count
final cartCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(userProvider).asData?.value;
  if (user != null) {
    return FirestoreService().getCartItemCountStream(user.id);
  }
  return Stream.value(0);
}); 