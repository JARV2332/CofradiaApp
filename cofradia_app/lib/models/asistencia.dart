import '../models/evento.dart';
import '../models/cofrade.dart';

class Asistencia {
  final String id;
  final Evento evento;
  final Cofrade cofrade;
  final String estado;

  Asistencia({
    required this.id,
    required this.evento,
    required this.cofrade,
    required this.estado,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['id'],
      evento: Evento.fromJson(json['evento']),
      cofrade: Cofrade.fromJson(json['cofrade']),
      estado: json['estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'evento': evento.toJson(),
      'cofrade': cofrade.toJson(),
      'estado': estado,
    };
  }

  Asistencia copyWith({
    String? id,
    Evento? evento,
    Cofrade? cofrade,
    String? estado,
  }) {
    return Asistencia(
      id: id ?? this.id,
      evento: evento ?? this.evento,
      cofrade: cofrade ?? this.cofrade,
      estado: estado ?? this.estado,
    );
  }
}
