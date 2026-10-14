import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/kdrama_model.dart';

class AdminCatalogTab extends StatelessWidget {
  final List<KdramaModel> kdramas;
  final Function(KdramaModel) onDelete;
  final VoidCallback? onRefreshNeeded; // Opcional para refrescar lista

  const AdminCatalogTab({
    super.key,
    required this.kdramas,
    required this.onDelete,
    this.onRefreshNeeded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Catálogo de K-Dramas (Admin)",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF1493)),
          ),
          const SizedBox(height: 5),
          Text("${kdramas.length} doramas disponibles en la plataforma", style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 15),
          Expanded(
            child: kdramas.isEmpty
                ? const Center(child: Text("No hay K-Dramas registrados"))
                : ListView.builder(
                    itemCount: kdramas.length,
                    itemBuilder: (context, index) {
                      final drama = kdramas[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(drama.imagen, width: 65, height: 85, fit: BoxFit.cover),
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
                              // Botón de Editar
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFFFF1493)),
                                tooltip: "Editar Dorama",
                                onPressed: () async {
                                  final actualizado = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AdminEditDramaScreen(drama: drama)),
                                  );
                                  if (actualizado == true && onRefreshNeeded != null) {
                                    onRefreshNeeded!();
                                  }
                                },
                              ),
                              // Botón de Eliminar
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: "Eliminar Dorama",
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Eliminar K-Drama"),
                                      content: Text("¿Estás seguro de eliminar '${drama.titulo}'?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Cancelar"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            onDelete(drama);
                                          },
                                          child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
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

class AdminEditDramaScreen extends StatefulWidget {
  final KdramaModel drama;
  const AdminEditDramaScreen({super.key, required this.drama});

  @override
  State<AdminEditDramaScreen> createState() => _AdminEditDramaScreenState();
}

class _AdminEditDramaScreenState extends State<AdminEditDramaScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _genreController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.drama.titulo);
    _descController = TextEditingController(text: widget.drama.descripcion);
    _genreController = TextEditingController(text: widget.drama.genero);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Editar: ${widget.drama.titulo}")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: "Título", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(controller: _genreController, decoration: InputDecoration(labelText: "Género", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(controller: _descController, maxLines: 3, decoration: InputDecoration(labelText: "Descripción", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1493),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                try {
                  await Supabase.instance.client
                      .from('kdramas')
                      .update({
                        'titulo': _titleController.text.trim(),
                        'genero': _genreController.text.trim(),
                        'descripcion': _descController.text.trim(),
                      })
                      .eq('id', widget.drama.id!);

                  setState(() => _isLoading = false);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cambios guardados en la nube con éxito"), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context, true); 
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al actualizar los datos. Inténtalo de nuevo."), backgroundColor: Colors.red),
                  );
                }
              },
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("GUARDAR CAMBIOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}