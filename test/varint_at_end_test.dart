import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

/// A varint is read through a 9-byte window. These transactions put a varint
/// within 9 bytes of the end of the buffer it is read from, which used to throw
/// a RangeError instead of parsing.
void main() {
  test("parses a CPFP child whose last input spends a P2A anchor", () {
    final hex = [
      "03000000", // version 3
      "0001", // segwit marker and flag
      "02", // 2 inputs
      "22" * 32, "00000000", "00", "ffffffff", // funding coin
      "11" * 32, "00000000", "00", "ffffffff", // P2A anchor
      "01", // 1 output
      "1027000000000000", "16", "0014${"33" * 20}", // P2WPKH change
      "02", "47", "44" * 71, "21", "02${"55" * 32}", // funding witness: sig + pubkey
      "00", // anchor witness: empty, right before the locktime
      "00000000", // locktime
    ].join();

    final tx = BtcTransaction.fromRaw(hex);

    expect(tx.inputs, hasLength(2));
    expect(tx.witnesses.last.stack, isEmpty);
    expect(tx.serialize(), hex);
  });

  test("parses a transaction with a P2A anchor output", () {
    final hex = [
      "03000000", "0001", "01", // version 3, segwit, 1 input
      "11" * 32, "00000000", "00", "ffffffff",
      "01", "0000000000000000", "04", "51024e73", // P2A anchor: OP_1 <0x4e73>
      "00", "00000000", // empty witness, locktime
    ].join();

    final tx = BtcTransaction.fromRaw(hex);

    expect(tx.outputs.single.scriptPubKey.toHex(), "51024e73");
    expect(tx.serialize(), hex);
  });
}
