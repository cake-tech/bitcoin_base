import 'dart:typed_data';
import 'package:bitcoin_base/src/cash_token/cash_token.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Represents a transaction output.
///
/// [amount] the value we want to send to this output in satoshis
/// [scriptPubKey] the script that will lock this amount
class TxOutput {
  const TxOutput({
    required this.amount,
    required this.scriptPubKey,
    this.cashToken,
    this.isSilentPayment = false,
    this.isChange = false,
  });
  final CashToken? cashToken;
  final BigInt amount;
  final Script scriptPubKey;
  final bool isSilentPayment;
  final bool isChange;

  ///  creates a copy of the object
  TxOutput copy() {
    return TxOutput(
      amount: amount,
      scriptPubKey: Script(script: List.from(scriptPubKey.script)),
      cashToken: cashToken,
      isSilentPayment: isSilentPayment,
      isChange: isChange,
    );
  }

  List<int> toBytes() {
    final amountBytes =
        BigintUtils.toBytes(amount, length: 8, order: Endian.little);
    List<int> scriptBytes = [
      ...cashToken?.toBytes() ?? <int>[],
      ...scriptPubKey.toBytes()
    ];
    final data = [
      ...amountBytes,
      ...IntUtils.encodeVarint(scriptBytes.length),
      ...scriptBytes
    ];
    return data;
  }

  static Tuple<TxOutput, int> fromRaw({
    required String raw,
    required int cursor,
    bool hasSegwit = false,
  }) =>
      fromBytes(
        bytes: BytesUtils.fromHexString(raw),
        cursor: cursor,
        hasSegwit: hasSegwit,
      );

  /// Like [fromRaw] on already-decoded bytes, so a caller reading many outputs
  /// decodes the transaction once instead of once per output.
  static Tuple<TxOutput, int> fromBytes({
    required List<int> bytes,
    required int cursor,
    bool hasSegwit = false,
  }) {
    final txBytes = bytes;
    final value = BigintUtils.fromBytes(txBytes.sublist(cursor, cursor + 8),
            byteOrder: Endian.little)
        .toSigned(64);
    cursor += 8;

    final vi = IntUtils.decodeVarint(txBytes.skip(cursor).take(9).toList());
    cursor += vi.item2;
    // Only the script's own bytes can hold a token, so don't copy the rest of the tx.
    final token = CashToken.fromRaw(txBytes.sublist(cursor, cursor + vi.item1));
    List<int> lockScript =
        txBytes.sublist(cursor + token.item2, cursor + vi.item1);
    cursor += vi.item1;
    return Tuple(
        TxOutput(
            amount: value,
            cashToken: token.item1,
            scriptPubKey: Script.fromRaw(
              hexData: BytesUtils.toHexString(lockScript),
              hasSegwit: hasSegwit,
            )),
        cursor);
  }

  @override
  String toString() {
    return "TxOutput{cashToken: ${cashToken?.toString()}}, amount: $amount, script: ${scriptPubKey.toString()}}";
  }
}
