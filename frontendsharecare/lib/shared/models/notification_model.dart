/// In-app notification from backend.
class NotificationModel {
  NotificationModel({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.message,
    this.notificationTypeDisplay,
    this.targetId,
    this.targetType,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      notificationTypeDisplay: json['notification_type_display'] as String?,
      targetId: json['target_id'] as int?,
      targetType: json['target_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

  final int id;
  final String notificationType;
  final String title;
  final String message;
  final String? notificationTypeDisplay;
  final int? targetId;
  final String? targetType;
  final bool isRead;
  final String? createdAt;
}
