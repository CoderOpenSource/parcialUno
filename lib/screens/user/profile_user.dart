import 'dart:convert';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/widgets/mis_compras.dart';
import 'package:mapas_api/widgets/reserva_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: const Text("Perfil de Usuario",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final userData = snapshot.data!;

            return Column(
              children: <Widget>[
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (userData['foto_perfil'] != null) {
                        _showImagePreview(context, userData['foto_perfil']);
                      }
                    },
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage: userData['foto_perfil'] != null
                          ? NetworkImage(userData['foto_perfil'])
                          : null, // Si no hay foto de perfil, se usa 'null' para el backgroundImage
                      backgroundColor: const Color(0xFF1E272E),
                      child: userData['foto_perfil'] == null
                          ? Icon(
                              Icons.person, // Ícono clásico de perfil
                              size: 80,
                              color: Colors.white,
                            )
                          : null, // Si hay foto de perfil, no se muestra ningún ícono
                    ),
                  ),
                ),
                ListTile(
                  title: const Text(
                    "Nombre:",
                    style: TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    userData['first_name'],
                    style: const TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  leading: const Icon(
                    Icons.person,
                    color: const Color(0xFF1E272E),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6,
                      color: const Color(0xFF1E272E)),
                  title: const Text(
                    "Tema",
                    style: TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    // Acción para cambiar tema
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined,
                      color: const Color(0xFF1E272E)),
                  title: const Text(
                    "Mis Reservas",
                    style: TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ReservaScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_food_beverage_sharp,
                      color: const Color(0xFF1E272E)),
                  title: const Text(
                    "Mis Compras",
                    style: TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsView2(),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color(0xFF1E272E)),
                    ),
                    onPressed: () {
                      _showLogoutConfirmation(context);
                    },
                    child: const Text(
                      "Cerrar sesión",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Algo salió mal.'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    print('$userId--------------------------------------');
    if (userId == null) {
      throw Exception("User ID not found");
    }
    final response = await http
        .get(Uri.parse('http://137.184.190.92/users/usuarios-cliente/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user data');
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(ctx);
          },
          child: Container(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration:
                  const BoxDecoration(color: const Color(0xFF1E272E)),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _logout(context);
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove the stored preferences
    prefs.remove('accessToken');
    prefs.remove('accessRefresh');
    prefs.remove('userId');

    // Navigate to the login page and remove all other screens from the navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) =>
            const LoginView(), // Assuming your login view is named LoginView
      ),
      (Route<dynamic> route) => false, // This will remove all other screens
    );
  }
}
