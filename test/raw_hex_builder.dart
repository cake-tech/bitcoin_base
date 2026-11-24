/// Builds raw transaction hex by hand. The tests use it so the bytes under test
/// (scriptSig shape, witness layout, varint lengths, the MWEB extension) are
/// written out explicitly, instead of coming back through this library's own
/// serializer, which could hide the same mistake on both sides.
library;

String _le(int value, int bytes) {
  final out = StringBuffer();
  for (var i = 0; i < bytes; i++) {
    out.write(((value >> (8 * i)) & 0xff).toRadixString(16).padLeft(2, '0'));
  }
  return out.toString();
}

String varint(int n) {
  if (n < 0xfd) {
    return _le(n, 1);
  }
  if (n <= 0xffff) {
    return 'fd${_le(n, 2)}';
  }
  return 'fe${_le(n, 4)}';
}

String _push(String hex) => varint(hex.length ~/ 2) + hex;

/// A txid as displayed (big-endian hex) becomes little-endian bytes on the wire.
String _txidOnWire(String txid) {
  final bytes = <String>[];
  for (var i = 0; i < txid.length; i += 2) {
    bytes.add(txid.substring(i, i + 2));
  }
  return bytes.reversed.join();
}

class RawInput {
  RawInput({
    required this.txid,
    this.index = 0,
    this.scriptSig = '',
    this.sequence = 0xffffffff,
  });

  final String txid;
  final int index;

  /// Raw script bytes as hex, without the length prefix.
  final String scriptSig;
  final int sequence;
}

class RawOutput {
  RawOutput({required this.amount, required this.scriptPubKey});

  final int amount;

  /// Raw script bytes as hex, without the length prefix.
  final String scriptPubKey;
}

/// Serializes a transaction. [witnesses] adds the segwit marker and flag and
/// writes one witness stack per input, an empty list meaning no witness. [mweb]
/// is raw extension bytes, written before the locktime and flagged with 0x08.
String rawTxHex({
  required List<RawInput> inputs,
  required List<RawOutput> outputs,
  int version = 2,
  List<List<String>>? witnesses,
  String mweb = '',
  int locktime = 0,
}) {
  final segwit = witnesses != null;
  final hasMweb = mweb.isNotEmpty;
  final buf = StringBuffer(_le(version, 4));

  if (segwit || hasMweb) {
    final flag = (segwit ? 1 : 0) | (hasMweb ? 8 : 0);
    buf.write('00${_le(flag, 1)}');
  }

  buf.write(varint(inputs.length));
  for (final input in inputs) {
    buf
      ..write(_txidOnWire(input.txid))
      ..write(_le(input.index, 4))
      ..write(_push(input.scriptSig))
      ..write(_le(input.sequence, 4));
  }

  buf.write(varint(outputs.length));
  for (final output in outputs) {
    buf
      ..write(_le(output.amount, 8))
      ..write(_push(output.scriptPubKey));
  }

  if (segwit) {
    if (witnesses.length != inputs.length) {
      throw ArgumentError('one witness stack per input');
    }
    for (final stack in witnesses) {
      buf.write(varint(stack.length));
      for (final item in stack) {
        buf.write(_push(item));
      }
    }
  }

  if (hasMweb) {
    buf.write(mweb);
  }
  buf.write(_le(locktime, 4));
  return buf.toString();
}
