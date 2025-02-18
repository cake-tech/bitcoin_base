import 'dart:async';
import 'package:rxdart/rxdart.dart';

class AsyncRequestCompleter<T> {
  AsyncRequestCompleter(this.params);
  final Completer<T> completer = Completer<T>();
  final Map<String, dynamic> params;
}

class AsyncBehaviorSubject<T> {
  AsyncBehaviorSubject(this.params);
  final BehaviorSubject<T> subscription = BehaviorSubject<T>();
  final Map<String, dynamic> params;
}
