import 'dart:io';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

String _readFixtureHex(String name) =>
    File('test/fixtures/$name').readAsStringSync().trim();

String _toHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('BtcTransaction.fromRaw - large transactions', () {
    // These are two real, on-chain consolidation-style transactions with
    // well over 252 inputs/outputs each - the threshold at which Bitcoin's
    // CompactSize varint encoding switches from a 1-byte count to a 3-byte
    // (0xfd + 2 bytes LE) prefix. A wallet fetching either of these must be
    // able to parse them like any other transaction.
    test('parses a real transaction with 260 inputs / 340 outputs', () {
      final hex = _readFixtureHex('large_tx_260in_340out.hex');
      final tx = BtcTransaction.fromRaw(hex);

      expect(tx.inputs.length, 260);
      expect(tx.outputs.length, 340);
      expect(tx.hasSegwit, isTrue);
    });

    test('parses a real transaction with 365 inputs / 454 outputs', () {
      final hex = _readFixtureHex('large_tx_365in_454out.hex');
      final tx = BtcTransaction.fromRaw(hex);

      expect(tx.inputs.length, 365);
      expect(tx.outputs.length, 454);
      expect(tx.hasSegwit, isTrue);
    });

    test('a re-serialized large transaction round-trips to the same txid', () {
      final hex = _readFixtureHex('large_tx_260in_340out.hex');
      final tx = BtcTransaction.fromRaw(hex);
      final reencoded =
          BtcTransaction.fromRaw(_toHex(tx.toBytes(segwit: true)));

      expect(reencoded.inputs.length, tx.inputs.length);
      expect(reencoded.outputs.length, tx.outputs.length);
      expect(reencoded.hasSegwit, tx.hasSegwit);

      expect(reencoded.txId(), tx.txId());
    });

    group('truncated/malformed input', () {
      test(
          'the exception message identifies it as a parsing failure and '
          'carries the input length for diagnostics', () {
        final truncatedHex =
            _readFixtureHex('large_tx_260in_340out.hex').substring(0, 100);

        try {
          BtcTransaction.fromRaw(truncatedHex);
          fail('expected BtcTransaction.fromRaw to throw');
        } on BitcoinBasePluginException catch (e) {
          expect(e.message.toLowerCase(), contains('malformed'));
          expect(e.details?['hexLength'], truncatedHex.length);
        }
      });

      test(
          'truncating only the trailing locktime bytes now throws instead '
          'of silently absorbing a wrong locktime', () {
        // For non-mweb transactions, `cursor` after inputs/outputs/witnesses
        // is validated against the expected `rawtx.length - 4` locktime
        // offset, so cutting off the last 4 bytes (or any amount) is caught
        // here instead of being silently reinterpreted as a different,
        // wrong-but-still-4-byte locktime.
        final fullHex = _readFixtureHex('large_tx_365in_454out.hex');
        final truncatedHex = fullHex.substring(0, fullHex.length - 4);

        expect(
          () => BtcTransaction.fromRaw(truncatedHex),
          throwsA(isA<BitcoinBasePluginException>()),
        );
      });

      test('throws a typed exception for a hex only a few bytes long', () {
        expect(
          () => BtcTransaction.fromRaw('01000000'),
          throwsA(isA<BitcoinBasePluginException>()),
        );
      });

      test('throws a typed exception for an empty string', () {
        expect(
          () => BtcTransaction.fromRaw(''),
          throwsA(isA<BitcoinBasePluginException>()),
        );
      });
    });
  });
}
