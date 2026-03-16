import 'role_model.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final int idRole;
  final String? emailVerifiedAt;
  final RoleModel? role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.idRole,
    this.emailVerifiedAt,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      idRole: json['id_role'] is int
          ? json['id_role']
          : int.parse(json['id_role'].toString()),
      emailVerifiedAt: json['email_verified_at'],
      role: json['role'] != null ? RoleModel.fromJson(json['role']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'id_role': idRole,
      'email_verified_at': emailVerifiedAt,
      'role': role?.toJson(),
    };
  }

  bool get isAdmin => role?.namaRole == 'admin';
  bool get isPelanggan => role?.namaRole == 'pelanggan';
  bool get isEmailVerified => emailVerifiedAt != null;
}