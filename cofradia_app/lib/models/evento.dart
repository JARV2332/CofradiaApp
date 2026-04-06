class Evento {
  final String id;
  final String nombre;
  final String descripcion;
  final String fecha;
  final String hora;
  final String lugar;
  final String tipo;
  final String estado;
  final int cupo;

  Evento({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fecha,
    required this.hora,
    required this.lugar,
    required this.tipo,
    required this.estado,
    required this.cupo,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      fecha: json['fecha'],
      hora: json['hora'],
      lugar: json['lugar'],
      tipo: json['tipo'],
      estado: json['estado'],
      cupo: json['cupo'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'nombre': nombre,
      'descripcion': descripcion,
      'fecha': fecha,
      'hora': hora,
      'lugar': lugar,
      'tipo': tipo,
      'estado': estado,
      'cupo': cupo,
    };

    // Para inserts por Supabase, el id viene por defecto (UUID).
    // Si el id viene vacío, no lo enviamos.
    if (id.isNotEmpty) {
      data['id'] = id;
    }

    return data;
  }

  String get fechaHora {
    return '$fecha $hora';
  }

  Evento copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? fecha,
    String? hora,
    String? lugar,
    String? tipo,
    String? estado,
    int? cupo,
  }) {
    return Evento(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      lugar: lugar ?? this.lugar,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      cupo: cupo ?? this.cupo,
    );
  }
}
