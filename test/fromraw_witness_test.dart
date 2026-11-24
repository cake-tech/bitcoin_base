import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

import 'raw_hex_builder.dart';

/// BtcTransaction.fromRaw must read exactly one witness stack per input once the
/// segwit flag is set (BIP144), including for P2SH-wrapped inputs, and must read
/// every varint length without running past the end of the transaction.
void main() {
  final sig = '11' * 71;
  final pubHex = '02${'ab' * 32}';
  final outScript = '0014${'33' * 20}';

  // P2SH-P2WPKH: scriptSig is one push of the 22-byte redeem script.
  final nestedScriptSig = '16' '0014${'22' * 20}';
  // Legacy P2PKH: scriptSig is <sig> <pubkey>.
  final legacyScriptSig = '47${'11' * 71}21$pubHex';

  List<RawOutput> outputs() => [RawOutput(amount: 50000, scriptPubKey: outScript)];

  group('fromRaw reads one witness per input', () {
    test('a legacy-only transaction has no witnesses', () {
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [RawInput(txid: 'aa' * 32, scriptSig: legacyScriptSig)],
          outputs: outputs(),
        ),
      );

      expect(tx.hasSegwit, isFalse);
      expect(tx.witnesses, isEmpty);
    });

    test('a native P2WPKH input keeps its witness stack', () {
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [RawInput(txid: 'aa' * 32)],
          outputs: outputs(),
          witnesses: [
            [sig, pubHex],
          ],
        ),
      );

      expect(tx.hasSegwit, isTrue);
      expect(tx.witnesses.single.stack, [sig, pubHex]);
    });

    test('a nested-segwit (P2SH-P2WPKH) input keeps its witness stack', () {
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [RawInput(txid: 'aa' * 32, scriptSig: nestedScriptSig)],
          outputs: outputs(),
          witnesses: [
            [sig, pubHex],
          ],
        ),
      );

      expect(tx.witnesses, hasLength(1));
      expect(tx.witnesses.single.stack, [sig, pubHex]);
    });

    test('a nested input followed by a plain input does not desync the later witness', () {
      final plainWitness = ['22' * 70, pubHex];
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [
            RawInput(txid: 'aa' * 32, scriptSig: nestedScriptSig),
            RawInput(txid: 'bb' * 32, index: 1),
          ],
          outputs: outputs(),
          witnesses: [
            [sig, pubHex],
            plainWitness,
          ],
        ),
      );

      expect(tx.witnesses.first.stack, [sig, pubHex]);
      expect(tx.witnesses.last.stack, plainWitness);
    });
  });

  group('fromRaw reads varint lengths at the end of a transaction', () {
    test('a segwit transaction whose last input is legacy still parses', () {
      // After the last input's empty witness (0x00) only the 4-byte locktime is
      // left. A read that asks for 9 bytes at that point runs past the end.
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [
            RawInput(txid: 'aa' * 32, scriptSig: nestedScriptSig),
            RawInput(txid: 'bb' * 32, index: 1, scriptSig: legacyScriptSig),
          ],
          outputs: outputs(),
          witnesses: [
            [sig, pubHex],
            [],
          ],
        ),
      );

      expect(tx.inputs, hasLength(2));
      expect(tx.witnesses, hasLength(2));
      expect(tx.witnesses.last.stack, isEmpty);
    });

    test('a witness item of 252 bytes uses a one-byte length prefix and parses', () {
      final item = 'cd' * 252;
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [RawInput(txid: 'aa' * 32)],
          outputs: outputs(),
          witnesses: [
            [item],
          ],
        ),
      );

      expect(tx.witnesses.single.stack, [item]);
    });

    test('a witness item of 253 bytes uses the 0xfd length prefix and parses', () {
      final item = 'cd' * 253;
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [RawInput(txid: 'aa' * 32)],
          outputs: outputs(),
          witnesses: [
            [item],
          ],
        ),
      );

      expect(tx.witnesses.single.stack, [item]);
    });

    test('a large witness followed by a legacy input keeps both intact', () {
      final bigItem = 'ef' * 600;
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [
            RawInput(txid: 'aa' * 32, scriptSig: nestedScriptSig),
            RawInput(txid: 'bb' * 32, index: 1, scriptSig: legacyScriptSig),
          ],
          outputs: outputs(),
          witnesses: [
            [bigItem, pubHex],
            [],
          ],
        ),
      );

      expect(tx.witnesses.first.stack, [bigItem, pubHex]);
      expect(tx.witnesses.last.stack, isEmpty);
    });
  });
}
