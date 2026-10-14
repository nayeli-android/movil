import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kdrama_model.dart';
import 'video_player_screen.dart';

class KdramaDetailScreen extends StatefulWidget {
  final KdramaModel drama;
  const KdramaDetailScreen({super.key, required this.drama});

  @override
  State<KdramaDetailScreen> createState() => _KdramaDetailScreenState();
}

class _KdramaDetailScreenState extends State<KdramaDetailScreen> {
  void _showFloatingMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  // Función para actualizar favoritos y guardarlo en Supabase
  Future<void> _toggleFavorite() async {
    setState(() => widget.drama.isFav = !widget.drama.isFav);
    
    try {
      await Supabase.instance.client
          .from('kdramas')
          .update({'isFav': widget.drama.isFav})
          .eq('id', widget.drama.id!);

      _showFloatingMessage(
        widget.drama.isFav ? "Añadido a Mi Lista" : "Quitado de Mi Lista", 
        Colors.pinkAccent,
      );
    } catch (e) {
      debugPrint("Error al actualizar favorito en la nube: $e");
    }
  }

  // Función para calificar y guardar el rating en Supabase
  Future<void> _updateRating(double newRating) async {
    setState(() => widget.drama.rating = newRating);

    try {
      await Supabase.instance.client
          .from('kdramas')
          .update({'rating': newRating})
          .eq('id', widget.drama.id!);

      _showFloatingMessage("¡Calificado con ${newRating.toStringAsFixed(1)} estrellas!", Colors.green);
    } catch (e) {
      debugPrint("Error al actualizar calificación en la nube: $e");
    }
  }

  void _showRateDialog() {
    double currentRating = widget.drama.rating;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Calificar K-Drama"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Puntuación actual: ${currentRating.toStringAsFixed(1)} ⭐", style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: currentRating,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              activeColor: const Color(0xFFFF1493),
              onChanged: (value) {
                setState(() => currentRating = value);
              },
              onChangeEnd: (value) {
                Navigator.pop(context);
                _updateRating(value); // Guarda en Supabase al soltar el slider
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.drama.titulo),
        actions: [
          IconButton(
            icon: Icon(widget.drama.isFav ? Icons.favorite : Icons.favorite_border, color: Colors.white),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(image: NetworkImage(widget.drama.imagen), fit: BoxFit.cover),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.drama.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text("${widget.drama.rating.toStringAsFixed(1)} ⭐", style: const TextStyle(color: Colors.white70)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFF1493), borderRadius: BorderRadius.circular(6)),
                          child: Text(widget.drama.genero, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(widget.drama.descripcion, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ActionButton(
                    icon: widget.drama.isFav ? Icons.check : Icons.add,
                    label: "Mi Lista",
                    onTap: _toggleFavorite,
                  ),
                  _ActionButton(icon: Icons.star_rate, label: "Calificar", onTap: _showRateDialog),
                  _ActionButton(icon: Icons.share, label: "Compartir", onTap: () => _showFloatingMessage("Enlace copiado", Colors.blueAccent)),
                ],
              ),
            ),
            const Divider(height: 30, thickness: 1, indent: 16, endIndent: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("Episodios Disponibles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF1493))),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.drama.episodios.length,
              itemBuilder: (context, index) {
                final ep = widget.drama.episodios[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFF1493).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.play_arrow, color: Color(0xFFFF1493)),
                    ),
                    title: Text("Episodio ${index + 1}: ${ep.title}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Duración: ${ep.duration}", style: const TextStyle(color: Colors.black54)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFFF1493)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(episodeTitle: ep.title, videoUrl: ep.videoUrl))),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF1493), size: 26),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF1493))),
          ],
        ),
      ),
    );
  }
}