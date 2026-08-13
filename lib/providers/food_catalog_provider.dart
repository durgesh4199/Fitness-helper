import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../models/indian_foods.dart';
import '../services/database_service.dart';

/// Summary of a CSV import, shown to the user before/after committing.
class ImportResult {
  final int added;
  final int updated;
  final int skippedBuiltIn;
  final List<String> errors; // per-row problems, capped for display

  const ImportResult({
    required this.added,
    required this.updated,
    required this.skippedBuiltIn,
    required this.errors,
  });

  int get totalRowsHandled => added + updated + skippedBuiltIn + errors.length;
}

class FoodCatalogProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<FoodItem> _customItems = [];
  bool _loading = true;

  bool get loading => _loading;
  List<FoodItem> get customItems => _customItems;

  /// Built-in reference foods plus anything the user imported/added.
  List<FoodItem> get allItems => [...IndianFoods.items, ..._customItems];

  /// Built-in categories plus any new category names introduced by custom
  /// foods (so imported items with an unfamiliar category still get a
  /// filter chip instead of disappearing into "Other").
  List<FoodCategory> get categories {
    final baseNames = IndianFoods.categories.map((c) => c.name.toLowerCase()).toSet();
    final extraNames = <String>{};
    final extra = <FoodCategory>[];
    for (final item in _customItems) {
      final key = item.category.toLowerCase();
      if (!baseNames.contains(key) && extraNames.add(key)) {
        extra.add(FoodCategory(item.category, IndianFoods.unknownCategory.icon, IndianFoods.unknownCategory.color));
      }
    }
    return [...IndianFoods.categories, ...extra];
  }

  Future<void> load() async {
    _customItems = await _db.getAllCustomFoods();
    _loading = false;
    notifyListeners();
  }

  Future<void> addCustomFood(FoodItem item) async {
    await _db.upsertCustomFood(item);
    await load();
  }

  Future<void> deleteCustomFood(int id) async {
    await _db.deleteCustomFood(id);
    _customItems = _customItems.where((f) => f.id != id).toList();
    notifyListeners();
  }

  /// Replaces all custom foods with [items] — used when restoring a backup.
  Future<void> restoreCustomFoods(List<FoodItem> items) async {
    await _db.clearAndInsertCustomFoods(items);
    await load();
  }

  // ---------------------------------------------------------------------------
  // CSV export / import
  // ---------------------------------------------------------------------------

  /// The full current catalog (built-ins + custom) as a CSV string, meant to
  /// be edited in a spreadsheet and re-imported.
  String exportCsv() {
    final rows = <List<Object>>[
      FoodItem.csvColumns,
      ...allItems.map((f) => f.toCsvRow()),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  bool _isBuiltIn(String name, String category) => IndianFoods.items.any(
        (f) => f.name.toLowerCase() == name.toLowerCase() && f.category.toLowerCase() == category.toLowerCase(),
      );

  double? _num(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.trim());
  }

  /// Parses [csvContent] and upserts valid rows as custom foods. Rows that
  /// exactly match a built-in food (by name + category) are skipped, since
  /// built-in nutrition data is compiled into the app and can't be edited.
  Future<ImportResult> importCsv(String csvContent) async {
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(csvContent.trim(), fieldDelimiter: ',');
    if (rows.isEmpty) {
      return const ImportResult(added: 0, updated: 0, skippedBuiltIn: 0, errors: ['File is empty.']);
    }

    final header = rows.first.map((h) => h.toString().trim().toLowerCase()).toList();
    final colIndex = <String, int>{
      for (final name in FoodItem.csvColumns) name.toLowerCase(): header.indexOf(name.toLowerCase()),
    };
    if (colIndex['name'] == -1 || colIndex['category'] == -1 || colIndex['calories'] == -1) {
      return const ImportResult(
        added: 0,
        updated: 0,
        skippedBuiltIn: 0,
        errors: ['Missing required columns. Expected at least: name, category, calories.'],
      );
    }

    String? cell(List<dynamic> row, String col) {
      final i = colIndex[col] ?? -1;
      if (i < 0 || i >= row.length) return null;
      return row[i]?.toString();
    }

    int added = 0, updated = 0, skippedBuiltIn = 0;
    final errors = <String>[];

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue; // blank line

      final name = cell(row, 'name')?.trim() ?? '';
      final category = cell(row, 'category')?.trim() ?? '';
      if (name.isEmpty || category.isEmpty) {
        if (errors.length < 10) errors.add('Row ${r + 1}: missing name or category.');
        continue;
      }

      final calories = _num(cell(row, 'calories'));
      if (calories == null) {
        if (errors.length < 10) errors.add('Row ${r + 1} ("$name"): calories must be a number.');
        continue;
      }

      if (_isBuiltIn(name, category)) {
        skippedBuiltIn++;
        continue;
      }

      final item = FoodItem(
        name: name,
        category: category,
        serving: cell(row, 'serving')?.trim().isNotEmpty == true ? cell(row, 'serving')!.trim() : '1 serving',
        calories: calories,
        protein: _num(cell(row, 'protein')) ?? 0,
        carbs: _num(cell(row, 'carbs')) ?? 0,
        fiber: _num(cell(row, 'fiber')) ?? 0,
        fat: _num(cell(row, 'fat')) ?? 0,
        sugar: _num(cell(row, 'sugar')) ?? 0,
        iron: _num(cell(row, 'iron')) ?? 0,
        calcium: _num(cell(row, 'calcium')) ?? 0,
        vitaminC: _num(cell(row, 'vitaminc')) ?? 0,
        caffeine: _num(cell(row, 'caffeine')) ?? 0,
        // Left null (unknown) rather than defaulted to 0 when the column is
        // missing or blank — these are optional, best-effort fields.
        magnesium: _num(cell(row, 'magnesium')),
        potassium: _num(cell(row, 'potassium')),
        zinc: _num(cell(row, 'zinc')),
      );

      final wasInsert = await _db.upsertCustomFood(item);
      if (wasInsert) {
        added++;
      } else {
        updated++;
      }
    }

    await load();
    return ImportResult(added: added, updated: updated, skippedBuiltIn: skippedBuiltIn, errors: errors);
  }
}
