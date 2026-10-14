import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/kdrama_model.dart';

class AdminAddDramaTab extends StatefulWidget {
  final Function(KdramaModel) onDramaAdded;
  const AdminAddDramaTab({super.key, required this.onDramaAdded});

  @override
  State<AdminAddDramaTab> createState() => _AdminAddDramaTabState();
}

class _AdminAddDramaTabState extends State<AdminAddDramaTab> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _genreController = TextEditingController();
  final _imageController = TextEditingController();

  final List<Map<String, TextEditingController>> _episodesInputs = [];

  void _addEpisodeField() {
    setState(() {
      _episodesInputs.add({
        'title': TextEditingController(),
        'duration': TextEditingController(),
        'url': TextEditingController(),
      });
    });
  }

// Instancia de Supabase
  final supabase = Supabase.instance.client;

  void _submitDrama() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, llena al menos el Título y la Descripción"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // 1. Preparamos los datos básicos para enviarlos a la tabla 'kdramas' en Supabase
      final Map<String, dynamic> dramaData = {
        'titulo': _titleController.text.trim(),
        'genero': _genreController.text.isEmpty ? "Romance" : _genreController.text.trim(),
        'descripcion': _descController.text.trim(),
        'imagen': _imageController.text.isEmpty ? "https://picsum.photos/300/200?random=99" : _imageController.text.trim(),
        'isFav': false,
        'rating': 4.5,
      };

      // 2. Insertamos en Supabase y esperamos la respuesta
      final response = await supabase.from('kdramas').insert(dramaData).select().single();

      // 3. Creamos el modelo local para actualizar la interfaz al instante
      List<EpisodeModel> episodes = _episodesInputs.map((ep) {
        return EpisodeModel(
          title: ep['title']!.text.isEmpty ? "Episodio" : ep['title']!.text,
          duration: ep['duration']!.text.isEmpty ? "45 min" : ep['duration']!.text,
          videoUrl: ep['url']!.text.isEmpty ? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4' : ep['url']!.text,
        );
      }).toList();

      final newDrama = KdramaModel(
        id: response['id'], // ID real generado por Supabase
        titulo: _titleController.text,
        genero: _genreController.text.isEmpty ? "Romance" : _genreController.text,
        descripcion: _descController.text,
        imagen: _imageController.text.isEmpty ? "https://picsum.photos/300/200?random=99" : _imageController.text,
        episodios: episodes.isEmpty ? [EpisodeModel(title: "Episodio 1", duration: "50 min", videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4')] : episodes,
      );

      // Notificamos a la pantalla contenedora
      widget.onDramaAdded(newDrama);

      // 4. Limpiamos los campos y mostramos mensaje de éxito claro
      _titleController.clear();
      _descController.clear();
      _genreController.clear();
      _imageController.clear();
      setState(() {
        _episodesInputs.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡K-Drama publicado con éxito en la nube!"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      // Si ocurre un error de red o de permisos en Supabase
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al publicar. Verifica tu conexión e intenta de nuevo."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Subir Nuevo K-Drama", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF1493))),
          const SizedBox(height: 15),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Título del Dorama")),
          const SizedBox(height: 10),
          TextField(controller: _genreController, decoration: const InputDecoration(labelText: "Género (Romance, Comedia, Popular)")),
          const SizedBox(height: 10),
          TextField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: "Descripción")),
          const SizedBox(height: 10),
          TextField(controller: _imageController, decoration: const InputDecoration(labelText: "URL de la Imagen de Portada")),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Episodios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF1493)),
                onPressed: _addEpisodeField,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Añadir Episodio", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _episodesInputs.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text("Episodio ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextField(controller: _episodesInputs[index]['title'], decoration: const InputDecoration(labelText: "Título del episodio")),
                      TextField(controller: _episodesInputs[index]['duration'], decoration: const InputDecoration(labelText: "Duración (Ej: 52 min)")),
                      TextField(controller: _episodesInputs[index]['url'], decoration: const InputDecoration(labelText: "URL del Video MP4")),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1493),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: _submitDrama,
            child: const Text("PUBLICAR K-DRAMA", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}