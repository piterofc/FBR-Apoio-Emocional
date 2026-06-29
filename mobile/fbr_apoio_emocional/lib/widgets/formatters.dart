String formatDateTime(dynamic value) {
  if (value == null) return '';

  final dateTime = value is DateTime ? value : DateTime.tryParse(value.toString());
  if (dateTime == null) return value.toString();

  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(dateTime.day)}/${twoDigits(dateTime.month)}/${dateTime.year} ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
}

String displayNameFromUser(dynamic user, {String fallback = 'Usuário'}) {
  if (user is Map<String, dynamic>) {
    final nickname = user['nickname']?.toString();
    final email = user['email']?.toString();
    if (nickname != null && nickname.isNotEmpty) return nickname;
    if (email != null && email.isNotEmpty) return email;
  }
  return fallback;
}
