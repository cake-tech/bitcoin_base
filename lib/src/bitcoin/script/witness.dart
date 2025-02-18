import 'dart:typed_data';

import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';

class ScriptWitness {
  List<ByteData> stack;

  ScriptWitness({List<ByteData>? stack}) : stack = stack ?? [];

  bool isNull() {
    return stack.isEmpty;
  }
}

/// A list of the witness items required to satisfy the locking conditions of a segwit input (aka witness stack).
///
/// [stack] the witness items (hex str) list
class TxWitnessInput {
  TxWitnessInput({required List<String> stack, ScriptWitness? scriptWitness})
      : stack = stack.immutable,
        scriptWitness = scriptWitness ?? ScriptWitness();

  final List<String> stack;
  ScriptWitness scriptWitness;

  /// creates a copy of the object (classmethod)
  TxWitnessInput copy() {
    return TxWitnessInput(stack: stack);
  }

  /// returns a serialized byte version of the witness items list
  List<int> toBytes() {
    var stackBytes = <int>[];

    for (final item in stack) {
      final itemBytes = IntUtils.prependVarint(BytesUtils.fromHexString(item));
      stackBytes = [...stackBytes, ...itemBytes];
    }

    return stackBytes;
  }

  Map<String, dynamic> toJson() {
    return {'stack': stack};
  }

  @override
  String toString() {
    return "TxWitnessInput{stack: ${stack.join(", ")}}";
  }
}
