import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/bioavailability.dart';
import '../models/calcium_bioavailability_analyzer.dart';
import '../models/iron_bioavailability_analyzer.dart';
import '../models/nutrition_targets.dart';
import '../models/protein_quality_analyzer.dart';
import '../models/zinc_bioavailability_analyzer.dart';
import '../providers/body_measurement_provider.dart';
import '../providers/health_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/workout_provider.dart';

/// Generates a plain, neutral PDF summary of the data already in the app —
/// useful to bring to a doctor's appointment as a quick reference, not a
/// substitute for one. Every figure here is either something the user
/// entered, something synced from Health Connect, or a plainly-labeled
/// average/estimate — never presented as a diagnosis or clinical reading.
class HealthReportService {
  HealthReportService._();

  static const _disclaimer =
      'This summary reflects self-reported and device-synced data from the Fitness Tracker app. '
      'It is not a medical record, diagnosis, or clinical measurement. Consider discussing it with '
      'a qualified healthcare professional.';

  static Future<void> shareReport({
    required UserProvider user,
    required WeightProvider weight,
    required BodyMeasurementProvider bodyMeasurements,
    required WorkoutProvider workouts,
    required NutritionProvider nutrition,
    required HealthProvider health,
  }) async {
    final doc = pw.Document();
    final targets = NutritionTargets.forUser(user);
    final now = DateTime.now();

    // 7-day nutrition average — includes days with nothing logged, so this
    // is a straightforward "per day over the last week" figure, not an
    // average-of-only-logged-days number.
    double calSum = 0, proteinSum = 0, carbsSum = 0, fiberSum = 0, sugarSum = 0;
    for (var i = 0; i < 7; i++) {
      final t = nutrition.totalsForDate(now.subtract(Duration(days: i)));
      calSum += t.calories;
      proteinSum += t.protein;
      carbsSum += t.carbs;
      fiberSum += t.fiber;
      sugarSum += t.sugar;
    }

    // Today's nutrient bioavailability context — the same estimates shown
    // on the Diet screen's per-day card, run once here for the export.
    // Omitted entirely below if there's nothing to show yet.
    final todayContext = MealContextBuilder.build(nutrition.todayLogs);
    final bioavailabilityEstimates = [
      IronBioavailabilityAnalyzer.analyze(todayContext),
      ProteinQualityAnalyzer.analyze(todayContext),
      ZincBioavailabilityAnalyzer.analyze(todayContext),
      CalciumBioavailabilityAnalyzer.analyze(todayContext),
    ].whereType<BioavailabilityEstimate>().toList();

    String fmt1(double? v, String unit) => v == null ? '--' : '${v.toStringAsFixed(1)} $unit';
    String fmtChange(double? v, String unit) {
      if (v == null) return '--';
      final sign = v > 0 ? '+' : '';
      return '$sign${v.toStringAsFixed(1)} $unit';
    }

    pw.Widget sectionTitle(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        );

    pw.Widget row(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text('Fitness Tracker — Health Summary', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Generated ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text(_disclaimer, style: const pw.TextStyle(fontSize: 9.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
          ),
          sectionTitle('Profile'),
          row('Name', user.name),
          row('Age', '${user.age}'),
          row('Sex', user.sex.name),
          row('Height', fmt1(user.heightCm, 'cm')),
          row('Current weight (self-reported)', fmt1(user.weightKg, 'kg')),
          row('BMI', '${user.bmi.toStringAsFixed(1)} (${user.bmiCategory})'),
          if (user.isDiabetic) row('Diabetic mode', 'Enabled'),
          sectionTitle('Weight & Body Measurements'),
          row('Latest logged weight', fmt1(weight.currentWeightKg, 'kg')),
          row('7-day average', fmt1(weight.sevenDayAverage, 'kg')),
          row('30-day average', fmt1(weight.thirtyDayAverage, 'kg')),
          row('7-day change', fmtChange(weight.weeklyChange, 'kg')),
          row('30-day change', fmtChange(weight.changeOverDays(30), 'kg')),
          if (bodyMeasurements.currentWaistCm != null) ...[
            row('Latest waist measurement', fmt1(bodyMeasurements.currentWaistCm, 'cm')),
            row('Waist 7-day change', fmtChange(bodyMeasurements.waistWeeklyChange, 'cm')),
          ],
          sectionTitle('Activity (this week)'),
          row('Workouts logged', '${workouts.weekWorkoutCount}'),
          row('Active minutes', '${workouts.weekMinutes} min'),
          row('Calories burned (logged workouts)', '${workouts.weekCalories} kcal'),
          row('Current day streak', '${workouts.streakDays} day(s)'),
          if (workouts.weekTrainingLoad != null) row('Training load (minutes x RPE)', '${workouts.weekTrainingLoad}'),
          sectionTitle('Nutrition (7-day daily average)'),
          row('Calories', '${(calSum / 7).round()} kcal  (target ${targets.calories} kcal)'),
          row('Protein', '${(proteinSum / 7).round()} g  (target ${targets.protein} g)'),
          row('Carbohydrates', '${(carbsSum / 7).round()} g'),
          row('Fiber', '${(fiberSum / 7).round()} g  (target ${targets.fiber} g)'),
          row('Sugar', '${(sugarSum / 7).round()} g'),
          if (bioavailabilityEstimates.isNotEmpty) ...[
            sectionTitle('Nutrient Bioavailability Context (Today)'),
            pw.Text(
              'A context-favorability estimate, not a measured absorption amount — see each row\'s '
              'evidence confidence. Based on what was logged today.',
              style: const pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            for (final e in bioavailabilityEstimates)
              row('${e.nutrient} (confidence: ${e.confidence.label.toLowerCase()})', e.level.label),
          ],
          sectionTitle('Recent Vitals (from Health Connect, if synced)'),
          row('Steps today', health.steps?.toString() ?? 'Not available'),
          row('7-day average daily steps', health.averageDailySteps == null ? 'Not available' : health.averageDailySteps!.round().toString()),
          row('Heart rate (today, average)', health.heartRate == null ? 'Not available' : '${health.heartRate!.round()} bpm'),
          row('Sleep (today)', health.sleepLabel),
          pw.SizedBox(height: 20),
          pw.Text(_disclaimer, style: const pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final stamp = now.toIso8601String().split('T').first;
    final file = File('${dir.path}/fitness_tracker_health_summary_$stamp.pdf');
    await file.writeAsBytes(await doc.save());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Fitness Tracker health summary',
      text: 'A summary of your logged fitness/nutrition data — handy to bring to an appointment. '
          'Not a medical record.',
    );
  }
}
