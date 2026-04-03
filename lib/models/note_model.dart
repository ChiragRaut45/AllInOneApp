class NoteModel {
  String date; // YYYY-MM-DD
  String text;

  NoteModel({required this.date, required this.text});

  Map<String, dynamic> toJson() => {'date': date, 'text': text};

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(date: json['date'], text: json['text']);
  }
}
