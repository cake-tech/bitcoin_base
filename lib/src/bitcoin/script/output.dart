import 'dart:typed_data';
import 'package:bitcoin_base/src/cash_token/cash_token.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';

/// Represents a transaction output.
///
/// [amount] the value we want to send to this output in satoshis
/// [scriptPubKey] the script that will lock this amount
class TxOutput {
  factory TxOutput.negativeOne() {
    return TxOutput._(
      amount: BitcoinOpCodeConst.negativeSatoshi,
      scriptPubKey: Script(script: []),
    );
  }
  // BitcoinOpCodeConst.negativeSatoshi
  const TxOutput._({
    required this.amount,
    required this.scriptPubKey,
    this.cashToken,
    this.isSilentPayment = false,
    this.isChange = false,
  });
  factory TxOutput({
    required BigInt amount,
    required Script scriptPubKey,
    CashToken? cashToken,
    bool isSilentPayment = false,
    bool isChange = false,
  }) {
    try {
      return TxOutput._(
        amount: amount.asUint64,
        scriptPubKey: scriptPubKey,
        cashToken: cashToken,
        isSilentPayment: isSilentPayment,
        isChange: isChange,
      );
    } catch (_) {
      throw DartBitcoinPluginException(
          "Invalid output amount: must be a non-negative 64-bit integer.");
    }
  }
  final CashToken? cashToken;
  final BigInt amount;
  final Script scriptPubKey;
  final bool isSilentPayment;
  final bool isChange;

  Map<String, dynamic> toJson() {
    return {
      'cashToken': cashToken?.toJson(),
      'amount': amount.toString(),
      'scriptPubKey': scriptPubKey.script
    };
  }

  ///  creates a copy of the object
  TxOutput clone() {
    return copy();
  }

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
    final amountBytes = BigintUtils.toBytes(
      amount,
      length: 8,
      order: Endian.little,
    );
    final scriptBytes = <int>[
      ...cashToken?.toBytes() ?? <int>[],
      ...scriptPubKey.toBytes(),
    ];
    final data = [
      ...amountBytes,
      ...IntUtils.encodeVarint(scriptBytes.length),
      ...scriptBytes,
    ];
    return data;
  }

  static Tuple<TxOutput, int> deserialize({
    required int cursor,
    List<int>? bytes,
    String? raw,
    bool hasSegwit = false,
  }) {
    return fromRaw(bytes: bytes, cursor: cursor, hasSegwit: hasSegwit);
  }

  static Tuple<TxOutput, int> fromRaw({
    required int cursor,
    List<int>? bytes,
    String? raw,
    bool hasSegwit = false,
  }) {
    bytes ??= BytesUtils.fromHexString(raw!);
    final value = BigintUtils.fromBytes(
      bytes.sublist(cursor, cursor + 8),
      byteOrder: Endian.little,
    ).toSigned(64);
    cursor += 8;

    final vi = IntUtils.decodeVarint(bytes.sublist(cursor));
    cursor += vi.item2;
    final token = CashToken.deserialize(bytes.sublist(cursor));

    final lockScript = bytes.sublist(cursor + token.item2, cursor + vi.item1);
    cursor += vi.item1;
    return Tuple(
        TxOutput(
            amount: value,
            cashToken: token.item1,
            scriptPubKey: Script.deserialize(bytes: lockScript)),
        cursor);
  }

  @override
  String toString() {
    return 'TxOutput{cashToken: ${cashToken?.toString()}, amount: $amount, script: ${scriptPubKey.toString()}}';
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! TxOutput) return false;
    return amount == other.amount &&
        scriptPubKey == other.scriptPubKey &&
        cashToken == other.cashToken;
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([amount, scriptPubKey, cashToken]);
}
