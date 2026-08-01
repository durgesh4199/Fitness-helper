import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/indian_foods.dart';
import '../providers/food_catalog_provider.dart';
import '../theme/app_theme.dart';

class ManageFoodListScreen extends StatefulWidget {
  const ManageFoodListScreen({super.key});

  @override
  State<ManageFoodListScreen> createState() => _ManageFoodListScreenState();
}

class _ManageFoodListScreenState extends State<ManageFoodListScreen> {
  bool _busy = false;

  Future<void> _export(FoodCatalogProvider catalog) async {
    setState(() => _busy = true);
    try {
      final csv = catalog.exportCsv();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fitness_tracker_foods.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Fitness Tracker food list',
        text: 'Your Fitness Tracker food list (${catalog.allItems.length} items). '
            'Edit in a spreadsheet, add new rows, then re-import.',
      );
    } catch (e) {
      if (mounted) _showMessage('Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(FoodCatalogProvider catalog) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    String? content;
    try {
      if (picked.bytes != null) {
        content = utf8.decode(picked.bytes!, allowMalformed: true);
      } else if (picked.path != null) {
        content = await File(picked.path!).readAsString();
      }
    } catch (e) {
      _showMessage('Could not read file: $e');
      return;
    }
    if (content == null || content.trim().isEmpty) {
      _showMessage('That file appears to be empty.');
      return;
    }

    setState(() => _busy = true);
    final importResult = await catalog.importCsv(content);
    if (!mounted) return;
    setState(() => _busy = false);
    _showImportSummary(importResult);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showImportSummary(ImportResult result) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Import complete', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryLine(colors, Icons.add_circle_outline_rounded, AppBrand.fiber, '${result.added} new food${result.added == 1 ? '' : 's'} added'),
              _summaryLine(colors, Icons.edit_outlined, colors.primary, '${result.updated} existing custom food${result.updated == 1 ? '' : 's'} updated'),
              if (result.skippedBuiltIn > 0)
                _summaryLine(colors, Icons.info_outline_rounded, colors.textSecondary,
                    '${result.skippedBuiltIn} row${result.skippedBuiltIn == 1 ? '' : 's'} skipped (already built-in)'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Rows with problems:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 6),
                ...result.errors.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $e', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Done', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(AppPalette colors, IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13.5, color: colors.textPrimary))),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(FoodCatalogProvider catalog, int id, String name) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Remove "$name"?', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text('This only removes it from your food list — past logged entries are unaffected.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await catalog.deleteCustomFood(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final catalog = context.watch<FoodCatalogProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Manage food list')),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: Opacity(
            opacity: _busy ? 0.5 : 1,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.cardBorder),
                    boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${IndianFoods.items.length + catalog.customItems.length} foods in your list',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        '${IndianFoods.items.length} built-in · ${catalog.customItems.length} added by you',
                        style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ActionTile(
                  icon: Icons.ios_share_rounded,
                  color: colors.primary,
                  title: 'Export food list',
                  subtitle: 'Share a CSV with every food — edit it in a spreadsheet',
                  onTap: () => _export(catalog),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.file_upload_outlined,
                  color: AppBrand.secondary,
                  title: 'Import from CSV',
                  subtitle: 'Add new rows from an edited file back into the app',
                  onTap: () => _import(catalog),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Columns: name, category, serving, calories, protein, carbs, fiber, fat, sugar, iron, calcium, vitaminC, caffeine. '
                          'Export first to get the exact format, then add rows below the existing ones.',
                          style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (catalog.customItems.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Your added foods', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                  const SizedBox(height: 12),
                  ...catalog.customItems.map(
                    (food) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: IndianFoods.colorFor(food.category).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(IndianFoods.iconFor(food.category), color: IndianFoods.colorFor(food.category), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(food.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                                  Text('${food.category} · ${food.calories.round()} kcal',
                                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _confirmDelete(catalog, food.id!, food.name),
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
