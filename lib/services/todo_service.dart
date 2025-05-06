import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/todo.dart';

class TodoService {
  static const String baseUrl = 'http://localhost:8080/api/todos';

  Future<List<Todo>> getAllTodos() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((item) => Todo.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load todos');
  }

  Future<List<Todo>> searchTodos(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search?query=$query'),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((item) => Todo.fromJson(item))
          .toList();
    }
    throw Exception('Failed to search todos');
  }

  Future<List<Todo>> filterTodos({bool? completed, String? priority}) async {
    final queryParams = <String, String>{};
    if (completed != null) queryParams['completed'] = completed.toString();
    if (priority != null) queryParams['priority'] = priority;

    final response = await http.get(
      Uri.parse('$baseUrl/filter').replace(queryParameters: queryParams),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((item) => Todo.fromJson(item))
          .toList();
    }
    throw Exception('Failed to filter todos');
  }

  Future<Todo> createTodo(Todo todo) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(todo.toJson()),
    );
    if (response.statusCode == 200) {
      return Todo.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create todo');
  }

  Future<Todo> updateTodo(String id, Todo todo) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(todo.toJson()),
    );
    if (response.statusCode == 200) {
      return Todo.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update todo');
  }

  Future<void> deleteTodo(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete todo');
    }
  }

  Future<void> completeMultipleTodos(List<String> ids) async {
    final response = await http.put(
      Uri.parse('$baseUrl/batch/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(ids),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to complete todos');
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final response = await http.get(Uri.parse('$baseUrl/stats'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get statistics');
  }
}
