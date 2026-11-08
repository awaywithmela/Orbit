import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_database.dart';
import 'feature_walkthrough.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../orbit/application/orbit_controller.dart';
import '../../orbit/domain/app_tab.dart';

class FeatureGuide {
  const FeatureGuide(this.title, this.icon, this.tab, this.steps);
  final String title;
  final IconData icon;
  final AppTab tab;
  final List<(String, String)> steps;
}

const featureGuides = [
  FeatureGuide('Today & focus', Icons.wb_sunny_outlined, AppTab.today, [
    (
      'Add one task',
      'Tap + at the top of Today. Give your task a name and save it.',
    ),
    (
      'Start small',
      'Your next task appears in Do next. Tap Start focus, or use the snooze icon for a 10-minute pause.',
    ),
    (
      'Review your day',
      'Tap a timeline task to view its details, edit it, or archive it. Use Organize to adjust your view.',
    ),
  ]),
  FeatureGuide('Brain dump & resets', Icons.self_improvement_rounded, AppTab.today, [
    (
      'Capture a thought',
      'Scroll to Brain Dump and tap Capture. Save anything you want to get out of your head.',
    ),
    (
      'Clear some space',
      'Archive a thought when you no longer need it here. Find it again in Me → Archive.',
    ),
    (
      'Take a breath',
      'Tap Start on Breathe And Choose One Task. Follow the reset, then return to one small task.',
    ),
    (
      'Check reminders',
      'Tap the bell at the top of Today to see your reminders.',
    ),
  ]),
  FeatureGuide('Tasks & priorities', Icons.checklist_rounded, AppTab.plan, [
    (
      'Make a plan',
      'Tap Task in Planner & Goals. Choose a deadline, priority, category, and status.',
    ),
    (
      'Move it forward',
      'Change a task’s status from To Do to In Progress, then Done. Tap a task to inspect or edit it.',
    ),
    (
      'Keep it manageable',
      'Scroll to Show Only Top 3 and tap Show 3. Tap Show All when you want the full schedule again.',
    ),
  ]),
  FeatureGuide('Goals, notes & breaks', Icons.flag_outlined, AppTab.plan, [
    (
      'Choose a monthly goal',
      'Tap Goal, write a small target, and save it. Check it off when complete; use the edit icon to change it.',
    ),
    (
      'Save a note',
      'Find Notes, type a thought, and tap Add note. Use a note’s delete icon to remove it.',
    ),
    (
      'Make room to rest',
      'Tap Add Breaks to add rest blocks after schedule tasks lasting at least 25 minutes.',
    ),
    (
      'Try a focus session',
      'Tap Start Session in Focus Session Guide for instructions on working quietly alongside someone.',
    ),
  ]),
  FeatureGuide(
    'Wallets & expenses',
    Icons.account_balance_wallet_outlined,
    AppTab.expenses,
    [
      (
        'Create a wallet',
        'Tap New Wallet. Name your bank or cash wallet and enter its starting balance. This is manual tracking, not a bank connection.',
      ),
      (
        'Add a category',
        'Tap New Category and choose a name and monthly budget. You need a wallet and a category before recording an expense.',
      ),
      (
        'Record your spending',
        'Tap Add Expense. Enter the amount, choose the wallet and category, and save. The wallet balance updates automatically.',
      ),
      (
        'Keep the details',
        'Add notes or a receipt while recording an expense. Tap a purchase or receipt in the log to review it later.',
      ),
    ],
  ),
  FeatureGuide(
    'Budgets & spending history',
    Icons.bar_chart_rounded,
    AppTab.expenses,
    [
      (
        'Choose a month',
        'Use the month selector to browse your spending. The overview and charts reflect the selected month.',
      ),
      (
        'Set your limits',
        'Scroll to the category budget table and edit a category’s budget. Compare your budget with what you have spent.',
      ),
      (
        'Review older items',
        'Archive a purchase from the expense log. Archived purchases remain available in Me → Archive.',
      ),
    ],
  ),
  FeatureGuide('Workout counter', Icons.fitness_center_rounded, AppTab.fitness, [
    (
      'Time your exercise',
      'Tap Start under Timer. Pause when you need a break, or use the reset icon to start over.',
    ),
    (
      'Count your reps',
      'Choose a target and rep pace, then start the rep counter. Use + and − to adjust the count manually.',
    ),
    (
      'Finish a set',
      'Use Finish Set to move to the next set. Reset the reps when you want to begin a fresh session.',
    ),
  ]),
  FeatureGuide('Meals & meal ideas', Icons.restaurant_menu_rounded, AppTab.fitness, [
    (
      'Choose your day',
      'Scroll below Workout Counter to the meal planner and select a weekday.',
    ),
    (
      'Add a meal',
      'Tap Add Meal for the selected day and enter its time, foods, and notes. Tap an existing meal to edit it.',
    ),
    (
      'Get ideas',
      'Tap Ask AI, if available. Enter your preferences, allergies, budget, and meal count, then tap Generate.',
    ),
    (
      'Review before saving',
      'Review the suggestions and tap Add To Plan or Discard. AI requests need internet access; you can always add meals manually.',
    ),
  ]),
  FeatureGuide('Profile & preferences', Icons.person_outline_rounded, AppTab.me, [
    (
      'Make it yours',
      'Open Me and edit your profile to change your name, birthday, or preferred currency.',
    ),
    (
      'Keep your account handy',
      'Your account and saved records stay in the local database on this device.',
    ),
    (
      'Sign out when needed',
      'Use Sign Out on your profile card. Sign in with the same account on this device to return.',
    ),
  ]),
  FeatureGuide('Archive & help', Icons.inventory_2_outlined, AppTab.me, [
    (
      'Find saved history',
      'Scroll to Archive in Me to review completed tasks, archived purchases, and brain dump items.',
    ),
    (
      'Learn at your pace',
      'Open How to use Orbit to replay any guide. Reading a guide never changes your tasks or records.',
    ),
    (
      'Learn about Orbit',
      'Open About Orbit for the app version, developer information, and details about data and online features.',
    ),
  ]),
];

void openOrbitGuides(BuildContext context, {AppTab? tab}) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => OrbitGuidesPage(tab: tab)));
}

class OrbitGuidesPage extends StatelessWidget {
  const OrbitGuidesPage({this.tab, super.key});
  final AppTab? tab;

  @override
  Widget build(BuildContext context) {
    final guides = featureGuides.where(
      (guide) => tab == null || guide.tab == tab,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('How to use Orbit')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'A little guidance.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick a feature. Learn one step at a time.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              for (final guide in guides)
                Card(
                  elevation: 0,
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(guide.icon, color: AppColors.blue),
                    title: Text(guide.title),
                    subtitle: Text('${guide.steps.length} quick steps'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FeatureGuidePage(guide: guide),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureGuidePage extends ConsumerStatefulWidget {
  const FeatureGuidePage({required this.guide, super.key});
  final FeatureGuide guide;

  @override
  ConsumerState<FeatureGuidePage> createState() => _FeatureGuidePageState();
}

class _FeatureGuidePageState extends ConsumerState<FeatureGuidePage> {
  int _step = 0;
  final _scrollController = ScrollController();

  void _showStep(int step) {
    setState(() => _step = step);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;
    final step = guide.steps[_step];
    final isLast = _step == guide.steps.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text(guide.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.peach,
                      child: Icon(guide.icon, size: 44, color: AppColors.blue),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Step ${_step + 1} of ${guide.steps.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    step.$1,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    step.$2,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: AppColors.softText,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      if (!isLast) {
                        _showStep(_step + 1);
                      } else {
                        ref
                            .read(orbitControllerProvider.notifier)
                            .selectTab(guide.tab);
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: Icon(
                      isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      isLast
                          ? 'Try it in ${guide.tab == AppTab.expenses ? 'Expense' : guide.tab.name[0].toUpperCase() + guide.tab.name.substring(1)}'
                          : 'Next step',
                    ),
                  ),
                  if (_step > 0)
                    TextButton(
                      onPressed: () => _showStep(_step - 1),
                      child: const Text('Previous step'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Injected storage lets tests verify persistence without a native database.
final guideStorageProvider = Provider<GuideStorage>((ref) => GuideStorage());

class GuideStorage {
  Future<bool> hasSeen(String key) async =>
      await LocalDatabase.instance.read(key) == 'seen';
  Future<void> markSeen(String key) =>
      LocalDatabase.instance.write(key, 'seen');
}

class FirstVisitGuide extends ConsumerStatefulWidget {
  const FirstVisitGuide({required this.tab, super.key});
  final AppTab tab;

  @override
  ConsumerState<FirstVisitGuide> createState() => _FirstVisitGuideState();
}

class _FirstVisitGuideState extends ConsumerState<FirstVisitGuide> {
  bool _showIntro = false;
  bool _dismissed = false;
  String? _storageKey;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authControllerProvider).profile?.id;
    if (userId != null) {
      _storageKey = 'help.v1.$userId.${widget.tab.name}';
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final seen = await ref.read(guideStorageProvider).hasSeen(_storageKey!);
      if (mounted && !_dismissed) setState(() => _showIntro = !seen);
    } catch (_) {
      // Help stays available even when local storage cannot be read.
    }
  }

  Future<void> _dismiss() async {
    _dismissed = true;
    setState(() => _showIntro = false);
    if (_storageKey == null) return;
    try {
      await ref.read(guideStorageProvider).markSeen(_storageKey!);
    } catch (_) {
      // A storage error must not prevent users from using the app.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: _showIntro ? AppColors.peach : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: _showIntro ? 14 : 0),
          leading: const Icon(
            Icons.help_outline_rounded,
            color: AppColors.blue,
          ),
          title: Text(_showIntro ? 'New here? Start small.' : 'Quick guide'),
          subtitle: _showIntro ? const Text('See exactly where to tap.') : null,
          trailing: _showIntro
              ? IconButton(
                  tooltip: 'Dismiss introduction',
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close_rounded),
                )
              : const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () {
            _dismiss();
            final tour = WalkthroughScope.maybeOf(context);
            if (tour != null) {
              tour.start(widget.tab);
            } else {
              openOrbitGuides(context, tab: widget.tab);
            }
          },
        ),
      ),
    );
  }
}

class OrbitHelpLinks extends StatelessWidget {
  const OrbitHelpLinks({super.key});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: AppColors.surface,
    child: Column(
      children: [
        TourTarget(
          id: 'help.library',
          child: ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('How to use Orbit'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => openOrbitGuides(context),
          ),
        ),
      ],
    ),
  );
}

class OrbitAboutButton extends StatelessWidget {
  const OrbitAboutButton({super.key});

  @override
  Widget build(BuildContext context) => TourTarget(
    id: 'about',
    child: IconButton(
      tooltip: 'About Orbit',
      icon: const Icon(Icons.info_outline_rounded, size: 22),
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const OrbitAboutPage())),
    ),
  );
}

class OrbitAboutPage extends StatelessWidget {
  const OrbitAboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About Orbit')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.blur_circular_rounded,
                size: 42,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Orbit.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            const Text('Version 1.0.0 · Build 1', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text(
              'Developed by Nova',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('How to use Orbit'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => openOrbitGuides(context),
            ),
            const Divider(height: 1),
            for (final detail in const [
              (
                'Made for everyday life',
                'A calm place for daily tasks, spending, workouts, and meals. Start small and build routines at your own pace.',
              ),
              (
                'Developer information',
                'Developed by Nova, the developer behind Photozip.',
              ),
              (
                'Your data & privacy',
                'Your account and app records are saved in a local database on this device. Removing the app or clearing its data may remove your saved records.',
              ),
              (
                'Online features',
                'AI meal ideas, when enabled, send your meal preferences and allergies to OpenRouter and its selected model provider. Ads use Google Mobile Ads and may involve network requests. Ad consent is requested where required.',
              ),
              (
                'Reminders',
                'Device notifications need permission in your phone’s settings. Delivery depends on your notification settings and device permissions.',
              ),
            ]) ...[
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 20),
                title: Text(detail.$1),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      detail.$2,
                      style: const TextStyle(
                        color: AppColors.softText,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    ),
  );
}
