class Sucursal {
  final int id;
  final String nombre;
  final String direccion;
  final String telefono;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      telefono: json['telefono'],
    );
  }
}
