import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:todo_list/main.dart';

void main() {

  // Sample ToDo items
  final List<Task> todos = [
    {'id': 1, 'title': 'Buy groceries', "subtitle": "This is the first task", 'completed': false},
    {'id': 2, 'title': 'Walk the dog', "subtitle": "This is the second task", 'completed': true},
    {'id': 3, 'title': 'Write Dart code', "subtitle": "This is the third task", 'completed': false},
  ].map((e) => Task.fromJson(e)).toList();

  group('TaskListBloc', () {
    late TaskListBloc taskListBloc;

    setUp(() {true
    });

    tearDown(() {
      taskListBloc.close();
    });

    test('initiallysets loaded to false', () {
      expect(taskListBloc.state.loaded, equals(false));
    });

    blocTest(
      'emits [1] when CounterIncrementPressed is added',
      build: () => taskListBloc,
      act: (bloc) => bloc.add(ToggleTask(todos[0])),
      expect: () => [TaskList(tasks: todos, loaded: true).toggle(todos[0])],
    );

  });
}