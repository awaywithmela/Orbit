import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/rounded_dropdown_form_field.dart';
import '../../orbit/presentation/orbit_home_page.dart';
import '../application/auth_controller.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState.isSignedIn) {
      return const OrbitHomePage();
    }

    return const ProfileSetupPage();
  }
}

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _onboardingController = PageController();
  var _onboardingPage = 0;
  var _showAuthForm = false;
  var _isLoginMode = false;
  var _showPassword = false;
  var _showConfirmPassword = false;
  var _currencyCode = 'PHP';
  DateTime? _birthDate;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    _onboardingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (!_showAuthForm) {
      return Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
            ),
          ),
          child: SafeArea(
            child: _FullScreenOnboarding(
              controller: _onboardingController,
              currentPage: _onboardingPage,
              onPageChanged: (page) {
                setState(() => _onboardingPage = page);
              },
              onSkip: () => setState(() => _showAuthForm = true),
              onNext: _advanceOnboarding,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 112, 18, 150),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 262,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isLoginMode ? 'Log In' : 'Create Account',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -.4,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isLoginMode
                                      ? 'Welcome back to Orbit.'
                                      : 'Make Orbit yours.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                ),
                                const SizedBox(height: 28),
                                if (!_isLoginMode) ...[
                                  TextField(
                                    key: const ValueKey('profileNameField'),
                                    controller: _nameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Name',
                                      prefixIcon: Icon(Icons.person_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                TextField(
                                  key: const ValueKey('profileEmailField'),
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  key: const ValueKey('profilePasswordField'),
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  textInputAction: _isLoginMode
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_rounded),
                                    suffixIcon: IconButton(
                                      key: const ValueKey(
                                        'togglePasswordVisibility',
                                      ),
                                      tooltip: _showPassword
                                          ? 'Hide password'
                                          : 'Show password',
                                      onPressed: () => setState(
                                        () => _showPassword = !_showPassword,
                                      ),
                                      icon: Icon(
                                        _showPassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!_isLoginMode) ...[
                                  const SizedBox(height: 12),
                                  TextField(
                                    key: const ValueKey(
                                      'profileConfirmPasswordField',
                                    ),
                                    controller: _confirmPasswordController,
                                    obscureText: !_showConfirmPassword,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_reset_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        key: const ValueKey(
                                          'toggleConfirmPasswordVisibility',
                                        ),
                                        tooltip: _showConfirmPassword
                                            ? 'Hide confirmed password'
                                            : 'Show confirmed password',
                                        onPressed: () => setState(
                                          () => _showConfirmPassword =
                                              !_showConfirmPassword,
                                        ),
                                        icon: Icon(
                                          _showConfirmPassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _birthDateController,
                                    readOnly: true,
                                    onTap: _pickBirthDate,
                                    decoration: const InputDecoration(
                                      labelText: 'Birthday',
                                      hintText: 'Optional',
                                      prefixIcon: Icon(Icons.cake_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  RoundedDropdownFormField<String>(
                                    value: _currencyCode,
                                    menuMaxHeight: 280,
                                    itemHeight: 56,
                                    decoration: const InputDecoration(
                                      labelText: 'Default Currency',
                                      prefixIcon: Icon(Icons.payments_rounded),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'PHP',
                                        child: Text('PHP - Peso'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'USD',
                                        child: Text('USD - US Dollar'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'EUR',
                                        child: Text('EUR - Euro'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'GBP',
                                        child: Text('GBP - British Pound'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'CAD',
                                        child: Text('CAD - Canadian Dollar'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'AUD',
                                        child: Text('AUD - Australian Dollar'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'JPY',
                                        child: Text('JPY - Japanese Yen'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'SGD',
                                        child: Text('SGD - Singapore Dollar'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'AED',
                                        child: Text('AED - UAE Dirham'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'INR',
                                        child: Text('INR - Indian Rupee'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'KRW',
                                        child: Text('KRW - South Korean Won'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'CHF',
                                        child: Text('CHF - Swiss Franc'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'NZD',
                                        child: Text('NZD - New Zealand Dollar'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _currencyCode = value);
                                      }
                                    },
                                  ),
                                ],
                                if (authState.errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    authState.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (authState.errorMessage!.contains(
                                        'confirmation link',
                                      ) ||
                                      authState.errorMessage!.contains(
                                        'newest email',
                                      )) ...[
                                    const SizedBox(height: 8),
                                    Center(
                                      child: TextButton.icon(
                                        key: const ValueKey(
                                          'resendConfirmationButton',
                                        ),
                                        onPressed: authState.isLoading
                                            ? null
                                            : () => ref
                                                  .read(
                                                    authControllerProvider
                                                        .notifier,
                                                  )
                                                  .resendConfirmation(
                                                    _emailController.text,
                                                  ),
                                        icon: const Icon(
                                          Icons.mark_email_unread_rounded,
                                        ),
                                        label: const Text('Send a fresh link'),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 18,
                left: 18,
                right: 18,
                child: Center(
                  child: _AuthModeSwitch(
                    isLoginMode: _isLoginMode,
                    onChanged: (value) {
                      ref.read(authControllerProvider.notifier).clearError();
                      setState(() => _isLoginMode = value);
                    },
                  ),
                ),
              ),
              _GlassAuthBar(
                isLoginMode: _isLoginMode,
                isLoading: authState.isLoading,
                onPrimary: _continueToOrbit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (date == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _birthDate = date;
      _birthDateController.text =
          '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    });
  }

  Future<void> _continueToOrbit() async {
    final wasSigningUp = !_isLoginMode;
    await ref
        .read(authControllerProvider.notifier)
        .signInWithProfile(
          displayName: _isLoginMode
              ? _emailController.text.split('@').first
              : _nameController.text,
          email: _emailController.text,
          currencyCode: _currencyCode,
          birthDate: _birthDate,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          isLoginMode: _isLoginMode,
        );
    if (!mounted || !wasSigningUp) {
      return;
    }
    final message = ref.read(authControllerProvider).errorMessage;
    if (message?.startsWith('We sent a confirmation link') == true) {
      setState(() => _isLoginMode = true);
    }
  }

  void _advanceOnboarding() {
    final isLastPage = _onboardingPage == _OnboardingCarousel.slideCount - 1;
    if (isLastPage) {
      setState(() => _showAuthForm = true);
      return;
    }
    _onboardingController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}

class _AuthModeSwitch extends StatelessWidget {
  const _AuthModeSwitch({required this.isLoginMode, required this.onChanged});

  final bool isLoginMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 330),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _AuthModeButton(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Sign Up',
                selected: !isLoginMode,
                onTap: () => onChanged(false),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _AuthModeButton(
                icon: Icons.check_rounded,
                label: 'Log In',
                selected: isLoginMode,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.activeCard : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.text),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenOnboarding extends StatelessWidget {
  const _FullScreenOnboarding({
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
    required this.onSkip,
    required this.onNext,
  });

  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == _OnboardingCarousel.slideCount - 1;

    return Stack(
      children: [
        const Positioned(
          left: -70,
          top: 30,
          child: _AmbientOrb(size: 190, color: AppColors.peach),
        ),
        const Positioned(
          right: -90,
          bottom: 80,
          child: _AmbientOrb(size: 230, color: AppColors.sage),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  const _OrbitWordmark(),
                  const Spacer(),
                  TextButton(onPressed: onSkip, child: const Text('Skip')),
                ],
              ),
              Expanded(
                child: _OnboardingCarousel(
                  controller: controller,
                  currentPage: currentPage,
                  onPageChanged: onPageChanged,
                  expanded: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('onboardingNextButton'),
                  onPressed: onNext,
                  icon: Icon(
                    isLastPage
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(isLastPage ? 'Get started' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrbitWordmark extends StatelessWidget {
  const _OrbitWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.blue],
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 18),
            ],
          ),
          child: const Icon(Icons.blur_circular_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          'ORBIT',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .28),
          boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 8)],
        ),
      ),
    );
  }
}

class _OnboardingCarousel extends StatelessWidget {
  const _OnboardingCarousel({
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
    this.expanded = false,
  });

  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final bool expanded;

  static int get slideCount => _slides.length;

  static const _slides = [
    _OnboardingSlideData(
      icon: Icons.auto_awesome_rounded,
      headline: 'A little more calm.',
      body: 'Your day, all in one place.',
      previewLabel: 'Your daily space',
    ),
    _OnboardingSlideData(
      icon: Icons.calendar_month_rounded,
      headline: 'One thing at a time.',
      body: 'Pick a task. Find your focus.',
      previewLabel: 'Today’s focus',
    ),
    _OnboardingSlideData(
      icon: Icons.account_balance_wallet_rounded,
      headline: 'Room for real life.',
      body: 'Keep money, meals, and movement together.',
      previewLabel: 'Your routines',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final carousel = PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      itemCount: _slides.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _OnboardingSlide(slide: _slides[index]),
        );
      },
    );

    return Column(
      children: [
        if (expanded)
          Expanded(child: carousel)
        else
          SizedBox(height: 390, child: carousel),
        const SizedBox(height: 12),
        _OnboardingDots(currentPage: currentPage, count: _slides.length),
      ],
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.currentPage, required this.count});

  final int currentPage;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: currentPage == index ? 36 : 12,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: currentPage == index
                  ? AppColors.primary
                  : AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _OnboardingSlide extends StatefulWidget {
  const _OnboardingSlide({required this.slide});

  final _OnboardingSlideData slide;

  @override
  State<_OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<_OnboardingSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -5 + (_controller.value * 10)),
                child: Transform.rotate(
                  angle: -.025 + (_controller.value * .05),
                  child: child,
                ),
              ),
              child: _ProductPreview(slide: widget.slide),
            ),
            const SizedBox(height: 24),
            Text(
              widget.slide.headline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.slide.body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.softText,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview({required this.slide});

  final _OnboardingSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      height: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.text, Color(0xFF51483F)],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: Colors.white.withValues(alpha: .65),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .17),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(slide.icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.sage,
                size: 26,
              ),
            ],
          ),
          const Spacer(),
          Text(
            slide.previewLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                Expanded(
                  child: Container(
                    height: index.isEven ? 8 : 14,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: .38),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.icon,
    required this.headline,
    required this.body,
    required this.previewLabel,
  });

  final IconData icon;
  final String headline;
  final String body;
  final String previewLabel;
}

class _GlassAuthBar extends StatelessWidget {
  const _GlassAuthBar({
    required this.isLoginMode,
    required this.isLoading,
    required this.onPrimary,
  });

  final bool isLoginMode;
  final bool isLoading;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('continueToOrbitButton'),
            onPressed: isLoading ? null : onPrimary,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      key: ValueKey('authLoadingIndicator'),
                      strokeWidth: 2.6,
                      color: AppColors.text,
                    ),
                  )
                : Icon(
                    isLoginMode
                        ? Icons.login_rounded
                        : Icons.person_add_rounded,
                  ),
            label: Text(
              isLoading
                  ? isLoginMode
                        ? 'Logging in…'
                        : 'Creating account…'
                  : isLoginMode
                  ? 'Log In'
                  : 'Sign Up',
            ),
          ),
        ),
      ),
    );
  }
}
