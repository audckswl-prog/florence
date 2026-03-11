class Project {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String? isbn;
  final String status; // 'pending_books', 'in_progress', 'completed', 'failed'
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.isbn,
    this.status = 'pending_books',
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      ownerId: json['owner_id'],
      isbn: json['isbn'],
      status: json['status'] ?? 'pending_books',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'status': status,
    };
  }
}

class ProjectMember {
  final String id;
  final String projectId;
  final String userId;
  final String role; // 'owner', 'member'
  final String readingStatus; // 'reading', 'completed'
  final int aiQuestionCount;
  final String? receiptUrl;
  final String? selectedIsbn;
  final String? selectedBookTitle;
  final String? selectedBookCover;
  final String? quote;
  final String? drawingUrl;
  final DateTime joinedAt;
  final String? nickname;
  final String? profileUrl;

  ProjectMember({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    required this.readingStatus,
    required this.aiQuestionCount,
    this.receiptUrl,
    this.selectedIsbn,
    this.selectedBookTitle,
    this.selectedBookCover,
    this.quote,
    this.drawingUrl,
    required this.joinedAt,
    this.nickname,
    this.profileUrl,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    // Parse joined book data if available
    final bookData = json['books'] as Map<String, dynamic>?;
    // Parse joined profile data if available
    final profileData = json['profiles'] as Map<String, dynamic>?;

    return ProjectMember(
      id: json['id'],
      projectId: json['project_id'],
      userId: json['user_id'],
      role: json['role'] ?? 'member',
      readingStatus: json['reading_status'] ?? 'reading',
      aiQuestionCount: json['ai_question_count'] ?? 0,
      receiptUrl: json['receipt_url'],
      selectedIsbn: json['selected_isbn'],
      selectedBookTitle: bookData?['title'],
      selectedBookCover: bookData?['cover_url'],
      quote: json['quote'] as String?,
      drawingUrl: json['drawing_url'] as String?,
      joinedAt: DateTime.parse(json['joined_at']),
      nickname: profileData?['nickname'],
      profileUrl: profileData?['profile_url'],
    );
  }
}

class ProjectBook {
  final String id;
  final String projectId;
  final String isbn;
  final DateTime? targetDate;
  final DateTime createdAt;

  ProjectBook({
    required this.id,
    required this.projectId,
    required this.isbn,
    this.targetDate,
    required this.createdAt,
  });

  factory ProjectBook.fromJson(Map<String, dynamic> json) {
    return ProjectBook(
      id: json['id'],
      projectId: json['project_id'],
      isbn: json['isbn'],
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ProjectInvite {
  final String id;
  final String projectId;
  final DateTime expiresAt;
  final DateTime createdAt;

  ProjectInvite({
    required this.id,
    required this.projectId,
    required this.expiresAt,
    required this.createdAt,
  });

  factory ProjectInvite.fromJson(Map<String, dynamic> json) {
    return ProjectInvite(
      id: json['id'],
      projectId: json['project_id'],
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AiQnaLog {
  final String id;
  final String projectId;
  final String userId;
  final String question;
  final String answer;
  final DateTime createdAt;

  AiQnaLog({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.question,
    required this.answer,
    required this.createdAt,
  });

  factory AiQnaLog.fromJson(Map<String, dynamic> json) {
    return AiQnaLog(
      id: json['id'],
      projectId: json['project_id'],
      userId: json['user_id'],
      question: json['question'],
      answer: json['answer'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
