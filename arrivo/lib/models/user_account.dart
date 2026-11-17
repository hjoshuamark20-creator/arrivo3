/// The signed-in user (name and email only; the password never leaves the secure store).
class UserAccount {
  const UserAccount({required this.name, required this.email});

  final String name;
  final String email;

  /// Two-letter initials for the avatar, e.g. "Maria Santos" -> "MS".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Map<String, dynamic> toJson() => {'name': name, 'email': email};

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        name: (json['name'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
      );
}
