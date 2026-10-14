class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    user: Map<String, dynamic>.from(json['user'] as Map),
  );

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;
}
