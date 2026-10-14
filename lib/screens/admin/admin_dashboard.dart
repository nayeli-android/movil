import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../models/kdrama_model.dart';
import 'admin_catalog_tab.dart';
import 'admin_add_drama_tab.dart';
import 'admin_users_tab.dart';
import '../login_screen.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  List<KdramaModel> _kdramas = [];
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  // Cargar datos del catálogo y usuarios desde Supabase
  Future<void> _loadAdminData() async {
    try {
      final response = await Supabase.instance.client.from('kdramas').select();
      
      final loadedKdramas = (response as List).map((map) {
        return KdramaModel(
          id: map['id'],
          titulo: map['titulo'],
          genero: map['genero'],
          descripcion: map['descripcion'],
          imagen: map['imagen'],
          isFav: map['isFav'] == true, 
          rating: (map['rating'] ?? 4.5).toDouble(),
          episodios: [
            EpisodeModel(title: "Episodio 1", duration: "60 min", videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
          ],
        );
      }).toList();

      final currentAuthUser = Supabase.instance.client.auth.currentUser;
      List<UserModel> loadedUsers = [
        UserModel(
          id: currentAuthUser?.id ?? 'admin_id', 
          name: "Administrador", 
          email: currentAuthUser?.email ?? "admin@kdrama.com", 
          password: "", 
          role: "admin"
        ),
      ];

      setState(() {
        _kdramas = loadedKdramas;
        _users = loadedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error al cargar datos del admin: $e");
    }
  }

  void _showProfileMenu() {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'admin@kdrama.com';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Perfil de Administrador", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF1493))),
            const SizedBox(height: 15),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFFFF1493)),
              title: const Text("Administrador"),
              subtitle: Text(userEmail),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF1493))),
      );
    }

    final List<Widget> pages = [
      AdminCatalogTab(
        kdramas: _kdramas,
        onDelete: (dramaToDelete) async {
          await Supabase.instance.client
              .from('kdramas')
              .delete()
              .eq('id', dramaToDelete.id!);
          
          await _loadAdminData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("'${dramaToDelete.titulo}' fue eliminado de la nube"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
      AdminAddDramaTab(onDramaAdded: (newDrama) async {
        // El guardado ya se hace dentro de AdminAddDramaTab, 
        // aquí solo recargamos la lista y volvemos al catálogo (índice 0).
        await _loadAdminData();
        setState(() {
          _currentIndex = 0; 
        });
      }),
      const AdminUsersTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: _showProfileMenu,
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF1493),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Catálogo"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Subir Dorama"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Usuarios"),
        ],
      ),
    );
  }
}