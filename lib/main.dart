import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_list/server.dart';

part "main.g.dart";

void main() {
  startServer([]); // Start the server in the background
  Bloc.observer = LoggingBlocObserver();
  runApp(BlocProvider(create: (_) => TaskListBloc(), child: MainApp()));
}

class TaskListDataProvider {
  static const rootUrl = "http://localhost:8000";
  final getUrl = Uri.parse("$rootUrl/todos");
  final updateUrl = Uri.parse("$rootUrl/todos/update");

  Future<TaskList> getTaskListString() async {
    final response = await http.get(getUrl);
    if (response.statusCode == 200) {
      return TaskList.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<bool> setCompleted(int id, bool completed) async {
    final response = await http.post(
      updateUrl,
      body: jsonEncode({"id": id, "completed": completed}),
      headers: {"Content-Type": "application/json"},
    );
    return response.statusCode == 200;
  }
}

class TaskListCubit extends Cubit<TaskList> {
  final TaskListDataProvider dataProvider = TaskListDataProvider();

  TaskListCubit() : super(TaskList(loaded: false)) {
    dataProvider.getTaskListString().then((value) {
      emit(value);
    });
  }

  void toggleTask(Task task) {
    final completed = !task.completed;
    dataProvider.setCompleted(task.id, completed).then((value) {
      if (value) {
        emit(state.toggle(task));
      }
    });
  }
}

sealed class TaskListEvent {}

class LoadTasks extends TaskListEvent {}

class ToggleTask extends TaskListEvent {
  final Task task;

  ToggleTask(this.task);
}

class TaskListBloc extends Bloc<TaskListEvent, TaskList> {
  final TaskListDataProvider dataProvider = TaskListDataProvider();

  TaskListBloc() : super(TaskList(loaded: false)) {
    on<LoadTasks>((event, emit) async {
      await dataProvider.getTaskListString().then((value) {
        emit(value);
      });
    });

    on<ToggleTask>((event, emit) async {
      final completed = !event.task.completed;
      await dataProvider.setCompleted(event.task.id, completed).then((value) {
        if (value) {
          emit(state.toggle(event.task));
        }
      });
    });

    add(LoadTasks());
  }
}

class LoggingBlocObserver extends BlocObserver {
  // @override
  // void onChange(BlocBase bloc, Change change) {
  //   super.onChange(bloc, change);
  //   if(bloc.runtimeType == TaskListCubit) {
  //     print("TaskListCubit - TaskList: ${change.nextState.toString()}");
  //   }
  // }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    print(event);
  }
}

@JsonSerializable()
class TaskList {
  List<Task> tasks;
  bool loaded;

  TaskList({this.tasks = const [], this.loaded = true});
  factory TaskList.fromJson(Map<String, dynamic> json) =>
      _$TaskListFromJson(json);
  Map<String, dynamic> toJson() => _$TaskListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

  TaskList toggle(Task task) {
    return TaskList(
      tasks: tasks.map((t) => t == task ? (t..toggle()) : t).toList(),
    );
  }
}

@JsonSerializable()
class Task {
  final int id;
  final String title;
  final String subtitle;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.subtitle,
    this.completed = false,
  });
  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

  void toggle() {
    completed = !completed;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: TextTheme(
          titleMedium: TextStyle(color: Colors.deepOrange, fontSize: 24),
          bodyMedium: TextStyle(color: Colors.deepOrange, fontSize: 16),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.flutter_dash),
          title: Text("ToDo List"),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        body: ToDoListBody(),
      ),
    );
  }
}

class ToDoListBody extends StatelessWidget {
  const ToDoListBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskListBloc, TaskList>(
      builder:
          (context, taskList) => Padding(
            padding: EdgeInsets.only(top: 64),
            child: Center(
              child:
                  taskList.loaded
                      ? SizedBox(
                        width: 450,
                        child: ListView(
                          children:
                              taskList.tasks
                                  .map((task) => TaskTile(task: task))
                                  .toList(),
                        ),
                      )
                      : CircularProgressIndicator(color: Colors.deepOrange),
            ),
          ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({super.key, required this.task});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        onPressed: () => {context.read<TaskListBloc>().add(ToggleTask(task))},
        icon: Icon(
          task.completed ? Icons.check_circle : Icons.circle_outlined,
          color: Colors.deepOrange,
        ),
        color: Colors.deepOrange,
      ),
      title: Text(task.title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        task.subtitle,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
