import 'dart:io';
import 'dart:convert'; // Import for JSON encoding

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final _router =
    Router()
      ..get('/', _rootHandler)
      ..get('/echo/<message>', _echoHandler)
      ..get('/todos', _todosHandler) // Add the new route
      ..post('/todos/update', _updateTodoHandler); // Add the new POST route

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

// Sample ToDo items
final Map<String, List<Map<String, Object>>> _todos = {
  'tasks': [
    {
      'id': 1,
      'title': 'Buy groceries',
      "subtitle": "This is the first task",
      'completed': false,
    },
    {
      'id': 2,
      'title': 'Walk the dog',
      "subtitle": "This is the second task",
      'completed': true,
    },
    {
      'id': 3,
      'title': 'Write Dart code',
      "subtitle": "This is the third task",
      'completed': false,
    },
  ],
};

// New handler for the /todos route
Response _todosHandler(Request req) {
  final jsonResponse = jsonEncode(_todos);
  return Response.ok(
    jsonResponse,
    headers: {'Content-Type': 'application/json'},
  );
}

// Handler for updating a ToDo item's completed status
Future<Response> _updateTodoHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = jsonDecode(payload) as Map<String, dynamic>;

    if (data.containsKey('id') && data.containsKey('completed')) {
      final id = data['id'] as int;
      final completed = data['completed'] as bool;

      final task = _todos['tasks']?.firstWhere(
        (todo) => todo['id'] == id,
        orElse: () => {},
      );
      if (task != null) {
        task['completed'] = completed;
        return Response.ok(
          jsonEncode({'status': 'success', 'task': task}),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.notFound(
          jsonEncode({'error': 'Task not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } else {
      return Response.badRequest(
        body: jsonEncode({'error': 'Invalid request payload'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'An error occurred', 'details': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

void startServer(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8000');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
