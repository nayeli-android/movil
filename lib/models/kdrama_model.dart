class EpisodeModel {
  final String title;
  final String duration;
  final String videoUrl;

  EpisodeModel({
    required this.title,
    required this.duration,
    required this.videoUrl,
  });
}

class KdramaModel {
  final int? id;
  final String titulo;
  final String genero;
  final String descripcion;
  final String imagen;
  bool _isFav;
  double rating;
  final List<EpisodeModel> episodios;

  KdramaModel({
    this.id,
    required this.titulo,
    required this.genero,
    required this.descripcion,
    required this.imagen,
    bool isFav = false,
    this.rating = 4.5,
    required this.episodios,
  }) : _isFav = isFav;

  // Getter para isFav
  bool get isFav => _isFav;

  // Setter para isFav
  set isFav(bool value) {
    _isFav = value;
  }
}