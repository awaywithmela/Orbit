class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.currencyCode,
    this.birthDate,
  });

  final String id;
  final String displayName;
  final String email;
  final String currencyCode;
  final DateTime? birthDate;

  String get firstName {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      return 'there';
    }
    return trimmedName.split(RegExp(r'\s+')).first;
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? currencyCode,
    DateTime? birthDate,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      currencyCode: currencyCode ?? this.currencyCode,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}
