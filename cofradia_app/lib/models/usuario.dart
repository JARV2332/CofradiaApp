class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? cargo;
  final String? numeroCarnet;
  final String estado;
  final String rol;
  final DateTime fechaIngreso;
  final DateTime? fechaNacimiento;
  final String? direccion;
  final String? googleId;
  final bool esDirectiva;
  final DateTime fechaRegistro;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.cargo,
    this.numeroCarnet,
    required this.estado,
    required this.rol,
    required this.fechaIngreso,
    this.fechaNacimiento,
    this.direccion,
    this.googleId,
    this.esDirectiva = false,
    DateTime? fechaRegistro,
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      telefono: json['telefono'],
      cargo: json['cargo'],
      numeroCarnet: json['numero_carnet'],
      estado: json['estado'] ?? 'activo',
      rol: json['rol'] ?? 'usuario',
      fechaIngreso: json['fecha_ingreso'] != null 
          ? DateTime.parse(json['fecha_ingreso'])
          : DateTime.now(),
      fechaNacimiento: json['fecha_nacimiento'] != null 
          ? DateTime.parse(json['fecha_nacimiento'])
          : null,
      direccion: json['direccion'],
      googleId: json['google_id'],
      esDirectiva: json['es_directiva'] ?? false,
      fechaRegistro: json['fecha_registro'] != null 
          ? DateTime.parse(json['fecha_registro'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'cargo': cargo,
      'numero_carnet': numeroCarnet,
      'estado': estado,
      'rol': rol,
      'fecha_ingreso': fechaIngreso.toIso8601String(),
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'direccion': direccion,
      'google_id': googleId,
      'es_directiva': esDirectiva,
      'fecha_registro': fechaRegistro.toIso8601String(),
    };
  }
}
