import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../widgets/todo_item.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  TodoScreenState createState() => TodoScreenState();
}

class TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TodoService _todoService = TodoService();
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
    //print("Fetching todos...");

    try {
      final todos = await _todoService.getAllTodos();
      setState(() {
        _todos = todos;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load todos');
    }
  }

  Future<void> _searchTodos(String query) async {
    if (query.isEmpty) {
      _fetchTodos();
      return;
    }

    try {
      final todos = await _todoService.searchTodos(query);
      setState(() {
        _todos = todos;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to search todos');
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
    try {
      final todo = Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _controller.text,
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
      );
      await _todoService.createTodo(todo);
      _controller.clear();
      _fetchTodos();
    } catch (e) {
      _showErrorSnackBar('Failed to add todo');
    }
  }

  Future<void> _filterTodos({bool? completed, String? priority}) async {
    try {
      final todos = await _todoService.filterTodos(
        completed: completed,
        priority: priority,
      );
      setState(() {
        _todos = todos;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to filter todos');
    }
  }

  Future<void> _showEditDialog(Todo todo) async {
    final TextEditingController editController =
        TextEditingController(text: todo.title);
    final updatedTodo = await showDialog<Todo>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Todo'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'Enter new title'),
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
      try {
        await _todoService.updateTodo(todo.id, updatedTodo);
        _fetchTodos();
      } catch (e) {
        _showErrorSnackBar('Failed to update todo');
      }
    }
  }

  Future<void> _showDeleteConfirmation(Todo todo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this todo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _todoService.deleteTodo(todo.id);
        _fetchTodos();
      } catch (e) {
        _showErrorSnackBar('Failed to delete todo');
      }
    }
  }

  Future<void> _showStatistics() async {
    try {
      final stats = await _todoService.getStatistics();
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
    } catch (e) {
      _showErrorSnackBar('Failed to get statistics');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                onChanged: _searchTodos,
              )
            : const Text('Todo List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTodos,
          ),
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
            onPressed: _showStatistics,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          final todo = _todos[index];
          return TodoItem(
            todo: todo,
            onToggleComplete: (updatedTodo) async {
              try {
                await _todoService.updateTodo(updatedTodo.id, updatedTodo);
                _fetchTodos();
              } catch (e) {
                _showErrorSnackBar('Failed to update todo');
              }
            },
            onEdit: _showEditDialog,
            onDelete: _showDeleteConfirmation,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
