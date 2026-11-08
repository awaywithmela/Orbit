class PlannerTask {
  const PlannerTask({
    required this.name,
    required this.dueDate,
    required this.priority,
    required this.category,
    required this.status,
    this.archivedAt,
    this.id,
  });

  final String? id;
  final String name;
  final DateTime dueDate;
  final String priority;
  final String category;
  final String status;
  final DateTime? archivedAt;

  bool get isOverdue {
    final today = DateTime.now();
    final dateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    return status != 'Done' &&
        status != 'Archived' &&
        dateOnly.isBefore(todayOnly);
  }

  bool get isDueToday {
    final today = DateTime.now();
    return dueDate.year == today.year &&
        dueDate.month == today.month &&
        dueDate.day == today.day;
  }

  PlannerTask copyWith({
    String? name,
    DateTime? dueDate,
    String? priority,
    String? category,
    String? status,
    DateTime? archivedAt,
  }) {
    return PlannerTask(
      name: name ?? this.name,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      status: status ?? this.status,
      archivedAt: archivedAt ?? this.archivedAt,
      id: id,
    );
  }
}

class ArchivedInboxItem {
  const ArchivedInboxItem({
    required this.text,
    required this.archivedAt,
    this.id,
  });

  final String? id;
  final String text;
  final DateTime archivedAt;
}

class MonthlyGoal {
  const MonthlyGoal({
    required this.text,
    required this.complete,
    this.targetAmount,
    this.id,
  });

  final String? id;
  final String text;
  final bool complete;
  final double? targetAmount;

  MonthlyGoal copyWith({String? text, bool? complete, double? targetAmount}) {
    return MonthlyGoal(
      text: text ?? this.text,
      complete: complete ?? this.complete,
      targetAmount: targetAmount ?? this.targetAmount,
      id: id,
    );
  }
}

class PlannerNote {
  const PlannerNote({required this.body, required this.createdAt, this.id});

  final String? id;
  final String body;
  final DateTime createdAt;
}

class MealNutrition {
  const MealNutrition({
    required this.serving,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.benefits,
  });

  final String serving;
  final double calories, protein, carbs, fat, fiber;
  final List<String> benefits;

  factory MealNutrition.fromJson(dynamic json) {
    if (json is! Map) throw const FormatException('Missing nutrition');
    double number(String key) {
      final value = json[key];
      if (value is! num || !value.isFinite || value < 0) {
        throw FormatException('Invalid $key');
      }
      return value.toDouble();
    }

    final serving = json['serving'];
    final benefits = json['benefits'];
    if (serving is! String ||
        serving.trim().isEmpty ||
        benefits is! List ||
        benefits.isEmpty ||
        benefits.any((v) => v is! String || v.trim().isEmpty)) {
      throw const FormatException('Missing serving or benefits');
    }
    return MealNutrition(
      serving: serving.trim(),
      calories: number('calories'),
      protein: number('protein_g'),
      carbs: number('carbs_g'),
      fat: number('fat_g'),
      fiber: number('fiber_g'),
      benefits: List<String>.from(benefits),
    );
  }

  Map<String, dynamic> toJson() => {
    'serving': serving,
    'calories': calories,
    'protein_g': protein,
    'carbs_g': carbs,
    'fat_g': fat,
    'fiber_g': fiber,
    'benefits': benefits,
  };
}

class DietMealPlan {
  const DietMealPlan({
    required this.title,
    required this.time,
    required this.focus,
    required this.foods,
    required this.notes,
    this.id,
    this.dayId,
    this.nutrition,
  });

  final String? id;
  final String? dayId;
  final String title;
  final String time;
  final String focus;
  final MealNutrition? nutrition;
  final String foods;
  final String notes;

  DietMealPlan copyWith({
    String? title,
    String? time,
    String? focus,
    String? foods,
    String? notes,
    MealNutrition? nutrition,
  }) {
    return DietMealPlan(
      title: title ?? this.title,
      time: time ?? this.time,
      focus: focus ?? this.focus,
      foods: foods ?? this.foods,
      notes: notes ?? this.notes,
      id: id,
      dayId: dayId,
      nutrition:
          nutrition ??
          ((foods != null && foods != this.foods) ||
                  (notes != null && notes != this.notes)
              ? null
              : this.nutrition),
    );
  }
}

class PlannerState {
  PlannerState({
    required this.tasks,
    required this.goals,
    required List<PlannerNote> notes,
    required Map<int, List<DietMealPlan>> dietPlans,
  }) : _notes = notes,
       _dietPlans = dietPlans;

  final List<PlannerTask> tasks;
  final List<MonthlyGoal> goals;
  // Nullable backing fields keep objects created before a hot reload safe when
  // the state shape changes. Fresh instances always receive a non-null list.
  final List<PlannerNote>? _notes;
  List<PlannerNote> get notes => _notes ?? const [];
  final Map<int, List<DietMealPlan>>? _dietPlans;

  Map<int, List<DietMealPlan>> get dietPlans => _dietPlans ?? const {};

  PlannerState copyWith({
    List<PlannerTask>? tasks,
    List<MonthlyGoal>? goals,
    List<PlannerNote>? notes,
    Map<int, List<DietMealPlan>>? dietPlans,
  }) {
    return PlannerState(
      tasks: tasks ?? this.tasks,
      goals: goals ?? this.goals,
      notes: notes ?? this.notes,
      dietPlans: dietPlans ?? this.dietPlans,
    );
  }

  static Map<int, List<DietMealPlan>> defaultDietPlans() {
    return const {};
  }
}
