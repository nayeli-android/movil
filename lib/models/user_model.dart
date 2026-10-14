class UserModel {
  String? id; // Cambiado a String? porque Supabase usa IDs de tipo UUID
  String name;
  String email;
  String password;
  String role; // 'admin' o 'user'

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}

class UserStore {
  // Almacena el usuario autenticado temporalmente si lo requieres en la app
  static UserModel? currentUser;
}