import 'dart:typed_data';

import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'script.dart';

/// A transaction input requires a transaction id of a UTXO and the index of that UTXO.
///
/// [txId] the transaction id as a hex string
/// [txIndex] the index of the UTXO that we want to spend
/// [scriptSig] the script that satisfies the locking conditions
/// [sequence] the input sequence (for timelocks, RBF, etc.)
class TxInput {
  TxInput({
    required this.txId,
    required this.txIndex,
    Script? scriptSig,
    List<int>? sequence,
  })  : sequence = List.unmodifiable(
          sequence ?? BitcoinOpCodeConst.DEFAULT_TX_SEQUENCE,
        ),
        scriptSig = scriptSig ?? Script(script: []);
  TxInput copyWith({
    String? txId,
    int? txIndex,
    Script? scriptSig,
    List<int>? sequence,
  }) {
    return TxInput(
        txId: txId ?? this.txId,
        txIndex: txIndex ?? this.txIndex,
        scriptSig: scriptSig ?? this.scriptSig,
        sequence: sequence ?? this.sequence);
  }

  final String txId;
  final int txIndex;
  Script scriptSig;
  List<int> sequence;

  /// creates a copy of the object
  TxInput copy() {
    return TxInput(txId: txId, txIndex: txIndex, scriptSig: scriptSig, sequence: sequence);
  }

  /// serializes TxInput to bytes
  List<int> toBytes() {
    final txidBytes = BytesUtils.fromHexString(txId).reversed.toList();

    final txoutBytes = IntUtils.toBytes(txIndex, length: 4, byteOrder: Endian.little);
    // writeUint32LE(txIndex, txoutBytes);
    final scriptSigBytes = scriptSig.toBytes();
    final scriptSigLengthVarint = IntUtils.encodeVarint(scriptSigBytes.length);
    final data = List<int>.from(
        [...txidBytes, ...txoutBytes, ...scriptSigLengthVarint, ...scriptSigBytes, ...sequence]);
    return data;
  }

  static Tuple<TxInput, int> deserialize({
    required List<int> bytes,
    String? raw,
    int cursor = 0,
    bool hasSegwit = false,
  }) {
    return fromRaw(bytes: bytes, cursor: cursor, hasSegwit: hasSegwit);
  }

  static Tuple<TxInput, int> fromRaw({
    List<int>? bytes,
    String? raw,
    int cursor = 0,
    bool hasSegwit = false,
  }) {
    final txInputRaw = bytes ?? BytesUtils.fromHexString(raw!);
    final inpHash = txInputRaw.sublist(cursor, cursor + 32).reversed.toList();
    cursor += 32;
    final outputN =
        IntUtils.fromBytes(txInputRaw.sublist(cursor, cursor + 4), byteOrder: Endian.little);
    cursor += 4;
    final vi = IntUtils.decodeVarint(txInputRaw.sublist(cursor));
    cursor += vi.item2;
    final unlockingScript = txInputRaw.sublist(cursor, cursor + vi.item1);
    cursor += vi.item1;
    final sequenceNumberData = txInputRaw.sublist(cursor, cursor + 4);
    cursor += 4;
    return Tuple(
        TxInput(
          txId: BytesUtils.toHexString(inpHash),
          txIndex: outputN,
          scriptSig: Script.deserialize(
            bytes: unlockingScript,
            hasSegwit: hasSegwit,
          ),
          sequence: sequenceNumberData,
        ),
        cursor);
  }

  Map<String, dynamic> toJson() {
    return {
      'txid': txId,
      'txIndex': txIndex,
      'scriptSig': scriptSig.script,
      'sequance': BytesUtils.toHexString(sequence),
    };
  }

  @override
  String toString() {
    return 'TxInput{txId: $txId, txIndex: $txIndex, scriptSig: $scriptSig, sequence: ${BytesUtils.toHexString(sequence)}}';
  }
}
