import 'package:mapas_api/widgets/favoritos_page.dart';
import 'package:mapas_api/widgets/search_screen.dart';
import 'package:flutter/material.dart';

class AppBarActiTone2 extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onStoreIconPressed;
  const AppBarActiTone2({Key? key, this.onStoreIconPressed}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white), // Ícono blanco
          onPressed: () => Scaffold.of(context).openDrawer(), // Abrir Drawer
        ),
      ),
      backgroundColor: const Color(0xFF1E272E),
      title: Row(
        children: [
          SizedBox(
            width: 36,
            child: IconButton(
              icon: const Icon(
                Icons.store,
                color: Colors.white,
                size: 30,
              ),
              onPressed: onStoreIconPressed,
            ),
          ),
          const SizedBox(width: 10), // Espacio entre el icono y el TextField
          Expanded(
            child: GestureDetector(
              // <- Agrega el GestureDetector aquí
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: TextField(
                decoration: InputDecoration(
                  enabled: false,
                  hintText: 'Buscar productos',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.favorite, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritosPage()),
            );
          },
        ),
        /*IconButton(
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          onPressed: () {
            // TODO: Navigate to cart screen
          },
        ),*/
      ],
    );
  }
}
