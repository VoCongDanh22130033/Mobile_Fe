const String baseUrl = "https://daren-stroppy-joette.ngrok-free.dev";

String getImageUrl(String? path) {
  if (path == null || path.isEmpty) return "https://via.placeholder.com/150";
  if (path.startsWith('http')) return path;

  // Đảm bảo không bị thừa dấu "/" giữa baseUrl và path
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;

  return "$baseUrl/$cleanPath";
}