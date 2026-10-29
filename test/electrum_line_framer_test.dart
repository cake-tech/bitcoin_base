import 'dart:async';
import 'dart:convert';

import 'package:bitcoin_base/src/provider/service/electrum/params.dart';
import 'package:bitcoin_base/src/provider/service/electrum/service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

List<int> line(Map<String, dynamic> message) => utf8.encode("${json.encode(message)}\n");

void main() {
  group("ElectrumLineFramer", () {
    late List<Map<String, dynamic>> received;
    late ElectrumLineFramer framer;

    setUp(() {
      received = [];
      framer = ElectrumLineFramer(received.add);
    });

    test("decodes several messages from one chunk", () {
      framer.add([...line({"id": 1}), ...line({"id": 2})]);

      expect(received, [
        {"id": 1},
        {"id": 2},
      ]);
    });

    test("reassembles a message split at every byte", () {
      final bytes = [...line({"id": 1, "result": "x" * 500}), ...line({"id": 2})];

      for (final byte in bytes) {
        framer.add([byte]);
      }

      expect(received.map((m) => m["id"]), [1, 2]);
      expect(received.first["result"], "x" * 500);
    });

    test("waits for the newline before dispatching", () {
      final bytes = line({"id": 1});

      framer.add(bytes.sublist(0, bytes.length - 1));
      expect(received, isEmpty);

      framer.add([0x0A]);
      expect(received, [
        {"id": 1}
      ]);
    });

    test("expands a batch response", () {
      framer.add(utf8.encode('[{"id":1},{"id":2}]\n'));

      expect(received.map((m) => m["id"]), [1, 2]);
    });

    test("a bad line only loses itself", () {
      framer.add(utf8.encode('{"id":1, garbage\n'));
      framer.add(line({"id": 2}));

      expect(received, [
        {"id": 2}
      ]);
    });

    // Regression: a handler that threw while handling a message split across
    // reads used to leave that message in the reassembly buffer forever, so
    // every later multi-read message was appended to it and silently lost.
    test("a throwing handler does not poison later messages", () {
      final seen = <int>[];
      final throwing = ElectrumLineFramer((message) {
        seen.add(message["id"] as int);
        if (message["id"] == 1) {
          throw StateError("Cannot add new events after calling close");
        }
      });

      final first = line({"id": 1, "result": "done"});
      final second = line({"id": 2, "result": "y" * 1000});
      throwing.add(first.sublist(0, 10));
      throwing.add([...first.sublist(10), ...second.sublist(0, 20)]);
      throwing.add(second.sublist(20));

      expect(seen, [1, 2]);
    });
  });

  group("failSocketTasks", () {
    test("errors and closes open subscriptions and pending calls", () async {
      final request = ElectrumRequestDetails(id: 1, params: {}, method: "m");
      final subject = BehaviorSubject<dynamic>();
      final completer = Completer<dynamic>();
      final closedSubject = BehaviorSubject<dynamic>();
      await closedSubject.close();

      final tasks = <int, SocketTask>{
        1: SocketTask(isSubscription: true, request: request, subject: subject),
        2: SocketTask(isSubscription: false, request: request, completer: completer),
        3: SocketTask(isSubscription: true, request: request, subject: closedSubject),
      };

      final errors = <Object>[];
      var done = false;
      subject.listen((_) {}, onError: errors.add, onDone: () => done = true);
      final callError = completer.future.then<Object?>((_) => null, onError: (Object e) => e);

      failSocketTasks(tasks, const SocketClosed());
      await Future<void>.delayed(Duration.zero);

      expect(tasks, isEmpty);
      expect(errors, [isA<SocketClosed>()]);
      expect(done, isTrue);
      expect(await callError, isA<SocketClosed>());
    });
  });
}

class SocketClosed implements Exception {
  const SocketClosed();
}
