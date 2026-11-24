import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

import 'raw_hex_builder.dart';

/// Litecoin MWEB transactions carry an extension after the outputs and witnesses,
/// flagged by 0x08 in the flag byte. The extension must be kept as mwebBytes and
/// must not change how the inputs, outputs or witnesses are read.
void main() {
  final sig = '11' * 71;
  final pubHex = '02${'ab' * 32}';
  final outScript = '0014${'33' * 20}';
  const mweb = 'abcdef0123456789';

  String hexOfBytes(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  group('fromRaw with an MWEB extension', () {
    test('a segwit + MWEB transaction keeps the extension and its witnesses', () {
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [RawInput(txid: 'aa' * 32)],
          outputs: [RawOutput(amount: 50000, scriptPubKey: outScript)],
          witnesses: [
            [sig, pubHex],
          ],
          mweb: mweb,
        ),
      );

      expect(tx.hasSegwit, isTrue);
      expect(tx.mwebBytes, isNotNull);
      expect(hexOfBytes(tx.mwebBytes!), mweb);
      expect(tx.witnesses.single.stack, [sig, pubHex]);
      expect(tx.inputs, hasLength(1));
      expect(tx.outputs, hasLength(1));
    });

    test('an MWEB transaction without segwit parses with no witnesses', () {
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [RawInput(txid: 'aa' * 32)],
          outputs: [RawOutput(amount: 50000, scriptPubKey: outScript)],
          mweb: mweb,
        ),
      );

      expect(tx.hasSegwit, isFalse);
      expect(hexOfBytes(tx.mwebBytes!), mweb);
      expect(tx.witnesses, isEmpty);
    });

    test('a plain transaction has no MWEB extension', () {
      final tx = BtcTransaction.fromRaw(
        rawTxHex(
          inputs: [RawInput(txid: 'aa' * 32)],
          outputs: [RawOutput(amount: 50000, scriptPubKey: outScript)],
          witnesses: [
            [sig, pubHex],
          ],
        ),
      );

      expect(tx.mwebBytes, isNull);
    });
  });

  group('MWEB serialization round trip', () {
    test('toHex then fromRaw returns the same extension and witnesses', () {
      final original = BtcTransaction(
        inputs: [TxInput(txId: 'aa' * 32, txIndex: 0)],
        outputs: [
          TxOutput(
            amount: BigInt.from(50000),
            scriptPubKey: Script(script: ['0014${'33' * 20}']),
          ),
        ],
        witnesses: [
          TxWitnessInput(stack: [sig, pubHex]),
        ],
        hasSegwit: true,
        mwebBytes: BytesUtils.fromHexString(mweb),
      );

      final parsed = BtcTransaction.fromRaw(original.toHex());

      expect(parsed.hasSegwit, isTrue);
      expect(hexOfBytes(parsed.mwebBytes!), mweb);
      expect(parsed.witnesses.single.stack, [sig, pubHex]);
      expect(parsed.toHex(), original.toHex());
    });
  });
}
