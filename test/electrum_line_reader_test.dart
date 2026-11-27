import 'dart:async';
import 'dart:convert';

import 'package:bitcoin_base/src/provider/service/electrum/electrum_line_reader.dart';
import 'package:bitcoin_base/src/provider/service/electrum/params.dart';
import 'package:bitcoin_base/src/provider/service/electrum/service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

List<int> line(Map<String, dynamic> message) => utf8.encode("${json.encode(message)}\n");

void main() {
  group("ElectrumLineReader with dispatchElectrumLine", () {
    late List<Map<String, dynamic>> received;
    late ElectrumLineReader reader;

    void add(List<int> chunk, [void Function(Map<String, dynamic>)? onMessage]) {
      for (final lineText in reader.feed(chunk)) {
        dispatchElectrumLine(lineText, onMessage ?? received.add);
      }
    }

    setUp(() {
      received = [];
      reader = ElectrumLineReader();
    });

    test("decodes several messages from one chunk", () {
      add([...line({"id": 1}), ...line({"id": 2})]);

      expect(received, [
        {"id": 1},
        {"id": 2},
      ]);
    });

    test("reassembles a message split at every byte", () {
      final bytes = [...line({"id": 1, "result": "x" * 500}), ...line({"id": 2})];

      for (final byte in bytes) {
        add([byte]);
      }

      expect(received.map((m) => m["id"]), [1, 2]);
      expect(received.first["result"], "x" * 500);
    });

    test("waits for the newline before dispatching", () {
      final bytes = line({"id": 1});

      add(bytes.sublist(0, bytes.length - 1));
      expect(received, isEmpty);

      add([0x0A]);
      expect(received, [
        {"id": 1}
      ]);
    });

    test("expands a batch response", () {
      add(utf8.encode('[{"id":1},{"id":2}]\n'));

      expect(received.map((m) => m["id"]), [1, 2]);
    });

    test("a bad line only loses itself", () {
      add(utf8.encode('{"id":1, garbage\n'));
      add(line({"id": 2}));

      expect(received, [
        {"id": 2}
      ]);
    });

    test("a multi-byte character split across chunks is decoded whole", () {
      final bytes = line({"id": 1, "result": "€"});
      final euro = bytes.indexOf(0xE2);

      add(bytes.sublist(0, euro + 1));
      add(bytes.sublist(euro + 1));

      expect(received.single["result"], "€");
    });

    // Regression: a handler that threw while handling a message split across
    // reads used to leave that message in the reassembly buffer forever, so
    // every later multi-read message was appended to it and silently lost.
    test("a throwing handler does not poison later messages", () {
      final seen = <int>[];
      void throwing(Map<String, dynamic> message) {
        seen.add(message["id"] as int);
        if (message["id"] == 1) {
          throw StateError("Cannot add new events after calling close");
        }
      }

      final first = line({"id": 1, "result": "done"});
      final second = line({"id": 2, "result": "y" * 1000});
      add(first.sublist(0, 10), throwing);
      add([...first.sublist(10), ...second.sublist(0, 20)], throwing);
      add(second.sublist(20), throwing);

      expect(seen, [1, 2]);
    });

    test("reset drops a half-read line from a dropped connection", () {
      final bytes = line({"id": 1, "result": "abc"});
      add(bytes.sublist(0, 8));

      reader.reset();
      add(line({"id": 2}));

      expect(received, [
        {"id": 2}
      ]);
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
