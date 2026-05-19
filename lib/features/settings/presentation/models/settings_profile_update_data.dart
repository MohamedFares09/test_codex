class SettingsProfileUpdateData {
  const SettingsProfileUpdateData({
    required this.name,
    this.imagePath,
    this.deletePhoto = false,
  });

  final String name;
  final String? imagePath;
  final bool deletePhoto;
}
