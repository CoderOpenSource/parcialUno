import 'package:mapas_api/services/productos_services.dart';
import 'package:mapas_api/widgets/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  _FavoritosPageState createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  List<dynamic> displayedProducts = [];
  final FavoritosService favoritosService = FavoritosService();

  @override
  void initState() {
    super.initState();
    _cargarProductosFavoritos();
  }

  _cargarProductosFavoritos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.parse(prefs.getString('userId') ?? '0');
      List<dynamic> productos =
          await favoritosService.obtenerProductosFavoritos(userId);
      setState(() {
        displayedProducts = productos;
      });
    } catch (error) {
      print('Error al cargar productos favoritos: $error');
      // Considera mostrar un mensaje al usuario aquí.
    }
  }

  _eliminarProducto(int productId) {
    // Aquí puedes agregar el código para eliminar el producto.
    // Por ejemplo, hacer una llamada a una API, eliminar el producto de una lista, etc.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: const Text("Productos Favoritos",
            style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(10.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 1 / 1.5,
        ),
        itemCount: displayedProducts.length,
        itemBuilder: (context, index) {
          double precio =
              double.parse(displayedProducts[index]['precio'].toString());
          double descuento = double.parse(
              displayedProducts[index]['descuento_porcentaje'].toString());
          final discountedPrice = precio - (precio * (descuento / 100));

          return Card(
            elevation: 5.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Stack(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                            productId: displayedProducts[index]['id']),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        displayedProducts[index]['imagenes'][0]['ruta_imagen'],
                        fit: BoxFit.cover,
                        height: 100,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayedProducts[index]['nombre']
                            .replaceAll('Ã±', 'ñ'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Antes: Bs${displayedProducts[index]['precio']}',
                          style: const TextStyle(fontSize: 12)),
                      Text('Ahora: Bs$discountedPrice',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: PopupMenuButton(
                    onSelected: (value) {
                      if (value == "eliminar") {
                        _eliminarProducto(displayedProducts[index]['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "eliminar",
                        child: Text("Eliminar"),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
