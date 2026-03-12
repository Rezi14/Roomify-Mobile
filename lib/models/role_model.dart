class RoleModel {
  final int idRole;
  final String namaRole;
  final String? deskripsi;

  RoleModel({
    required this.idRole,
    required this.namaRole,
    this.deskripsi,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      idRole: json['id_role'] is int
          ? json['id_role']
          : int.parse(json['id_role'].toString()),
      namaRole: json['nama_role'] ?? '',
      deskripsi: json['deskripsi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_role': idRole,
      'nama_role': namaRole,
      'deskripsi': deskripsi,
    };
  }
}