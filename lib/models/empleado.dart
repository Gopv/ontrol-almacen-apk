class Empleado {
  final String id;
  final String nombre;
  final String rol;
  final bool bpmAprobado;

  Empleado({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.bpmAprobado,
  });

  factory Empleado.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Empleado(
      id: documentId,
      nombre: data['nombre'] ?? '',
      rol: data['rol'] ?? 'operario',
      bpmAprobado: data['bpmAprobado'] ?? false,
    );
  }
}