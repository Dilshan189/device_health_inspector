String formatBytes(dynamic bytes) {
  if (bytes == null || bytes <= 0) return "0 B";
  double b = bytes is int ? bytes.toDouble() : bytes;
  if (b > 1024 * 1024 * 1024)
    return "${(b / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
  if (b > 1024 * 1024) return "${(b / (1024 * 1024)).toStringAsFixed(1)} MB";
  return "${(b / 1024).toStringAsFixed(0)} KB";
}
