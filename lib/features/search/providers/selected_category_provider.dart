import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/data/category_item.dart';

class SelectedCategoryNotifier extends Notifier<CategoryItem?> {
  @override
  CategoryItem? build() => null;

  void setCategory(CategoryItem? category) => state = category;
  void clear() => state = null;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, CategoryItem?>(
      SelectedCategoryNotifier.new,
    );
