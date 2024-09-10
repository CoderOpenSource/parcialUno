import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String email;
  final String fotoPerfil;
  final String
      modo; // Esto parece ser el rol del usuario (ejemplo: "Conductor")
  final String nombre;
  final String telefono;

  User({
    required this.email,
    required this.fotoPerfil,
    required this.modo,
    required this.nombre,
    required this.telefono,
  });

  // Método para convertir un documento de Firestore a un objeto User
  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      email: doc['email'] ?? '',
      fotoPerfil: doc['fotoPerfil'] ?? '',
      modo: doc['modo'] ?? '',
      nombre: doc['nombre'] ?? '',
      telefono: doc['telefono'] ?? '',
    );
  }

  // Método para convertir un objeto User a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fotoPerfil': fotoPerfil,
      'modo': modo,
      'nombre': nombre,
      'telefono': telefono,
    };
  }
}
