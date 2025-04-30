import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_custom.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class Todo {
  final String id;
  final String title;
  bool completed;
  String priority;
  DateTime? dueDate;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.title,
    this.completed = false,
    this.priority = 'low',
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      completed: json['completed'] ?? false,
      priority: (json['priority'] ?? 'low').toLowerCase(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
////////////////////////////////////////////////////////////

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoScreen(),
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  TodoScreenState createState() => TodoScreenState();
}

class TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Todo> _todos = [];
  String _selectedPriority = 'low';
  DateTime? _selectedDueDate;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  Future<void> _fetchTodos() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:8080/api/todos'));
      if (response.statusCode == 200) {
        setState(() {
          _todos = (jsonDecode(response.body) as List)
              .map((item) => Todo.fromJson(item))
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load todos')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    }
  }

  Future<void> _searchTodos(String query) async {
    if (query.isEmpty) {
      _fetchTodos();
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:8080/api/todos/search?query=$query'),
    );
    if (response.statusCode == 200) {
      setState(() {
        _todos = (jsonDecode(response.body) as List)
            .map((item) => Todo.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> _showAddTodoDialog() async {
    _controller.clear();
    _selectedPriority = 'low';
    _selectedDueDate = null;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Todo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Todo Title',
                  hintText: 'Enter todo title',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                ),
                items: ['low', 'medium', 'high'].map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDueDate == null
                    ? 'Select Due Date'
                    : DateFormat('MMM d, y').format(_selectedDueDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDueDate = date;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_controller.text.isNotEmpty) {
                await _addTodo();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTodo() async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/api/todos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': _controller.text,
        'completed': false,
        'priority': _selectedPriority,
        'dueDate': _selectedDueDate?.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      _controller.clear();
      _fetchTodos();
    }
  }

  Future<void> _filterTodos({bool? completed, String? priority}) async {
    final queryParams = <String, String>{};
    if (completed != null) queryParams['completed'] = completed.toString();
    if (priority != null) queryParams['priority'] = priority;

    final response = await http.get(
      Uri.parse('http://localhost:8080/api/todos/filter').replace(
        queryParameters: queryParams,
      ),
    );
    if (response.statusCode == 200) {
      setState(() {
        _todos = (jsonDecode(response.body) as List)
            .map((item) => Todo.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> _completeMultipleTodos(List<String> ids) async {
    await http.put(
      Uri.parse('http://localhost:8080/api/todos/batch/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(ids),
    );
    _fetchTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search todos...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  _searchTodos(value);
                },
              )
            : const Text('Todo List'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _fetchTodos();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              switch (value) {
                case 'all':
                  _fetchTodos();
                  break;
                case 'completed':
                  _filterTodos(completed: true);
                  break;
                case 'pending':
                  _filterTodos(completed: false);
                  break;
                case 'high':
                  _filterTodos(priority: 'high');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'high', child: Text('High Priority')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () async {
              final response = await http.get(
                Uri.parse('http://localhost:8080/api/todos/stats'),
              );
              if (response.statusCode == 200) {
                final stats = jsonDecode(response.body);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Statistics'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: ${stats['total']}'),
                        Text('Completed: ${stats['completed']}'),
                        Text('Pending: ${stats['pending']}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration:
                            todo.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.completed ? 'Completed' : 'Incomplete',
                          style: TextStyle(
                            color: todo.completed ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildPriorityIcon(todo.priority),
                            if (todo.dueDate != null)
                              Text(
                                'Due: ${DateFormat('MMM d, y').format(todo.dueDate!)}',
                                style: TextStyle(color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ],
                    ),
                    leading: GestureDetector(
                      onTap: () async {
                        todo.completed = !todo.completed;
                        await http.put(
                          Uri.parse(
                              'http://localhost:8080/api/todos/${todo.id}'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode(todo.toJson()),
                        );
                        _fetchTodos();
                      },
                      child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: todo.completed ? Colors.green : Colors.red,
                          ),
                          child: todo.completed
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                )),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                          onPressed: () async {
                            final TextEditingController editController =
                                TextEditingController(text: todo.title);
                            final updatedTodo = await showDialog<Todo>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Edit Todo'),
                                content: TextField(
                                  controller: editController,
                                  decoration: const InputDecoration(
                                      hintText: 'Enter new title'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        Todo(
                                          id: todo.id,
                                          title: editController.text,
                                          completed: todo.completed,
                                          priority: todo.priority,
                                          dueDate: todo.dueDate,
                                          createdAt: todo.createdAt,
                                        ),
                                      );
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                            if (updatedTodo != null) {
                              await http.put(
                                Uri.parse(
                                    'http://localhost:8080/api/todos/${todo.id}'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode(updatedTodo.toJson()),
                              );
                              _fetchTodos();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text(
                                    'Are you sure you want to delete this todo?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await http.delete(
                                Uri.parse(
                                    'http://localhost:8080/api/todos/${todo.id}'),
                              );
                              _fetchTodos();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPriorityIcon(String priority) {
    final color = {
          'high': Colors.red,
          'medium': Colors.orange,
          'low': Colors.green,
        }[priority.toLowerCase()] ??
        Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
