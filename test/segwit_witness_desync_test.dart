import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

String _toHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// A hex string of exactly [byteLength] bytes, built from [nibble] - avoids
/// hand-typed repeated-character literals silently being the wrong length.
String _hexOf(int byteLength, String nibble) => nibble * (byteLength * 2);

void main() {
  group('BtcTransaction.fromRaw - witness/scriptSig desync regression', () {
    // Per BIP144, once the segwit marker+flag is set, EVERY input gets
    // exactly one witness field - including a legacy/P2SH-wrapped input
    // whose actual unlock data lives in a non-empty scriptSig rather than
    // (only) in the witness. `fromRaw` used to `continue` (skip reading a
    // witness entry entirely) for any input with a non-empty scriptSig,
    // which desyncs the cursor for every witness read after it - dropping
    // or corrupting the witness data of every subsequent input.
    test(
        'reads a P2SH-wrapped-segwit input\'s witness and does not '
        'desync a later plain-segwit input\'s witness', () {
      // Input 0: P2SH-wrapped segwit style - non-empty scriptSig (the
      // "redeem script push") *and* a real witness stack (sig + pubkey).
      final wrappedInput = TxInput(
        txId: _hexOf(32, 'a'),
        txIndex: 0,
        scriptSig: Script(script: [_hexOf(20, 'e')]),
      );
      final wrappedWitness = TxWitnessInput(stack: [
        _hexOf(71, '1'),
        _hexOf(33, '2'),
      ]);

      // Input 1: plain segwit - empty scriptSig, its own distinct witness.
      // If input 0's witness were skipped, this witness would be read at
      // the wrong cursor position (reading input 0's actual witness bytes
      // instead, or running past the buffer).
      final plainInput = TxInput(txId: _hexOf(32, 'b'), txIndex: 1);
      final plainWitness = TxWitnessInput(stack: [
        _hexOf(72, '3'),
        _hexOf(33, '4'),
      ]);

      final output = TxOutput(
        amount: BigInt.from(50000),
        scriptPubKey: Script(script: [
          'OP_DUP',
          'OP_HASH160',
          _hexOf(20, 'f'),
          'OP_EQUALVERIFY',
          'OP_CHECKSIG',
        ]),
      );

      final original = BtcTransaction(
        inputs: [wrappedInput, plainInput],
        outputs: [output],
        witnesses: [wrappedWitness, plainWitness],
        hasSegwit: true,
      );

      final hex = _toHex(original.toBytes(segwit: true));
      final parsed = BtcTransaction.fromRaw(hex);

      expect(parsed.inputs.length, 2);
      expect(parsed.witnesses.length, 2,
          reason: 'every input must get its own witness entry, including '
              'the one with a non-empty scriptSig');

      expect(parsed.inputs[0].scriptSig.script, wrappedInput.scriptSig.script);
      expect(parsed.witnesses[0].stack, wrappedWitness.stack);

      expect(parsed.inputs[1].scriptSig.script, isEmpty);
      expect(parsed.witnesses[1].stack, plainWitness.stack);
    });

    test(
        'reads an empty witness stack for a legacy input mixed into a '
        'segwit transaction (the 0x00 "no witness items" placeholder)', () {
      final legacyInput = TxInput(
        txId: _hexOf(32, 'c'),
        txIndex: 0,
        scriptSig: Script(script: [_hexOf(71, '5'), _hexOf(33, '6')]),
      );

      final segwitInput = TxInput(txId: _hexOf(32, 'd'), txIndex: 0);
      final segwitWitness = TxWitnessInput(stack: [
        _hexOf(71, '7'),
        _hexOf(33, '8'),
      ]);

      final output = TxOutput(
        amount: BigInt.from(1000),
        scriptPubKey: Script(script: ['OP_TRUE']),
      );

      final original = BtcTransaction(
        inputs: [legacyInput, segwitInput],
        outputs: [output],
        // The legacy input still gets an entry - an empty stack.
        witnesses: [TxWitnessInput(stack: const []), segwitWitness],
        hasSegwit: true,
      );

      final hex = _toHex(original.toBytes(segwit: true));
      final parsed = BtcTransaction.fromRaw(hex);

      expect(parsed.witnesses.length, 2);
      expect(parsed.witnesses[0].stack, isEmpty);
      expect(parsed.witnesses[1].stack, segwitWitness.stack);
    });
  });
}
