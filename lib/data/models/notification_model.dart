class NotificationModel {
  final String id;
  final String userId;
  final String? senderId;
  final String type; // 'friend_request', 'project_invite', 'project_started', 'page_milestone', 'project_success'
  final String? message;
  final String? relatedId; // Project ID or Friendship ID
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.senderId,
    required this.type,
    this.message,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      senderId: json['sender_id'],
      type: json['type'],
      message: json['message'],
      relatedId: json['related_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
