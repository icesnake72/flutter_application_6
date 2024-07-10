class BoardDTO {
  final int id;
  final String title;
  final String text;
  final int like;
  final int unlike;
  final int userId;
  final String userEmail;
  final String userNickname;
  final List<String> imageUrls;

  BoardDTO({
    required this.id,
    required this.title,
    required this.text,
    required this.like,
    required this.unlike,
    required this.userId,
    required this.userEmail,
    required this.userNickname,
    required this.imageUrls,
  });

  factory BoardDTO.fromJson(Map<String, dynamic> json) {
    return BoardDTO(
      id: json['id'],
      title: json['title'],
      text: json['text'],
      like: json['like'],
      unlike: json['unlike'],
      userId: json['userId'],
      userEmail: json['userEmail'],
      userNickname: json['userNickName'],
      imageUrls: List<String>.from(json['imageUrls']),
    );
  }
}
