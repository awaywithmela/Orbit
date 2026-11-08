import 'package:flutter/material.dart';
import '../../domain/planner_models.dart';

class MealNutritionDetails extends StatelessWidget {
  const MealNutritionDetails({super.key, required this.nutrition});
  final MealNutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final n = nutrition;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text('≈ ${n.calories.round()} kcal / serving'),
      subtitle: const Text('Nutrition & body benefits'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assumed serving: ${n.serving}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final entry in {
                    'Protein': n.protein,
                    'Carbs': n.carbs,
                    'Fat': n.fat,
                    'Fiber': n.fiber,
                  }.entries)
                    Chip(label: Text('${entry.key} ${entry.value.round()} g')),
                ],
              ),
              const SizedBox(height: 8),
              for (final benefit in n.benefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $benefit'),
                ),
              const Text(
                'Calories measure the energy food provides. Eating twice this serving gives roughly twice the calories and nutrients.',
              ),
              const SizedBox(height: 8),
              Text(
                'AI estimates, not measured values. Portions, ingredients, and preparation change these numbers.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
