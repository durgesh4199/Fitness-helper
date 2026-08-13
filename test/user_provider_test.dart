import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/providers/user_provider.dart';

void main() {
  group('UserProvider.bmi', () {
    test('computes BMI from height/weight and buckets into a category', () async {
      SharedPreferences.setMockInitialValues({});
      final user = UserProvider();
      await user.load();
      await user.updateProfile(heightCm: 180, weightKg: 90);

      expect(user.bmi, closeTo(90 / (1.8 * 1.8), 0.01));
      expect(user.bmiCategory, 'Overweight');
    });

    test('a low BMI is categorized as Underweight', () async {
      SharedPreferences.setMockInitialValues({});
      final user = UserProvider();
      await user.load();
      await user.updateProfile(heightCm: 180, weightKg: 50);

      expect(user.bmiCategory, 'Underweight');
    });
  });
}
