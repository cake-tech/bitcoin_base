import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:test/test.dart";

void main() {
  final scriptPubKey = ECPrivate.random().getPublic().toP2wpkhAddress().toScriptPubKey();

  BtcTransaction bigTransaction(int count) => BtcTransaction(
        inputs: [
          for (var i = 0; i < count; i++) TxInput(txId: "ab" * 32, txIndex: i),
        ],
        outputs: [
          for (var i = 0; i < count; i++)
            TxOutput(amount: BigInt.from(1000 + i), scriptPubKey: scriptPubKey),
        ],
        witnesses: [
          for (var i = 0; i < count; i++) TxWitnessInput(stack: ["11" * 64, "22" * 33]),
        ],
        hasSegwit: true,
      );

  test("a transaction with thousands of inputs and outputs parses back unchanged", () {
    final hex = bigTransaction(3000).toHex();

    final parsed = BtcTransaction.fromRaw(hex);

    expect(parsed.inputs, hasLength(3000));
    expect(parsed.outputs, hasLength(3000));
    expect(parsed.witnesses, hasLength(3000));
    expect(parsed.toHex(), hex);
  });

  test("TxInput.fromRaw and fromBytes read the same input", () {
    final hex = bigTransaction(2).toHex();
    final bytes = BytesUtils.fromHexString(hex);

    // Version (4) + marker/flag (2) + input count (1) puts the first input at 7.
    final fromHex = TxInput.fromRaw(raw: hex, cursor: 7, hasSegwit: true);
    final fromBytes = TxInput.fromBytes(bytes: bytes, cursor: 7, hasSegwit: true);

    expect(fromBytes.item1.txId, fromHex.item1.txId);
    expect(fromBytes.item1.txIndex, fromHex.item1.txIndex);
    expect(fromBytes.item2, fromHex.item2);
  });
}
