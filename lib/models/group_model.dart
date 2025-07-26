class GroupModel {
  final String id;
  final String name;
  final String createdBy;
  final List<String> members;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
  });

  factory GroupModel.fromMap(String id, Map<String, dynamic> map) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      createdBy: map['createdBy'] ?? '',
      members: List<String>.from(map['members'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdBy': createdBy,
      'members': members,
    };
  }
}
