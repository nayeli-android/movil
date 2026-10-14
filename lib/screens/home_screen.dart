import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/kdrama_model.dart';
import 'kdrama_detail_screen.dart';
import 'login_screen.dart'; // Asegúrate de importar tu pantalla de login

class HomeScreen extends StatefulWidget {
  final UserModel user;
  final List<KdramaModel> kdramas;
  final VoidCallback? onDataChanged;

  const HomeScreen({super.key, required this.user, required this.kdramas, this.onDataChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _categoriaSeleccionada = "Todos";
  String _busquedaTexto = "";

  // Función para mostrar el menú flotante del perfil y cerrar sesión
  void _showUserProfileMenu(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? widget.user.email;
    final userName = Supabase.instance.client.auth.currentUser?.userMetadata?['name'] ?? widget.user.name;

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
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFFF1493),
              child: Icon(Icons.person, size: 35, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Cerrar Sesión",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
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
    final kdramasFiltrados = widget.kdramas.where((drama) {
      final coincideCategoria = _categoriaSeleccionada == "Todos" || drama.genero == _categoriaSeleccionada;
      final coincideBusqueda = drama.titulo.toLowerCase().contains(_busquedaTexto.toLowerCase());
      return coincideCategoria && coincideBusqueda;
    }).toList();

    final recientes = widget.kdramas.reversed.take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hola, ${widget.user.name} 👋",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF1493)),
                      ),
                      const Text(
                        "¿Qué K-Drama deseas ver hoy?",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                  // AQUÍ AGREGAMOS EL GESTUREDETECTOR AL CIRCLEAVATAR
                  GestureDetector(
                    onTap: () => _showUserProfileMenu(context),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFFF1493),
                      child: Text(
                        widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : "U",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                onChanged: (value) => setState(() => _busquedaTexto = value),
                decoration: InputDecoration(
                  hintText: "Buscar K-Drama por título...",
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFF1493)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            if (recientes.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("🔥 Agregados Recientemente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF1493))),
              ),
              SizedBox(
                height: 160,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.85),
                  itemCount: recientes.length,
                  itemBuilder: (context, index) {
                    final drama = recientes[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => KdramaDetailScreen(drama: drama)));
                        if (widget.onDataChanged != null) widget.onDataChanged!();
                        setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(image: NetworkImage(drama.imagen), fit: BoxFit.cover),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            drama.titulo,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ["Todos", "Romance", "Comedia", "Popular"].map((cat) {
                  final selected = _categoriaSeleccionada == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selected,
                      selectedColor: const Color(0xFFFF1493),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : const Color(0xFFFF1493),
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white,
                      onSelected: (bool isSelected) => setState(() => _categoriaSeleccionada = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("Catálogo Completo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF1493))),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: kdramasFiltrados.length,
              itemBuilder: (context, index) {
                final drama = kdramasFiltrados[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => KdramaDetailScreen(drama: drama)));
                      if (widget.onDataChanged != null) widget.onDataChanged!();
                      setState(() {});
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(child: Image.network(drama.imagen, fit: BoxFit.cover)),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(drama.titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(drama.genero, style: const TextStyle(fontSize: 11, color: Color(0xFFFFB6C1))),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: Icon(
                              drama.isFav ? Icons.favorite : Icons.favorite_border,
                              color: const Color(0xFFFF1493),
                              size: 22,
                            ),
                            onPressed: () async {
                              setState(() {
                                drama.isFav = !drama.isFav;
                              });
                              try {
                                await Supabase.instance.client
                                    .from('kdramas')
                                    .update({'isFav': drama.isFav})
                                    .eq('id', drama.id!);
        
                                if (widget.onDataChanged != null) {
                                  widget.onDataChanged!();
                                }
                              } catch (e) {
                                debugPrint("Error al actualizar favorito: $e");
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}