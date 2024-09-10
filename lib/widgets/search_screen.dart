import 'package:mapas_api/widgets/product_detail.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? _searchQuery;
  late FocusNode _focusNode;
  late TextEditingController _textController;
  List<Map<String, dynamic>> allProducts = [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textController = TextEditingController();
    _loadProducts();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _loadProducts() async {
    final productsResponse =
        await http.get(Uri.parse('http://161.35.16.6/productos/productos/'));

    if (productsResponse.statusCode == 200) {
      setState(() {
        allProducts = (json.decode(productsResponse.body) as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      });
    } else {
      // Puedes manejar un error aquí si lo deseas.
      print('Error al obtener productos: ${productsResponse.statusCode}');
    }
  }

  List<Map<String, dynamic>> get _results {
    List<Map<String, dynamic>> filteredResults;

    if (_searchQuery == null || _searchQuery!.isEmpty) {
      filteredResults = allProducts;
    } else {
      filteredResults = allProducts
          .where((product) => product['nombre']
              .replaceAll('Ã±', 'ñ')
              .toLowerCase()
              .contains(_searchQuery!.toLowerCase()))
          .toList();
    }

    // Aquí se limitan los resultados a 7 elementos
    if (filteredResults.length > 7) {
      return filteredResults.sublist(0, 7);
    } else {
      return filteredResults;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          margin: const EdgeInsets.symmetric(
              vertical: 8.0, horizontal: 0), // margen para dar espacio
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            controller: _textController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10.0, vertical: 5.0), // ajusta a tu preferencia
              hintText: 'Buscar productos',
              prefixIcon: const Icon(
                Icons.search,
                color: Color.fromARGB(255, 150, 146, 146),
              ),
              suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            focusNode: _focusNode,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_results[index]['nombre'].replaceAll('Ã±', 'ñ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    productId: _results[index]['id'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
