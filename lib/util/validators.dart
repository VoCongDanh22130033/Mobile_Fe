class Validators {
  static final RegExp _gmailOnly =
  RegExp(r'^[a-zA-Z0-9._%+-]+@(gmail\.com|googlemail\.com)$');

  // >=8 ký tự, có chữ và số
  static final RegExp _password =
  RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  static String? gmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Vui lòng nhập email';
    if (!_gmailOnly.hasMatch(s)) return 'Chỉ chấp nhận Gmail (vd: ten@gmail.com)';
    return null;
  }

  static String? password(String? v) {
    final s = (v ?? '');
    if (s.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (!_password.hasMatch(s)) return 'Mật khẩu ≥ 8 ký tự và gồm chữ + số';
    return null;
  }
}
