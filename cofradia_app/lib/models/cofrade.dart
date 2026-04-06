class Cofrade {
  final String id;
  final String nombre;
  final String apellidos;
  final String telefono;
  final String email;
  final String categoria; // seccion
  final String estado; // division
  final String agrupacion; // Rosario Viviente / Rosario Perpetuo
  final String fechaAlta; // yyyy-mm-dd
  /// URL pública de la foto (Supabase Storage u otro).
  final String fotoUrl;

  Cofrade({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.telefono,
    required this.email,
    required this.categoria,
    required this.estado,
    this.agrupacion = '',
    required this.fechaAlta,
    this.fotoUrl = '',
  });

  factory Cofrade.fromJson(Map<String, dynamic> json) {
    return Cofrade(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      agrupacion: json['agrupacion']?.toString() ?? '',
      fechaAlta: (json['fecha_alta'] ?? json['fechaAlta'])?.toString() ?? '',
      fotoUrl: json['foto_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'nombre': nombre,
      'apellidos': apellidos,
      'telefono': telefono,
      'email': email,
      'categoria': categoria,
      'estado': estado,
      'fecha_alta': fechaAlta,
    };
    if (agrupacion.isNotEmpty) data['agrupacion'] = agrupacion;
    data['foto_url'] = fotoUrl.isEmpty ? null : fotoUrl;

    // Para updates por Supabase no hace falta enviar `id`, pero lo dejamos
    // por compatibilidad si algún endpoint lo requiere.
    if (id.isNotEmpty) data['id'] = id;
    return data;
  }

  String get avatar {
    final n = nombre.isNotEmpty ? nombre[0] : '?';
    final a = apellidos.isNotEmpty ? apellidos[0] : '';
    return (n + a).toUpperCase();
  }

  Cofrade copyWith({
    String? id,
    String? nombre,
    String? apellidos,
    String? telefono,
    String? email,
    String? categoria,
    String? estado,
    String? agrupacion,
    String? fechaAlta,
    String? fotoUrl,
  }) {
    return Cofrade(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      categoria: categoria ?? this.categoria,
      estado: estado ?? this.estado,
      agrupacion: agrupacion ?? this.agrupacion,
      fechaAlta: fechaAlta ?? this.fechaAlta,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }
}
