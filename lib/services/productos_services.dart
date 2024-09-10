import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoritosService {
  final String baseUrl = 'http://137.184.190.92';

  Future<List<dynamic>> obtenerProductosFavoritos(int userId) async {
    // 1. Obtener todos los productos favoritos.
    final responseFavoritos = await http
        .get(Uri.parse('$baseUrl/productos_favoritos/productos_favoritos/'));
    if (responseFavoritos.statusCode != 200) {
      throw Exception('Error al obtener productos favoritos');
    }

    List<dynamic> productosFavoritos = json.decode(responseFavoritos.body);

    // 2. Filtrar los productos favoritos cuyo campo de usuario sea igual al userId.
    productosFavoritos = productosFavoritos
        .where((producto) => producto['usuario'] == userId)
        .toList();

    // 3. Hacer otro GET para obtener todos los productos.
    final responseProductos =
        await http.get(Uri.parse('$baseUrl/productos/productos/'));
    if (responseProductos.statusCode != 200) {
      throw Exception('Error al obtener todos los productos');
    }

    List<dynamic> productos = json.decode(responseProductos.body);

    // Convertir la lista de productos en un mapa para búsquedas más rápidas
    Map<int, dynamic> mapaProductos = {};
    for (var producto in productos) {
      mapaProductos[producto['id']] = producto;
    }

    // 4. Filtrar esos productos basados en el ID del producto obtenido en el paso 2.
    List<dynamic> productosResultantes = [];
    for (var favorito in productosFavoritos) {
      var productoFiltrado = mapaProductos[favorito['producto']];
      if (productoFiltrado != null) {
        productosResultantes.add(productoFiltrado);
      }
    }

    // 5. Devolver la lista filtrada.
    return productosResultantes;
  }
}
