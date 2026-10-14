import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kdrama_model.dart';
import 'kdrama_detail_screen.dart'; // Importa la pantalla de detalles

class MyListScreen extends StatefulWidget {
  final List<KdramaModel> allKdramas;
  final VoidCallback? onListChanged;

  const MyListScreen({
    super.key,
    required this.allKdramas,
    this.onListChanged,
  });

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  // Función para actualizar Supabase al quitar de favoritos
  Future<void> _removeFromFavorites(KdramaModel drama) async {
    setState(() {
      drama.isFav = false;
    });

    try {
      await Supabase.instance.client
          .from('kdramas')
          .update({'isFav': false})
          .eq('id', drama.id!);

      if (widget.onListChanged != null) {
        widget.onListChanged!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'${drama.titulo}' fue eliminado de tu lista"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Error al actualizar favorito en Supabase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteKdramas = widget.allKdramas.where((drama) => drama.isFav).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "💖 Mi Lista de K-Dramas",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF1493)),
            ),
            const SizedBox(height: 5),
            const Text("Tus doramas guardados para ver más tarde", style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 20),
            Expanded(
              child: favoriteKdramas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 15),
                          const Text("Aún no has agregado ningún K-Drama a tu lista", style: TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: favoriteKdramas.length,
                      itemBuilder: (context, index) {
                        final drama = favoriteKdramas[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          clipBehavior: Clip.antiAlias, // Asegura que el InkWell respete los bordes redondeados
                          child: InkWell(
                            // 1. AQUÍ AGREGAMOS LA NAVEGACIÓN AL HACER CLIC EN LA TARJETA
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => KdramaDetailScreen(drama: drama)),
                              );
                              setState(() {}); // Refresca al volver por si cambió algo en los detalles
                              if (widget.onListChanged != null) {
                                widget.onListChanged!();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(drama.imagen, width: 70, height: 90, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(drama.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(drama.genero, style: const TextStyle(fontSize: 13, color: Color(0xFFFF1493), fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text("${drama.episodios.length} Episodios", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: "Eliminar de mi lista",
                                    onPressed: () => _removeFromFavorites(drama),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}