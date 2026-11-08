import '../domain/user_profile.dart';

class AuthState {
  const AuthState({
    required this.profile,
    required this.isLoading,
    required this.errorMessage,
  });

  const AuthState.signedOut()
    : profile = null,
      isLoading = false,
      errorMessage = null;

  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;

  bool get isSignedIn => profile != null;

  AuthState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return AuthState(
      profile: clearProfile ? null : profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
