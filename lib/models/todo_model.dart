class TodoModel {
  String title;
  String description;
  bool isCompleted;
  String priority; // High / Medium / Low
  DateTime? dueDate;

  TodoModel({
    required this.title,
    required this.description,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "priority": priority,
      "isCompleted": isCompleted,
      "dueDate": dueDate?.toIso8601String(),
    };
  }

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      title: json["title"],
      description: json["description"],
      priority: json["priority"],
      isCompleted: json["isCompleted"],
      dueDate: json["dueDate"] != null ? DateTime.parse(json["dueDate"]) : null,
    );
  }
}
