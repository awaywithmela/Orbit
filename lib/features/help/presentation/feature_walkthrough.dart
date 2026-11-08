import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../orbit/domain/app_tab.dart';

class WalkthroughStep {
  const WalkthroughStep(this.target, this.title, this.description);
  final String target;
  final String title;
  final String description;
}

const walkthroughSteps = <AppTab, List<WalkthroughStep>>{
  AppTab.today: [
    WalkthroughStep(
      'today.add',
      'Add your first task',
      'Tap + to name a task and add it to your day.',
    ),
    WalkthroughStep(
      'today.reminders',
      'Check your reminders',
      'Tap the bell to see what is coming up.',
    ),
    WalkthroughStep(
      'today.focus',
      'Focus on one thing',
      'Once you have a task, tap Start focus here. Add a task first if this button is disabled.',
    ),
    WalkthroughStep(
      'today.organize',
      'Choose your view',
      'Tap Organize to adjust your timeline.',
    ),
    WalkthroughStep(
      'today.capture',
      'Make room in your head',
      'Tap Capture to save a thought in Brain Dump.',
    ),
  ],
  AppTab.plan: [
    WalkthroughStep(
      'plan.task',
      'Create a task',
      'Tap Task to choose a deadline, priority, and status.',
    ),
    WalkthroughStep(
      'plan.goal',
      'Set a small goal',
      'Tap Goal to add a monthly target.',
    ),
    WalkthroughStep(
      'plan.notes',
      'Keep a note',
      'Type a thought here, then tap Add note.',
    ),
    WalkthroughStep(
      'plan.breaks',
      'Make time for rest',
      'Tap Add Breaks to place breaks after longer schedule tasks.',
    ),
    WalkthroughStep(
      'plan.top',
      'Keep only three in view',
      'Tap Show 3 to simplify your schedule. Show All brings the full view back.',
    ),
    WalkthroughStep(
      'plan.session',
      'Work alongside someone',
      'Tap Start Session for a body-doubling focus guide.',
    ),
  ],
  AppTab.expenses: [
    WalkthroughStep(
      'expense.wallet',
      'Start with a wallet',
      'Tap New Wallet and enter your starting balance.',
    ),
    WalkthroughStep(
      'expense.category',
      'Group your spending',
      'Tap New Category to name a spending group and set its budget.',
    ),
    WalkthroughStep(
      'expense.add',
      'Record an expense',
      'Tap Add Expense, then choose the wallet and category you created.',
    ),
    WalkthroughStep(
      'expense.month',
      'Browse by month',
      'Tap a month here to review its spending and budgets.',
    ),
  ],
  AppTab.fitness: [
    WalkthroughStep(
      'fitness.timer',
      'Time your workout',
      'Tap Start to run the timer. Tap Pause when you need a break.',
    ),
    WalkthroughStep(
      'fitness.reps',
      'Count at your pace',
      'Set your target and pace above, then tap Start Count.',
    ),
    WalkthroughStep(
      'fitness.set',
      'Move to the next set',
      'Tap Finish Set when you finish your reps.',
    ),
    WalkthroughStep(
      'fitness.ai',
      'Get meal ideas',
      'Tap Ask AI to enter your preferences and review suggestions before saving.',
    ),
    WalkthroughStep(
      'fitness.meal',
      'Add your own meal',
      'Choose a day above, then tap this button to add a meal manually.',
    ),
  ],
  AppTab.me: [
    WalkthroughStep(
      'me.edit',
      'Make Orbit yours',
      'Tap Edit Profile to change your name, birthday, or currency.',
    ),
    WalkthroughStep(
      'help.library',
      'Replay a guide',
      'Tap How to use Orbit for detailed instructions on every feature.',
    ),
    WalkthroughStep(
      'about',
      'About Orbit',
      'Tap this info icon for app details, privacy information, and the developer credit.',
    ),
  ],
};

/// Marks an actual control, including controls built lazily further down a page.
class TourTarget extends StatelessWidget {
  const TourTarget({required this.id, required this.child, super.key});
  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final host = WalkthroughScope.maybeOf(context);
    return host == null
        ? child
        : KeyedSubtree(key: host.targetKey(id), child: child);
  }
}

class WalkthroughScope extends InheritedWidget {
  const WalkthroughScope({
    required this.host,
    required this.active,
    required super.child,
    super.key,
  });
  final FeatureWalkthroughHostState host;
  final bool active;

  static FeatureWalkthroughHostState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WalkthroughScope>()?.host;

  static EdgeInsets paddingOf(BuildContext context, EdgeInsets padding) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WalkthroughScope>();
    return scope?.active == true
        ? padding.copyWith(bottom: padding.bottom + 320)
        : padding;
  }

  @override
  bool updateShouldNotify(WalkthroughScope oldWidget) =>
      oldWidget.active != active;
}

class FeatureWalkthroughHost extends StatefulWidget {
  const FeatureWalkthroughHost({
    required this.tab,
    required this.child,
    super.key,
  });
  final AppTab tab;
  final Widget child;

  @override
  State<FeatureWalkthroughHost> createState() => FeatureWalkthroughHostState();
}

class FeatureWalkthroughHostState extends State<FeatureWalkthroughHost> {
  final scrollController = ScrollController();
  final _targets = <String, GlobalKey>{};
  final _canvasKey = GlobalKey();
  List<WalkthroughStep>? _steps;
  int _index = 0;
  int _generation = 0;
  Rect? _target;
  bool _locating = false;

  GlobalKey targetKey(String id) =>
      _targets.putIfAbsent(id, () => GlobalKey(debugLabel: id));

  void start(AppTab tab) {
    if (tab != widget.tab) return;
    setState(() {
      _steps = walkthroughSteps[tab];
      _index = 0;
    });
    _locate(0);
  }

  void stop() {
    _generation++;
    if (mounted)
      setState(() {
        _steps = null;
        _target = null;
        _locating = false;
      });
  }

  @override
  void didUpdateWidget(FeatureWalkthroughHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) {
      _generation++;
      _steps = null;
      _target = null;
      _locating = false;
    }
  }

  Future<void> _locate(int index) async {
    final generation = ++_generation;
    setState(() {
      _index = index;
      _target = null;
      _locating = true;
    });
    // Searching from the top also handles Back and controls built by lazy lists.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || generation != _generation) return;
    if (scrollController.hasClients) scrollController.jumpTo(0);
    for (var attempt = 0; attempt < 150; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || generation != _generation) return;
      final targetContext = _targets[_steps![index].target]?.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.12,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
        if (!mounted || generation != _generation) return;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || generation != _generation || !targetContext.mounted) {
          return;
        }
        final box = targetContext.findRenderObject();
        final canvas = _canvasKey.currentContext?.findRenderObject();
        if (box is RenderBox &&
            box.attached &&
            canvas is RenderBox &&
            box.hasSize) {
          final rect =
              box.localToGlobal(Offset.zero, ancestor: canvas) & box.size;
          setState(() {
            _target = rect.inflate(6);
            _locating = false;
          });
          return;
        }
      }
      if (!scrollController.hasClients) break;
      final position = scrollController.position;
      if (position.pixels >= position.maxScrollExtent) break;
      scrollController.jumpTo(
        math.min(
          position.maxScrollExtent,
          position.pixels + position.viewportDimension * .65,
        ),
      );
    }
    if (!mounted || generation != _generation) return;
    // For example, Edit Profile is absent without a signed-in profile.
    setState(() => _locating = false);
  }

  @override
  void dispose() {
    _generation++;
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    return WalkthroughScope(
      host: this,
      active: steps != null,
      child: PopScope(
        canPop: steps == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) stop();
        },
        child: Listener(
          onPointerDown: (event) {
            // Let a tap on the real highlighted control reach that control.
            if (_target?.contains(event.localPosition) == true) stop();
          },
          child: Stack(
            key: _canvasKey,
            fit: StackFit.expand,
            children: [
              widget.child,
              if (steps != null)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bounds = Offset.zero & constraints.biggest;
                    final hole = _target?.intersect(bounds);
                    final safeBottom = MediaQuery.paddingOf(context).bottom;
                    return Stack(
                      children: [
                        if (hole == null)
                          Positioned.fill(child: _blocker())
                        else ...[
                          Positioned.fromRect(
                            rect: Rect.fromLTRB(0, 0, bounds.right, hole.top),
                            child: _blocker(),
                          ),
                          Positioned.fromRect(
                            rect: Rect.fromLTRB(
                              0,
                              hole.bottom,
                              bounds.right,
                              bounds.bottom,
                            ),
                            child: _blocker(),
                          ),
                          Positioned.fromRect(
                            rect: Rect.fromLTRB(
                              0,
                              hole.top,
                              hole.left,
                              hole.bottom,
                            ),
                            child: _blocker(),
                          ),
                          Positioned.fromRect(
                            rect: Rect.fromLTRB(
                              hole.right,
                              hole.top,
                              bounds.right,
                              hole.bottom,
                            ),
                            child: _blocker(),
                          ),
                          Positioned.fromRect(
                            rect: hole,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (hole.center.dx - 16).clamp(
                              0,
                              bounds.width - 32,
                            ),
                            top: hole.bottom + 2,
                            child: const IgnorePointer(
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: safeBottom + 12,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 520,
                                maxHeight: math.min(300, bounds.height * .46),
                              ),
                              child: Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Semantics(
                                              liveRegion: true,
                                              child: Text(
                                                'Step ${_index + 1} of ${steps.length}',
                                                style: const TextStyle(
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: stop,
                                            child: const Text('Skip tour'),
                                          ),
                                        ],
                                      ),
                                      if (_locating)
                                        const LinearProgressIndicator()
                                      else ...[
                                        Text(
                                          steps[_index].title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          hole == null
                                              ? 'This control is not available on this screen yet. Continue to the next tip.'
                                              : steps[_index].description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(height: 1.4),
                                        ),
                                        const SizedBox(height: 6),
                                        if (hole != null)
                                          Text(
                                            'Tap the highlight to try it.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.muted,
                                                ),
                                          ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          if (_index > 0)
                                            TextButton(
                                              onPressed: _locating
                                                  ? null
                                                  : () => _locate(_index - 1),
                                              child: const Text('Back'),
                                            ),
                                          const Spacer(),
                                          FilledButton(
                                            onPressed: _locating
                                                ? null
                                                : () {
                                                    if (_index ==
                                                        steps.length - 1) {
                                                      stop();
                                                    } else {
                                                      _locate(_index + 1);
                                                    }
                                                  },
                                            child: Text(
                                              _index == steps.length - 1
                                                  ? 'Done'
                                                  : 'Next',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blocker() => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {},
    child: ColoredBox(color: Colors.black.withValues(alpha: .65)),
  );
}
