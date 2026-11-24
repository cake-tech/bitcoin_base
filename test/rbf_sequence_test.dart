import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

import 'raw_hex_builder.dart';

/// BIP125: an input opts into replace-by-fee when its sequence is below
/// 0xfffffffe. Matching only the one value the old code compared against missed
/// 0xfffffffd, which PSBT-built sends use.
List<int> _le32(int value) => [
      value & 0xff,
      (value >> 8) & 0xff,
      (value >> 16) & 0xff,
      (value >> 24) & 0xff,
    ];

void main() {
  final sig = '11' * 71;
  final pubHex = '02${'ab' * 32}';
  final outScript = '0014${'33' * 20}';

  group('BtcTransaction.sequenceSignalsRbf', () {
    test('0xfffffffd signals RBF', () {
      expect(BtcTransaction.sequenceSignalsRbf(_le32(0xfffffffd)), isTrue);
    });

    test('0xfffffffe does not signal RBF (BIP125 boundary)', () {
      expect(BtcTransaction.sequenceSignalsRbf(_le32(0xfffffffe)), isFalse);
    });

    test('0xffffffff does not signal RBF', () {
      expect(BtcTransaction.sequenceSignalsRbf(_le32(0xffffffff)), isFalse);
    });

    test('0x00000000 and 0x00000001 signal RBF', () {
      expect(BtcTransaction.sequenceSignalsRbf(_le32(0)), isTrue);
      expect(BtcTransaction.sequenceSignalsRbf(_le32(1)), isTrue);
    });

    test('a sequence that is not 4 bytes does not signal RBF', () {
      expect(BtcTransaction.sequenceSignalsRbf([0xfd, 0xff, 0xff]), isFalse);
    });
  });

  group('fromRaw sets canReplaceByFee from the input sequences', () {
    BtcTransaction parse(List<int> sequences) => BtcTransaction.fromRaw(
          rawTxHex(
            inputs: [
              for (var i = 0; i < sequences.length; i++)
                RawInput(txid: 'aa' * 32, index: i, sequence: sequences[i]),
            ],
            outputs: [RawOutput(amount: 50000, scriptPubKey: outScript)],
            witnesses: [
              for (var i = 0; i < sequences.length; i++) [sig, pubHex],
            ],
          ),
        );

    test('a PSBT-style 0xfffffffd input makes the transaction replaceable', () {
      expect(parse([0xfffffffd]).canReplaceByFee, isTrue);
    });

    test('a final 0xffffffff input does not make the transaction replaceable', () {
      expect(parse([0xffffffff]).canReplaceByFee, isFalse);
    });

    test('one signalling input among final ones makes the transaction replaceable', () {
      expect(parse([0xffffffff, 0xfffffffd]).canReplaceByFee, isTrue);
    });
  });
}
