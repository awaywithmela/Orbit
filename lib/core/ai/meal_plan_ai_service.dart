import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../../features/orbit/domain/planner_models.dart';

class MealPlanAiException implements Exception {
  const MealPlanAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MealPlanAiRequest {
  const MealPlanAiRequest({
    required this.dayName,
    required this.goal,
    required this.dietaryPreference,
    required this.allergies,
    required this.budgetStyle,
    required this.mealCount,
  });

  final String dayName;
  final String goal;
  final String dietaryPreference;
  final String allergies;
  final String budgetStyle;
  final int mealCount;

  Map<String, dynamic> toJson() => {
    'day_name': dayName,
    'goal': goal,
    'dietary_preference': dietaryPreference,
    'allergies': allergies,
    'budget_style': budgetStyle,
    'meal_count': mealCount,
  };
}

class MealPlanAiService {
  const MealPlanAiService({this.client, this.apiKey});

  final http.Client? client;
  final String? apiKey;
  static const model = 'nvidia/nemotron-3-ultra-550b-a55b:free';

  Future<List<DietMealPlan>> generate(MealPlanAiRequest request) async {
    if (request.mealCount < 2 || request.mealCount > 5) {
      throw const MealPlanAiException('Meal count must be between 2 and 5.');
    }
    final data = await _request(
      'Create practical meal ideas. Return JSON with a meals array of exactly the requested meal_count. Each meal must contain non-empty strings title, time, focus, foods, notes, and a nutrition object. Respect allergies and dietary preferences. $_nutritionInstructions',
      request.toJson(),
    );
    return _parseMeals(data, request.mealCount);
  }

  static const _nutritionInstructions =
      'Nutrition must contain serving (a string listing assumed ingredient quantities for one serving), calories (kcal), protein_g, carbs_g, fat_g, fiber_g (all nonnegative numbers), and benefits (2 to 3 short strings naming a nutrient present in the ingredients and its general function in the body). These are approximate estimates, not verified nutrition analysis. Use realistic portions and internally consistent calories and macros. Do not claim treatment, prevention, or guaranteed health outcomes.';

  Future<MealNutrition> estimateNutrition(DietMealPlan meal) async {
    final data = await _request(
      'Estimate nutrition for this existing meal without changing it. Return JSON with a nutrition object. $_nutritionInstructions',
      {'title': meal.title, 'foods': meal.foods, 'notes': meal.notes},
    );
    try {
      return MealNutrition.fromJson(data['nutrition']);
    } on FormatException {
      throw const MealPlanAiException(
        'The nutrition estimate was incomplete. Please try again.',
      );
    }
  }

  Future<Map> _request(String instructions, Map<String, dynamic> input) async {
    // A shared provider secret must never be shipped in a store build.
    if (kReleaseMode) {
      throw const MealPlanAiException(
        'AI meal ideas are not available in this version. You can still add meals manually.',
      );
    }
    final key = apiKey ?? const String.fromEnvironment('OPENROUTER_API_KEY');
    if (key.isEmpty) {
      throw const MealPlanAiException(
        'AI meal ideas are not configured. You can still add meals manually.',
      );
    }
    final connection = client ?? http.Client();
    try {
      final response = await connection
          .post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              // The UI reviews a complete plan before saving, so no SSE parsing is needed.
              'stream': false,
              'max_tokens': 6500,
              'response_format': {'type': 'json_object'},
              'messages': [
                {'role': 'system', 'content': instructions},
                {'role': 'user', 'content': jsonEncode(input)},
              ],
            }),
          )
          .timeout(const Duration(seconds: 90));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const MealPlanAiException(
          'The AI service could not authorize this request. Please check its configuration.',
        );
      }
      if (response.statusCode == 429) {
        throw const MealPlanAiException(
          'The AI service is busy or its free limit has been reached. Try again later.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const MealPlanAiException(
          'The AI service is temporarily unavailable. Try again later.',
        );
      }
      return _parseResponse(response.body);
    } on TimeoutException {
      throw const MealPlanAiException(
        'Meal ideas took too long. Please try again.',
      );
    } on http.ClientException {
      throw const MealPlanAiException(
        'Could not reach the AI service. Check your internet connection.',
      );
    } finally {
      if (client == null) connection.close();
    }
  }

  Map _parseResponse(String response) {
    const invalid = MealPlanAiException(
      'The AI returned an incomplete meal plan. Please try again.',
    );
    try {
      final body = jsonDecode(response);
      if (body is! Map || body['error'] != null) throw invalid;
      final choices = body['choices'];
      if (choices is! List || choices.isEmpty || choices.first is! Map) {
        throw invalid;
      }
      final choice = choices.first as Map;
      if (choice['finish_reason'] != 'stop') throw invalid;
      final message = choice['message'];
      if (message is! Map || message['content'] is! String) throw invalid;
      final data = jsonDecode(message['content'] as String);
      if (data is! Map) throw invalid;
      return data;
    } on FormatException {
      throw invalid;
    }
  }

  List<DietMealPlan> _parseMeals(Map data, int count) {
    const invalid = MealPlanAiException(
      'The AI returned an incomplete meal plan. Please try again.',
    );
    try {
      final meals = data['meals'];
      if (meals is! List || meals.length != count) throw invalid;
      return meals.map((meal) {
        if (meal is! Map) throw invalid;
        String field(String name) {
          final value = meal[name];
          if (value is! String || value.trim().isEmpty) throw invalid;
          return value.trim();
        }

        return DietMealPlan(
          title: field('title'),
          time: field('time'),
          focus: field('focus'),
          foods: field('foods'),
          notes: field('notes'),
          nutrition: MealNutrition.fromJson(meal['nutrition']),
        );
      }).toList();
    } on FormatException {
      throw invalid;
    }
  }
}
