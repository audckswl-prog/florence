class AIPromotionModel {
  final String isbn;
  final String hookTitle;
  final String historicalBackground;
  final String closingQuestion;
  final DateTime? createdAt;

  AIPromotionModel({
    required this.isbn,
    required this.hookTitle,
    required this.historicalBackground,
    required this.closingQuestion,
    this.createdAt,
  });

  factory AIPromotionModel.fromJson(Map<String, dynamic> json) {
    return AIPromotionModel(
      isbn: json['isbn'] as String? ?? '',
      hookTitle: json['hook_title'] as String? ?? '',
      historicalBackground: json['historical_background'] as String? ?? '',
      closingQuestion: json['closing_question'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isbn': isbn,
      'hook_title': hookTitle,
      'historical_background': historicalBackground,
      'closing_question': closingQuestion,
    };
  }
}
