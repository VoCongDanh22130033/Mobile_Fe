// máy ảo
// const String baseUrl = "http://10.0.2.2:8080";
//thiết bị thật
const String baseUrl = "http://192.168.2.4:8080";

// ✅ Hàm xử lý URL ảnh an toàn
String getImageUrl(String path) {
  if (path.startsWith('http')) {
    // Nếu path đã là URL hoàn chỉnh (vd Cloudinary, CDN)
    return path;
  } else {
    // Nếu là đường dẫn tương đối từ server (vd /uploads/image.png)
    return "$baseUrl/$path";
  }
}
