class UserPrivateText {
  final String userId;
  final String hashedMasterSecret;
  final DateTime updatedAt;

  UserPrivateText({
    required this.userId,
    required this.hashedMasterSecret,
    required this.updatedAt,
  });

  factory UserPrivateText.fromJson(Map<String, dynamic> json) {
    return UserPrivateText(
      userId: json['user_id'] as String,
      hashedMasterSecret: json['text_content'] as String? ?? '',
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'text_content': hashedMasterSecret,
      // updated_at معمولا خودکار توسط دیتابیس پر می‌شود، اما اگر نیاز بود اینجا اضافه کنید
    };
  }
}
