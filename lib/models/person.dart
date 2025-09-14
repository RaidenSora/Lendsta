class Person {
  final int? id;
  final String name;

  const Person({this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  static Person fromMap(Map<String, dynamic> m) =>
      Person(id: m['id'] as int?, name: m['name'] as String);
}
