class UploadConstants {
  static const int maxFileSizeMb = 20;
  static const int maxFileSizeBytes = maxFileSizeMb * 1024 * 1024;
  static const List<String> allowedExtensions = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'mp4'];
  static const int maxFileNameLength = 100;
}
