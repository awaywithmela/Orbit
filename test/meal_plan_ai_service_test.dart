import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:orbit/core/ai/meal_plan_ai_service.dart';

const _request = MealPlanAiRequest(
  dayName: 'Monday',
  goal: 'Balanced energy',
  dietaryPreference: 'No preference',
  allergies: 'None',
  budgetStyle: 'Budget friendly',
  mealCount: 2,
);

void main() {
  test('serializes the meal planner request', () {
    expect(_request.toJson(), {
      'day_name': 'Monday',
      'goal': 'Balanced energy',
      'dietary_preference': 'No preference',
      'allergies': 'None',
      'budget_style': 'Budget friendly',
      'meal_count': 2,
    });
  });

  test('rejects unsupported meal counts before making a request', () async {
    const invalidRequest = MealPlanAiRequest(
      dayName: 'Monday',
      goal: 'Balanced energy',
      dietaryPreference: 'No preference',
      allergies: 'None',
      budgetStyle: 'Budget friendly',
      mealCount: 6,
    );

    await expectLater(
      const MealPlanAiService().generate(invalidRequest),
      throwsA(isA<MealPlanAiException>()),
    );
  });

  test('uses OpenRouter and parses a complete meal plan', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'openrouter.ai');
      expect(request.headers['Authorization'], 'Bearer test-key');
      final payload = jsonDecode(request.body);
      expect(payload['model'], MealPlanAiService.model);
      expect(payload['stream'], isFalse);
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'finish_reason': 'stop',
              'message': {
                'content': jsonEncode({
                  'meals': List.generate(
                    2,
                    (index) => {
                      'title': 'Meal $index',
                      'time': '12:00',
                      'focus': 'Balanced',
                      'foods': 'Rice and vegetables',
                      'notes': 'Adjust portions',
                      'nutrition': {
                        'serving': '1 bowl: 150 g rice, 100 g vegetables',
                        'calories': 250,
                        'protein_g': 6,
                        'carbs_g': 48,
                        'fat_g': 4,
                        'fiber_g': 5,
                        'benefits': ['Fiber supports digestion.'],
                      },
                    },
                  ),
                }),
              },
            },
          ],
        }),
        200,
      );
    });
    final meals = await MealPlanAiService(
      client: client,
      apiKey: 'test-key',
    ).generate(_request);
    expect(meals.length, 2);
    expect(meals.first.title, 'Meal 0');
    expect(meals.first.nutrition!.calories, 250);
  });

  for (final status in [401, 403, 429, 503]) {
    test('handles HTTP $status without exposing provider responses', () async {
      final client = MockClient(
        (_) async => http.Response('private-provider-details', status),
      );
      await expectLater(
        MealPlanAiService(
          client: client,
          apiKey: 'test-key',
        ).generate(_request),
        throwsA(
          isA<MealPlanAiException>().having(
            (e) => e.message,
            'safe error',
            isNot(contains('private-provider-details')),
          ),
        ),
      );
    });
  }

  for (final response in [
    'not json',
    '{}',
    jsonEncode({'choices': []}),
    jsonEncode({
      'error': {'message': 'error'},
    }),
    jsonEncode({
      'choices': [
        {
          'finish_reason': 'length',
          'message': {'content': '{}'},
        },
      ],
    }),
    jsonEncode({
      'choices': [
        {
          'finish_reason': 'stop',
          'message': {'content': '{"meals":[]}'},
        },
      ],
    }),
    jsonEncode({
      'choices': [
        {
          'finish_reason': 'stop',
          'message': {'content': '{"meals":[{},{}]}'},
        },
      ],
    }),
  ]) {
    test('rejects malformed or incomplete response $response', () async {
      final client = MockClient((_) async => http.Response(response, 200));
      await expectLater(
        MealPlanAiService(
          client: client,
          apiKey: 'test-key',
        ).generate(_request),
        throwsA(isA<MealPlanAiException>()),
      );
    });
  }

  test('handles connection failures', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('network failed'),
    );
    await expectLater(
      MealPlanAiService(client: client, apiKey: 'test-key').generate(_request),
      throwsA(isA<MealPlanAiException>()),
    );
  });

  test('handles request timeouts', () async {
    final client = MockClient((_) async => throw TimeoutException('timeout'));
    await expectLater(
      MealPlanAiService(client: client, apiKey: 'test-key').generate(_request),
      throwsA(isA<MealPlanAiException>()),
    );
  });
}
