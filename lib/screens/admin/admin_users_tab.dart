import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await Supabase.instance.client.from('profiles').select();
      
      final loadedUsers = (response as List).map((map) {
        return UserModel(
          id: map['id']?.toString(), // ✅ Pasa el UUID en formato de texto correctamente // Convertimos el UUID a entero si tu modelo lo pide, o ajusta UserModel
          name: map['name'] ?? 'Sin nombre',
          email: map['email'] ?? '',
          password: '',
          role: map['role'] ?? 'user',
        );
      }).toList();

      setState(() {
        _users = loadedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error al cargar usuarios: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493)));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Estadísticas de Crecimiento", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF1493))),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(title: "Total", count: "${_users.length}", color: Colors.pinkAccent),
              _StatCard(title: "Esta Semana", count: "+${_users.length}", color: Colors.purpleAccent), // Dinámico según tu lógica
              _StatCard(title: "Este Mes", count: "+${_users.length}", color: Colors.deepOrangeAccent),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Usuarios Registrados en la Nube", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF1493))),
          const SizedBox(height: 10),
          Expanded(
            child: _users.isEmpty
                ? const Center(child: Text("No hay usuarios registrados"))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFF1493),
                            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "U", style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(user.email),
                          trailing: Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  const _StatCard({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 4),
              Text(count, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}