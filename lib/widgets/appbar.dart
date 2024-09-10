import 'package:mapas_api/widgets/search_screen.dart';
import 'package:flutter/material.dart';

class AppBarActiTone extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onStoreIconPressed;

  const AppBarActiTone({Key? key, this.onStoreIconPressed}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1E272E),
      title: Row(
        children: [
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
