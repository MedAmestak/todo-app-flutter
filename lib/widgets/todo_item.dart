import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final Function(Todo) onToggleComplete;
  final Function(Todo) onEdit;
  final Function(Todo) onDelete;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
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
          onTap: () {
            // print(
            //     'Toggling completion for: \\${todo.id}, was: \\${todo.completed}');
            final updatedTodo = Todo(
              id: todo.id,
              title: todo.title,
              completed: !todo.completed,
              priority: todo.priority,
              dueDate: todo.dueDate,
              createdAt: todo.createdAt,
            );
            onToggleComplete(updatedTodo);
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: todo.completed ? Colors.green : Colors.red,
            ),
            child: Center(
              child: Icon(
                todo.completed ? Icons.check : Icons.close,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 20,
              onPressed: () => onEdit(todo),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 20,
              onPressed: () => onDelete(todo),
            ),
          ],
        ),
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
}
