import 'dart:convert';
import 'package:http/http.dart' as http;

class AbastecimientoService {
  final String baseUrl = "http://localhost:3000/api/abastecimientos";

  Future<List<dynamic>> listar() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al listar abastecimientos");
    }
  }

  Future<Map<String, dynamic>> obtener(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener abastecimiento");
    }
  }

  Future<void> crear(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) {
      throw Exception("Error al crear abastecimiento");
    }
  }

  Future<void> actualizar(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception("Error al actualizar abastecimiento");
    }
  }

  Future<void> eliminar(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200) {
      throw Exception("Error al eliminar abastecimiento");
    }
  }
}

