class Project {
  int? id;
  String name;
  String description;
  double progress;

  Project(
      {this.id,
      required this.name,
      required this.description,
      this.progress = 0.0});

  // Convert a Project into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'progress': progress,
    };
  }

  // Convert a Map into a Project.
  static Project fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      progress: map['progress'],
    );
  }
}
